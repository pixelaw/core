import useSubscribe from '@/hooks/utils/useSubscribe'
import { parseEventData } from '@/hooks/events/utils'
import { toast } from '@/components/ui/use-toast'
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import { getComponentValue } from '@latticexyz/recs'
import { useDojo } from '@/dojo/useDojo'
import { getEntityIdFromKeys } from '@dojoengine/utils'
import { felt252ToString } from '@/global/utils'
import { useQueryClient } from '@tanstack/react-query'

const QUERY = `
  subscription alerts {
    eventEmitted(keys: ["0x4f01980329bc5de8cd181e4fb67fefefe583bd41f04365fa472ba112e7e5ef"]) {
      id
      keys
      data
      createdAt
      transactionHash
    }
  }
`

type EventDataMessage = {
  data: {
    eventEmitted: {
      id: string,
      keys: string[],
      data: string[],
      createdAt: string,
      transactionHash: string
    }
  }
}


/**
 * @notice toasts an incoming alert for the user
 * */
const useAnnounceAlert = () => {
  const queryClient = useQueryClient();
  const {
    setup: {
      clientComponents: { App },
    },
    account: {
      account
    }
  } = useDojo()

  const onAlert = ({data: { eventEmitted: { id, data }}}: EventDataMessage) => {
    const alert = parseEventData(id, data)
    const app = getComponentValue(App, getEntityIdFromKeys([BigInt(alert.caller)]))
    const appName = felt252ToString(app?.name ?? alert.caller)
    if (account.address.toLowerCase() !== alert.player.toLowerCase()) return
    queryClient.invalidateQueries({ queryKey: ['alerts', account.address.toLowerCase()]}).then()
    toast({
      title: appName,
      description: alert.message
    })
  }

  useSubscribe<EventDataMessage>(QUERY, onAlert)
}

export default useAnnounceAlert
