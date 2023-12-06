import { useQuery } from '@tanstack/react-query'
import { useDojo } from '@/DojoContext.tsx'
import { getComponentValue, setComponent } from '@latticexyz/recs'
import { getEntityIdFromKeys } from '@dojoengine/utils'
import { BLOCK_TIME } from '@/global/constants.ts'
import isEqual from 'lodash/isEqual'

export function useInstructions() {
  const {
    setup: {
      components: {
        Instruction
      },
      network: { graphSdk },
    },
  } = useDojo()

  return useQuery({
    queryKey: ['instructions'],
    queryFn: async () => {
      const {data} = await graphSdk.instructions()
      if (!data || !data.instructionModels?.edges) return { instructionModels: { edges: [] } }
      for (const edge of data.instructionModels.edges) {
        if (!edge || !edge.node) continue
        const {system, selector, instruction} = edge.node
        const entityId = getEntityIdFromKeys([
          BigInt(system),
          BigInt(selector)
        ])

        const currentInstruction = getComponentValue(Instruction, entityId)

        // do not update if it's already equal
        if (!isEqual(currentInstruction, {system, selector, instruction})) setComponent(Instruction, entityId, {system, selector, instruction})
      }

      return data
    },
    refetchInterval: BLOCK_TIME,
  })
}
