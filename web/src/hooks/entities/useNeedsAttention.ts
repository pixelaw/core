import {useQuery} from '@tanstack/react-query'
import {useDojo} from '@/DojoContext.tsx'
import {getEntityIdFromKeys} from '@dojoengine/utils'
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import {getComponentValue, setComponent} from '@latticexyz/recs'
import isEqual from 'lodash/isEqual'
import {BLOCK_TIME} from '@/global/constants.ts'

export function useNeedsAttention() {
  const {
    account: {
      account,
    },
    setup: {
      components: {
        Pixel,
        Alert
      },
      network: { graphSdk },
    },
  } = useDojo()

  return useQuery({
    queryKey: [ 'needs-attention' ],
    queryFn: async () => {
      const { data } = await graphSdk.getNeedsAttention({ first: 65536, address: account.address })
      if (!data || !data.pixelModels?.edges) return { pixelModels: { edges: [] } }
      for (const edge of data.pixelModels.edges) {
        if (!edge || !edge.node) continue
        const fetchedNode = edge.node
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        delete fetchedNode['__typename']
        const entityId = getEntityIdFromKeys([ BigInt(fetchedNode.x), BigInt(fetchedNode.y) ])
        const currentColor = getComponentValue(Pixel, entityId)

        // do not update if it's already equal
        if (isEqual(currentColor, fetchedNode)) continue

        // to update latticexyz indexer
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        setComponent(Pixel, entityId, fetchedNode)
      }

      if (!data || !data.alertModels?.edges) return {needsattentionModels: {edges: []}}
      for (const edge of data.alertModels.edges) {
        if (!edge || !edge.node) continue
        const { x, y, alert } = edge.node
        const needsAttentionValue = { x, y, alert }
        const entityId = getEntityIdFromKeys([ BigInt(x), BigInt(y) ])
        const currentNeedsAttentionValue = getComponentValue(Alert, entityId)

        // do not update if it's already equal
        if (isEqual(currentNeedsAttentionValue, needsAttentionValue)) continue

        setComponent(Alert, entityId, needsAttentionValue)
      }

      return data
    },
    refetchInterval: BLOCK_TIME
  })
}
