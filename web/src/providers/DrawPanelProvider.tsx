import React, {SetStateAction} from 'react'
import {CellDatum, Coordinate} from '@/components/shared/DrawPanel.tsx'
import {useDojo} from '@/DojoContext.tsx'
import { useAtom, useAtomValue } from 'jotai'
import {
  colorAtom,
  gameModeAtom,
  notificationDataAtom,
  positionWithAddressAndTypeAtom,
  zoomLevelAtom,
} from '@/global/states.ts'
import {CANVAS_HEIGHT, CANVAS_WIDTH, MAX_CELL_SIZE, MAX_ROWS_COLS} from '@/global/constants.ts'
import {useEntityQuery} from '@dojoengine/react'
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import {getComponentValue, Has} from '@latticexyz/recs'
import { argbToHex } from '@/global/utils.ts'
import useInteract from '@/hooks/systems/useInteract'
import ParamPicker from '@/components/ParamPicker'

type DrawPanelType = {
  gameMode: string,
  cellSize: number,
  selectedHexColor: string
  coordinates: [ number | undefined, number | undefined ] | undefined
  visibleAreaStart: [ number, number ]
  visibleAreaEnd: [ number, number ]
  panOffsetX: number
  panOffsetY: number
  setPanOffsetX: React.Dispatch<SetStateAction<number>>
  setPanOffsetY: React.Dispatch<SetStateAction<number>>
  data?: Array<CellDatum | undefined> | undefined,

  onCellClick?: (position: [ number, number ]) => void,
  onVisibleAreaCoordinate?: (visibleAreaStart: Coordinate, visibleAreaEnd: Coordinate) => void
  onHover?: (coordinate: Coordinate) => void
}

export const DrawPanelContext = React.createContext<DrawPanelType>({} as DrawPanelType)

