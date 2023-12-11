import { useQuery } from '@tanstack/react-query'
import { useDojo } from '@/DojoContext.tsx'
import { getComponentValue, setComponent } from '@latticexyz/recs'
import { getEntityIdFromKeys } from '@dojoengine/utils'
import isEqual from 'lodash/isEqual'

export function useFilteredEntities(
  xMin: number,
  xMax: number,
  yMin: number,
  yMax: number,
) {
  const {
    setup: {
      components: {
        Pixel
      },
      network: { graphSdk },
    },
  } = useDojo()

  return useQuery({
    queryKey: ['filtered-entities', xMin, xMax, yMin, yMax],
    queryFn: async () => {
      const {data} = await graphSdk.all_filtered_entities({first: 65536, xMin, xMax, yMin, yMax})
      if (!data || !data.pixelModels?.edges) return { pixelModels: { edges: [] } }
      for (const edge of data.pixelModels.edges) {
        if (!edge || !edge.node) continue
        const fetchedNode = edge.node
        const entityId = getEntityIdFromKeys([ BigInt(fetchedNode.x), BigInt(fetchedNode.y) ])
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        delete fetchedNode['__typename']
        const currentPixel = getComponentValue(Pixel, entityId)

        // do not update if it's already equal
        if (isEqual(currentPixel, fetchedNode)) continue

        // to update latticexyz indexer
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        setComponent(Pixel, entityId, fetchedNode)
      }

      return data
    }
  })
}
