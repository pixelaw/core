echo "Localdeploy"

BASEDIR="/mounted/"

APP_NAME=$(grep '^name =' $BASEDIR/Scarb.toml | awk -F'"' '{print $2}')
PROFILE=dev
MANIFEST="$BASEDIR/manifests/$PROFILE/manifest.json"

cd $BASEDIR

sozo --profile $PROFILE build
sozo --profile $PROFILE migrate plan
sozo --profile $PROFILE migrate apply

export ACTIONS_ADDRESS=$(cat $MANIFEST | jq -r --arg APP_NAME "$APP_NAME" '.contracts[] | select(.name | contains($APP_NAME)) | .address')

echo "---------------------------------------------------------------------------"
echo app : $APP_NAME
echo " "
echo actions : $ACTIONS_ADDRESS
echo "---------------------------------------------------------------------------"

# enable system -> component authorizations
COMPONENTS=($(jq -r --arg APP_NAME "$APP_NAME" '.models[] | select(.name | contains($APP_NAME)) | .name' $MANIFEST))

for index in "${!COMPONENTS[@]}"; do
    IFS='::' read -ra NAMES <<< "${COMPONENTS[index]}"
    LAST_INDEX=${#NAMES[@]}-1
    NEW_NAME=`echo ${NAMES[LAST_INDEX]} | sed -r 's/_/ /g' | awk '{for(j=1;j<=NF;j++){ $j=toupper(substr($j,1,1)) substr($j,2) }}1' | sed -r 's/ //g'`
    COMPONENTS[index]=$NEW_NAME
done

# if #COMPONENTS is 0, then there are no models in the manifest. This might be error,
echo "Write permissions for ACTIONS"
if [ ${#COMPONENTS[@]} -eq 0 ]; then
    echo "Warning: No models found in manifest.json. Are you sure you don't have new any components?"
else
    for component in ${COMPONENTS[@]}; do
        echo "For $component"
        sozo --profile $PROFILE auth grant --wait writer $component,$ACTIONS_ADDRESS
    done
fi
echo "Write permissions for ACTIONS: Done"

echo "Initialize ACTIONS: (sozo --profile $PROFILE execute -v $ACTIONS_ADDRESS init)"
sozo --profile $PROFILE execute --wait -v $ACTIONS_ADDRESS init
echo "Initialize ACTIONS: Done"

echo "Default authorizations have been successfully set."

