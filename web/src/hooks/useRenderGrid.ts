import { useCallback } from 'react'
import { CellDatum } from '@/components/shared/DrawPanel.tsx'
import { felt252ToString } from '@/global/utils'

export function useRenderGrid() {
  return useCallback((ctx: CanvasRenderingContext2D, options: {
    width: number,
    height: number,
    cellSize: number,
    coordinates: [ number | undefined, number | undefined ] | undefined
    panOffsetX: number,
    panOffsetY: number,
    selectedHexColor: string,
    visibleAreaXStart: number,
    visibleAreaXEnd: number,
    visibleAreaYStart: number,
    visibleAreaYEnd: number,
    pixels: Array<CellDatum | undefined> | undefined
    focus: Array<{x: number, y: number}>
  }) => {
    const {
      cellSize,
      width,
      height,
      panOffsetX,
      panOffsetY,
      coordinates,
      selectedHexColor,
      visibleAreaXStart,
      visibleAreaXEnd,
      visibleAreaYStart,
      visibleAreaYEnd,
      pixels,
      focus
    } = options

    ctx.clearRect(0, 0, width, height)

    for (let row = visibleAreaXStart; row <= visibleAreaXEnd; row++) {
      for (let col = visibleAreaYStart; col <= visibleAreaYEnd; col++) {
        const x = row * cellSize + panOffsetX
        const y = col * cellSize + panOffsetY

        let pixelColor = '#2F1643' // default color
        let pixelText = ''

        if (pixels && pixels.length > 0) {
          const pixel = pixels.find(p => p && p.coordinates[0] === row && p.coordinates[1] === col)
          if (pixel) {
            /// if hexColor from the contract is empty, then use default color
            pixel.hexColor = pixel.hexColor === '0x0' ? pixelColor : pixel.hexColor
            // Get the current color of the pixel
            const imageData = ctx.getImageData(x, y, 1, 1).data
            const currentColor = '#' + ((1 << 24) | (imageData[0] << 16) | (imageData[1] << 8) | imageData[2]).toString(16).slice(1)

            if (pixel.text && pixel.text !== '0x0') {
              pixelText = pixel.text
            }

            // Check if the pixel color has changed
            if (pixel.hexColor !== currentColor) {
              pixelColor = pixel.hexColor
            } else {
              // Skip this iteration if the pixel color hasn't changed
              continue
            }
          }
        }

        if (coordinates && row === coordinates[0] && col === coordinates[1]) {
          pixelColor = selectedHexColor
        }

        ctx.fillStyle = pixelColor
        ctx.fillRect(x, y, cellSize, cellSize)
        ctx.strokeStyle = '#2E0A3E'
        ctx.strokeRect(x, y, cellSize, cellSize)

        if(focus.length){
          const pixelNeedAttention = focus.find(p => p.x === row && p.y === col)
          if(pixelNeedAttention){
            ctx.strokeStyle = '#FFFFFF'
            ctx.shadowColor = '#FFFFFF'
            ctx.shadowBlur = 10
            ctx.strokeRect(x, y, cellSize, cellSize)
            ctx.shadowColor = 'transparent'
          }
        }



        if (pixelText) {
          ctx.textAlign = 'center'

          /// "✂" seems to not have its own color and such so doing a quick fix by adding a fill-color to it
          if (pixelText === '0x552b32373032') {
            ctx.fillStyle = 'red'
          }
          ctx.font=`${(cellSize / 2)}px Serif`

          let text = felt252ToString(pixelText)

          if (text.includes('U+')) {
              text = text.replace('U+', '')
              const codePoint = parseInt(text, 16)
              text = String.fromCodePoint(codePoint)
          }

          ctx.fillText(text, x + cellSize / 2, y + cellSize / 1.5)
        }

      }
    }
  }, [])
}
