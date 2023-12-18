import { useDojo } from '@/DojoContext'
import { useComponentValue } from '@dojoengine/react'
import { getEntityIdFromKeys } from '@dojoengine/utils'
import { shortString } from 'starknet'
import { useQuery } from '@tanstack/react-query'
import { felt252ToString, streamToString } from '@/global/utils'
import { Manifest } from '@/global/types'

type PropsType = {
  name: string
}

const useManifest = ({name}: PropsType) => {
  const {
    setup: {
      components: {
        App, AppName
      }
    },
  } = useDojo()

  const nameEntityId = getEntityIdFromKeys([BigInt(shortString.encodeShortString(name))])
  const appName = useComponentValue(AppName, nameEntityId)
  const appEntityId = getEntityIdFromKeys([BigInt(appName?.system ?? 0)])
  const app = useComponentValue(App, appEntityId)
  const manifest = felt252ToString(app?.manifest ?? '')

  return useQuery<Manifest>(
    {
      queryKey: ['manifest', manifest],
      queryFn: async () => {
        if (manifest.startsWith('BASE/')) {
          const result = await fetch(manifest.replace('BASE', ''))
          if (!result?.body) return {}
          const string = await streamToString(result.body)
          return JSON.parse(string)

        } else if (manifest.startsWith('ipfs://')) {
          // TODO: handle ipfs
          return {}
        } else {
          return await fetch(manifest)
        }
      },
      enabled: !!app?.manifest
    }
  )
}

export default useManifest