export default function DrawPanelProvider({ children }: { children: React.ReactNode }) {
  const {
    setup: {
      components: {
        Pixel
      },
    },
  } = useDojo()


  //mode of the game
  const gameMode = useAtomValue(gameModeAtom)
  //cell size or pixel size
  const zoomLevel = useAtomValue(zoomLevelAtom)
  const cellSize = MAX_CELL_SIZE * (zoomLevel / 100)

  //selected color in color pallet
  const [ selectedHexColor,  ] = useAtom(colorAtom)

  // offset is a negative value
  const [ panOffsetX, setPanOffsetX ] = React.useState<number>(0)
  const [ panOffsetY, setPanOffsetY ] = React.useState<number>(0)

  //For setting the visible area
  const [ visibleAreaStart, setVisibleAreaStart ] = React.useState<[ number, number ]>([ 0, 0 ])
  const [ visibleAreaEnd, setVisibleAreaEnd ] = React.useState<[ number, number ]>([ 28, 8 ])

  //setting the coordinates and passing it to plugin when hover in the cell
  const [position, setPositionWithAddressAndType] = useAtom(positionWithAddressAndTypeAtom)

  const { interact, params, instruction } = useInteract(
    `${gameMode}`,
    selectedHexColor,
    {
      x: position?.x ?? 10,
      y: position?.y ?? 10
    }
  )

  const hasParams = !!params.length

  const [additionalParams, setAdditionalParams] = React.useState<Record<string,any>>({})

  React.useEffect(() => {
    setAdditionalParams({})
  }, [gameMode])


  //for notification
  const [ notificationData, ] = useAtom(notificationDataAtom)

  const pixelData: Record<`[${number},${number}]`, { color: string, text: string}> = {}

  const entityIds = useEntityQuery([ Has(Pixel) ])

  const pixels = entityIds
    .map(entityId => getComponentValue(Pixel, entityId))
    .filter(entity => !!entity)
    .filter(entity => entity?.color !== 0)


  pixels.forEach(pixel => {
    pixelData[`[${pixel!.x},${pixel!.y}]`] = {
      color: argbToHex(pixel!.color),
      text: pixel?.text?.toString() ?? ''
    }
  })

  const handleData = () => {
    const data = {
      ...pixelData,
    }
    return Object.entries(data).map(([ key, value ]) => {
      return {
        coordinates: key.match(/\d+/g)?.map(Number) as [ number, number ],
        hexColor: value.color,
        text: value.text
      }
    })
  }

  const [openModal, setOpenModal] = React.useState(false)
  const handleInteract = (otherParams?: Record<string, any>) => {
    const variables = hasParams ? {
      otherParams
    } : {}

    interact.mutateAsync(variables)
      .then()
      .catch(err => {
        console.error('reversing color because of: ', err)
      })

    setOpenModal(false)
    setAdditionalParams({})
  }

  const handleCellClick = (coordinate: Coordinate) => {
    setPositionWithAddressAndType(() => {
      const pixel = pixels.find(pixel => pixel!.x === coordinate[0] && pixel!.y == coordinate[1])
      return {
        x: coordinate[0],
        y: coordinate[1],
        address: pixel ? pixel.owner : 'N/A',
        pixel: pixel ? pixel.app : 'N/A'
      }
    })
    if (hasParams) setOpenModal(true)
    else handleInteract()
  }

  const handleVisibleAreaCoordinate = (visibleAreaStart: Coordinate, visibleAreaEnd: Coordinate) => {
    const expansionFactor = 10
    const minLimit = 0, maxLimit = 256

    const expandedMinX = visibleAreaStart[0] - expansionFactor
    const expandedMinY = visibleAreaStart[1] - expansionFactor

    const expandedMaxX = visibleAreaEnd[0] + expansionFactor
    const expandedMaxY = visibleAreaEnd[1] + expansionFactor


    visibleAreaStart[0] = expandedMinX < minLimit ? minLimit : expandedMinX
    visibleAreaStart[1] = expandedMinX < minLimit ? minLimit : expandedMinY

    visibleAreaEnd[0] = expandedMaxX > maxLimit ? maxLimit : expandedMaxX
    visibleAreaEnd[1] = expandedMaxY > maxLimit ? maxLimit : expandedMaxY

    setVisibleAreaStart(visibleAreaStart)
    setVisibleAreaEnd(visibleAreaEnd)
  }

  const handleHover = (coordinate: Coordinate) => {
    // do not hover when the modal is open
    if (openModal) return
    setPositionWithAddressAndType(() => {
      const pixel = pixels.find(pixel => pixel!.x === coordinate[0] && pixel!.y == coordinate[1])
      return {
        x: coordinate[0],
        y: coordinate[1],
        address: pixel ? pixel.owner : 'N/A',
        pixel: pixel ? pixel.app : 'N/A'
      }
    })
  }

  React.useEffect(() => {
    if (!notificationData) return
    const targetPixelX = notificationData.x * cellSize
    const targetPixelY = notificationData.y * cellSize

    const offsetX = targetPixelX - CANVAS_WIDTH / 2
    const offsetY = targetPixelY - CANVAS_HEIGHT / 2

    const maxOffsetX = -(MAX_ROWS_COLS * cellSize - CANVAS_WIDTH)
    const maxOffsetY = -(MAX_ROWS_COLS * cellSize - CANVAS_HEIGHT)

    setPanOffsetX(offsetX < 0 ? 0 : Math.abs(offsetX) > Math.abs(maxOffsetX) ? maxOffsetX : -offsetX)
    setPanOffsetY(offsetY < 0 ? 0 : Math.abs(offsetY) > Math.abs(maxOffsetY) ? maxOffsetY : -offsetY)

  }, [cellSize, notificationData])

  return (
    <DrawPanelContext.Provider value={{
      gameMode,
      cellSize,
      selectedHexColor,
      coordinates: [position.x, position.y],
      visibleAreaStart,
      visibleAreaEnd,
      panOffsetX,
      panOffsetY,
      setPanOffsetX,
      setPanOffsetY,
      data: handleData(),
      onCellClick: handleCellClick,
      onVisibleAreaCoordinate: handleVisibleAreaCoordinate,
      onHover: handleHover,
    }}>
      {children}
      <ParamPicker
        instruction={instruction}
        value={additionalParams}
        onChange={(newValue) => setAdditionalParams(newValue)}
        onSelect={(newValue) => handleInteract(newValue)}
        onSubmit={() => handleInteract(additionalParams)}
        params={params}
        open={openModal}
        onOpenChange={(open) => setOpenModal(open)}
      />
    </DrawPanelContext.Provider>
  )
}

export function useDrawPanel() {
  return React.useContext(DrawPanelContext)
}
