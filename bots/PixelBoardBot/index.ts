// Importing necessary modules
import createBoard from './createBoard'
import createDefaultPixels from './createDefaultPixels'
import getState from './getState'
import getEnv from '../utils/getEnv'
import writeBoard from './writeBoard'

const BOARD_PATH_FILE = getEnv<string>(
  'BOARD_PATH_FILE', '../web/public/assets/placeholder/pixel-state.png'
)

// Configuration object for the canvas and pixel size, and refresh rate
const pixelBoardConfig = {
  canvasSize: {
    width: getEnv<number>('CANVAS_WIDTH', 256),
    height: getEnv<number>('CANVAS_HEIGHT', 256)
  },
  pixelSize: {
    height: getEnv<number>('PIXEL_HEIGHT', 1),
    width: getEnv<number>('PIXEL_WIDTH', 1)
  },
  refreshRate: getEnv<number>('PIXEL_BOARD_REFRESH_RATE', 5_000),
  totalWorldSize: {
    width: getEnv<number>('WORLD_WIDTH', 256),
    height: getEnv<number>('WORLD_HEIGHT', 256)
  }
}

// Creating default pixels based on the canvas size
const defaultPixelState = createDefaultPixels(pixelBoardConfig.canvasSize.height, pixelBoardConfig.canvasSize.width)

// Main loop function that gets the state, creates the board, and uploads it
async function mainLoop() {
  let mapIndex = -1
  for (
    let yMin = 0;
    yMin < pixelBoardConfig.totalWorldSize.height;
    yMin += pixelBoardConfig.canvasSize.height) {
    for (
      let xMin = 0;
      xMin < pixelBoardConfig.totalWorldSize.width;
      xMin += pixelBoardConfig.canvasSize.width) {
      const { totalWorldSize, canvasSize } = pixelBoardConfig
      const xMax = xMin + canvasSize.width < totalWorldSize.width ? xMin + canvasSize.width : totalWorldSize.width - 1
      const yMax = yMin + canvasSize.height < totalWorldSize.height ? yMin + canvasSize.height : totalWorldSize.height - 1

      mapIndex++
      console.info('[PIXEL_BOARD_BOT]', `MAP INDEX[${mapIndex}]: xMin-${xMin} xMax-${xMax} yMin-${yMin} yMax-${yMax}`)

      try {
        console.info('[PIXEL_BOARD_BOT]', 'getting state from torii')
        const pixelState = await getState(xMin, xMax, yMin, yMax)

        console.info('[PIXEL_BOARD_BOT]', 'creating board')
        const board = createBoard(pixelState, pixelBoardConfig, defaultPixelState)

        // TODO: write proper file path for each mapIndex to be referenced by the ui
        console.info('[PIXEL_BOARD_BOT]', 'writing board')
        writeBoard(board, BOARD_PATH_FILE)

      } catch (error) {
        console.error("Error with PixelBoardBot", error)
      }
    }
  }

  // Setting the loop to run at the specified refresh rate
  setTimeout(mainLoop, pixelBoardConfig.refreshRate);
}

// Function to start the bot
async function startBot () {
  console.info("PixelBoardBot starting")
  await mainLoop()
}

// Exporting the start function as default
export default startBot
