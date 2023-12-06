import { useDojo } from '@/DojoContext'
import { BLOCK_TIME } from '@/global/constants'
import { useQuery } from '@tanstack/react-query'
import { convertToDecimal, felt252ToString } from '@/global/utils'

const ALERTS_TO_GET = 1_000

const useAlerts = () => {
  const {
    setup: {
      network: { graphSdk },
    },
    account: {
      account
    }
  } = useDojo()

  return useQuery({
    queryKey: ['alerts', account.address],
    queryFn: async () => {
      /// TODO: paginate getting alerts. Settling for this right now
      const {data} = await graphSdk.alerts({ first: ALERTS_TO_GET })
      return (data.events?.edges ?? [])
        .filter(edge => {
          if (!edge?.node?.data) return false
          const player = edge.node.data[3]
          return player?.toLowerCase() === account.address.toLowerCase()
        })
        .map((edge, index) => {
          const [
            x,
            y,
            caller,
            player,
            message,
            timestamp
          ] = (edge?.node?.data ?? [])
          return {
            id: edge?.node?.id ?? index.toString(),
            position: {
              x: convertToDecimal(x ?? '0x0'),
              y: convertToDecimal(y ?? '0x0')
            },
            caller: caller ?? '0x0',
            player: player ?? '0x0',
            message: felt252ToString(message ?? ''),
            timestamp: BigInt(timestamp ?? '0x0')
          }
        })
    },
    refetchInterval: BLOCK_TIME,
  })
}

export default useAlerts
