import { createCanvas } from 'canvas'
import { Pixel } from './types'

type BoardConfig = {
  canvasSize: {
    height: number,
    width: number
  },
  pixelSize: {
    height: number,
    width: number
  }
}

const createBoard = (data: Pixel[], config: BoardConfig, defaultPixels?: Pixel[]) => {
  const canvas = createCanvas(config.canvasSize.width, config.canvasSize.height)
  const ctx = canvas.getContext("2d")

  const dataPoints = new Set(data.map(({x, y}) => `${x},${y}`))

  const filteredPixels = (defaultPixels ?? []).filter(({x, y}) => !dataPoints.has(`${x},${y}`))

  const board = [...data, ...filteredPixels]

  board.forEach(item => {
    ctx.fillStyle = `rgb(${item.color.r}, ${item.color.g}, ${item.color.b})`;
    ctx.fillRect(item.x, item.y, config.pixelSize.width, config.pixelSize.height);
    if (item.text) {
      ctx.textAlign = 'center'
      ctx.fillText(item.text, item.x + config.pixelSize.width / 2, item.y + config.pixelSize.height / 2);
    }

  });

  return canvas.toBuffer('image/png')
}

export default createBoard
