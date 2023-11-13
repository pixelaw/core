import indexEvents from './indexEvents'
import processUnlockables from './processUnlockables'
import getEnv from '../utils/getEnv'

const config = {
  refreshRate: getEnv<number>("QUEUE_BOT_REFRESH_RATE", 1_000)
}

async function loop() {
  await indexEvents()
  await processUnlockables()
  setTimeout(loop, config.refreshRate);
}

async function start () {
  console.info("QueueBot is starting")
  await loop()
}

export default start
