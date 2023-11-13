import PixelBoardBot from './PixelBoardBot'
import QueueBot from './QueueBot'

function startBots() {
  PixelBoardBot().then()
  QueueBot().then()
}

// Start the initial request
startBots();
