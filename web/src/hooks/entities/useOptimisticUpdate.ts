import { useSetAtom } from 'jotai'
import { optimisticDataAtom } from '@/global/states'
import { getEntityIdFromKeys } from '@dojoengine/utils'
import { EntityIndex } from '@latticexyz/recs'
import { uuid } from '@latticexyz/utils'
import { useDojo } from '@/DojoContext'
import { convertToDecimal } from '@/global/utils'

const useOptimisticUpdate = (position: {x: number, y: number}, color: string) => {
  const setOptimisticUpdate = useSetAtom(optimisticDataAtom)

  const {
    setup: {
      components: { Pixel }
    },
  } = useDojo()

  const entityId = getEntityIdFromKeys([BigInt(position.x), BigInt(position.y)]) as EntityIndex
  const solidColor = color.replace('#', '0xFF')
  const decimalColor = convertToDecimal(solidColor)

  const index: `${number}-${number}` = `${position.x}-${position.y}`

  const update = () => {
      const pixelId = uuid()
      setOptimisticUpdate(prevOptimisticUpdate => {
        return {
          ...prevOptimisticUpdate,
          [index]: pixelId
        }
      })
      Pixel.addOverride(pixelId, {
        entity: entityId,
        value: {
          color: decimalColor
        }
      })
    }

  const remove = () => {
    setOptimisticUpdate(prevOptimisticUpdate => {
      const prevValues: Record<`${number}-${number}`, string> = {}
      for (const [ key, value ] of Object.entries(prevOptimisticUpdate)) {
        if (key === index) {
          const pixelId = prevOptimisticUpdate[index]
          Pixel.removeOverride(pixelId)
          continue
        }
        prevValues[key as `${number}-${number}`] = value
      }
      return prevValues
    })
  }

    return { update, remove }
}

export default useOptimisticUpdate
