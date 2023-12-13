import processUnlockables from './processUnlockables'
import getEnv from '../utils/getEnv'
import { getQueue } from './queue'
import { subscribeToEvents } from './subscribeToEvents'
import checkSiteHealth from '../utils/checkSiteHealth'
import { RPC_URL, TORII_URI } from './constants'

const config = {
  refreshRate: getEnv<number>("QUEUE_BOT_REFRESH_RATE", 1_000)
}

async function loop() {
  try {
    await processUnlockables()
  } catch (e) {
    console.error('QueueBot failed to process unlockables due to: ', e)
  }
  setTimeout(loop, config.refreshRate);
}

async function tryStartup() {
  // do not try anything if torii and the rpc url is not yet up
  if(!await checkSiteHealth(TORII_URI, true) || !await checkSiteHealth(RPC_URL, true)) {
    setTimeout(tryStartup, config.refreshRate)
    return
  }

  let cleanupFunctions: (() => void)[] = []
  try {
    await getQueue()
    cleanupFunctions = subscribeToEvents()
  }
  catch (e) {
    console.error("QueueBot startup failed due to: ", e)
    cleanupFunctions.forEach(cleanupFunction => cleanupFunction())
    setTimeout(tryStartup, config.refreshRate)
    return
  }
  console.info('[QUEUE_BOT] started successfully')
}

async function start () {
  console.info("[QUEUE_BOT] starting...")
  await tryStartup()
  await loop()
}

export default start
