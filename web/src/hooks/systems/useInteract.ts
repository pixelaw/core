import { useDojo } from '@/DojoContext'
import { useMutation } from '@tanstack/react-query'
import { convertToDecimal, felt252ToString } from '@/global/utils'
import { EntityIndex, getComponentValue } from '@latticexyz/recs'
import { getEntityIdFromKeys } from '@dojoengine/utils'
import { num, selector, shortString } from 'starknet'
import interpret, { isInstruction, ParamDefinitionType } from '@/lib/Instruction'
import useManifest from '@/hooks/systems/useManifest'
import { InterfaceType, Manifest } from '@/global/types'
import { sleep } from '@latticexyz/utils'
import { useToast } from '@/components/ui/use-toast'
import { useComponentValue } from '@dojoengine/react'

const DEFAULT_PARAMETERS_TYPE = 'pixelaw::core::utils::DefaultParameters'

const convertSnakeToPascal = (snakeCaseString: string) => {
  return snakeCaseString.split('_').map(function(word) {
    return word.charAt(0).toUpperCase() + word.slice(1);
  }).join('')
}

const getParamsDef: (manifest: Manifest, contractName: string, methodName: string, position: {x: number, y: number}, strict?: boolean) => ParamDefinitionType[] =
  (manifest, contractName, methodName, position, strict = false) => {
    if (!manifest) {
      if (strict) throw new Error('manifest not found')
      else return []
    }
    const contract = manifest.contracts.find(contract => contract.name === contractName)
    if (!contract) {
      if (strict) throw new Error(`unknown contract: ${contractName}`)
      else return []
    }
    const interfaceName = `I${convertSnakeToPascal(contractName)}`
    const methods = contract.abi.find(x => x.type === 'interface' && x.name.includes(interfaceName)) as InterfaceType | undefined
    if (!methods) {
      if (strict) throw new Error(`unknown interface: ${interfaceName}`)
      else return []
    }
    if (!methods?.items) {
      if (strict) throw new Error(`no methods for interface: ${interfaceName}`)
      else return []
    }

    let functionDef = methods.items.find(method => method.name === methodName && method.type === 'function')
    if (!functionDef) {
      functionDef = methods.items.find(method => method.name === 'interact' && method.type === 'function')
      if (!functionDef) {
        if (strict) throw new Error(`function ${methodName} not found`)
        else return []
      }
    }
    const parameters = functionDef.inputs.filter(input => input.type !== DEFAULT_PARAMETERS_TYPE)

    return parameters.map(param => {
      if (isInstruction(param.name)) {
        // problem with types on contract.abi
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        return interpret(contractName, position, param.name, contract.abi)
      }
      const isPrimitiveType = param.type.includes("core::integer") || param.type.includes("core::felt252")
      let type: 'number' | 'string' | 'enum' = 'number'
      let variants: {name: string, value: number}[] = []
      if (!isPrimitiveType) {
        const typeDefinition = contract.abi.find(x => x.name === param.type)
        if (typeDefinition?.type === "enum") {
          variants = (typeDefinition?.variants ?? [])
            .map((variant, index) => {
              return {
                name: variant.name,
                value: index
              }
            })
            .filter(variant => variant.name !== 'None')
          type = 'enum'
        }
      } else if (param.type.includes("core::felt252")) {
        type = 'string'
      }
      return {
        name: param.name,
        type,

        // if is not primitive type fill these out
        variants,

        // for interpret instruction only
        transformValue: undefined,
        value: undefined,

      }
    })
  }

/// @dev this does not handle struct params yet...will support this on a later iteration
const useInteract = (
  appName: string,
  color: string,
  position: {x: number, y: number}
) => {

  const {
    setup: {
      systemCalls: {interact},
      components: { Pixel, AppName, Instruction },
      network: { switchManifest }
    },
    account: { account }
  } = useDojo()

  const { toast } = useToast()

  const manifest = useManifest({ name: appName })

  const contractName = `${appName}_actions`

  const solidColor = color.replace('#', '0xFF')
  const decimalColor = convertToDecimal(solidColor)

  const entityId = getEntityIdFromKeys([BigInt(position.x), BigInt(position.y)]) as EntityIndex
  const pixelValue = getComponentValue(Pixel, entityId)

  const action = (!pixelValue?.action || pixelValue?.action.toString() === '0x0') ? 'interact' : pixelValue.action
  const methodName = felt252ToString(action)

  const paramsDef = getParamsDef(manifest?.data, contractName, methodName, position)

  const fillableParamDefs = paramsDef.filter(paramDef => paramDef?.value == null)

  const contractAddress = useComponentValue(AppName, getEntityIdFromKeys([BigInt(shortString.encodeShortString(appName))]))

  const instruction = useComponentValue(Instruction, getEntityIdFromKeys([
    BigInt(contractAddress?.system ?? '0x0'),
    BigInt(selector.getSelectorFromName(methodName))
  ]))

  return {
    manifest,
    interact: useMutation({
      mutationKey: ['useInteract', contractName, color],
      mutationFn: async ({otherParams}: {
        // eslint-disable-next-line
        otherParams?: Record<string, any>
      }) => {
        if (!manifest.data) throw new Error('manifest has not loaded yet')
        switchManifest(manifest.data)
        if (!otherParams && fillableParamDefs.length > 0) throw new Error('incomplete parameters')
        const additionalParams: num.BigNumberish[] = []

        for (const paramDef of paramsDef) {
          if (paramDef.value) {
            additionalParams.push(paramDef.value)
          } else {
            if(!otherParams) continue
            let param = otherParams[paramDef.name]
            if (!param && paramDef.variants.length) {
              param = paramDef.variants[0].value
            }
            if (
              (paramDef.type === 'string' && typeof param !== 'string') ||
              (paramDef.type === 'number' && typeof param !== 'number')
            ) throw new Error(`incorrect parameter for ${paramDef.name}. supplied is ${param}`)

            // TODO handle structs
            if (paramDef.transformValue) {
              additionalParams.push(paramDef.transformValue(param))
            }
            else additionalParams.push(param)
          }
        }

        // TODO: add sleep for now so that nonce issue is mitigated
        await sleep(1_000)
        const interaction = `${appName}.${methodName}`
        try {
          await interact(account, contractName, position, decimalColor, methodName, additionalParams)
          const paramsList = additionalParams.length ? ` with params: [${additionalParams.join(", ")}]` : ''
          toast({
            title: 'Successful Transaction',
            description: `${interaction}${paramsList} was successful`
          })
        } catch (e) {
          toast({
            variant: "destructive",
            title: 'Failed Transaction',
            description: e?.toString() ?? `${interaction} could not be completed`
          })
          throw e
        }

      }
    }),
    params: fillableParamDefs,
    instruction: felt252ToString(instruction?.instruction ?? '')
  }
}

export default useInteract
