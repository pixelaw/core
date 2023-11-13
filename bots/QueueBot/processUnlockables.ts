import fetchApi from '../utils/fetchApi'
import { Account, num } from 'starknet'
import execute from '../utils/execute'
import { MASTER_ACCOUNT_ADDRESS, MASTER_PRIVATE_KEY, PROCESS_QUEUE_SYSTEM_IN_HEX, provider } from './constants'
import { eventsToProcess } from './memory'

let botPrivateKey = ''
let botAddress = ''

type AccountType = {
  address: string,
  balance: string,
  class_hash: string,
  private_key: string,
  public_key: string
}

// TODO: get this from manifest.json
const CORE_ACTIONS_ADDRESS = "0x5a8c45891c00ab589542d169769555327af8cdf9fae5d042263fd9b49d4df9a"
const CORE_ACTIONS_SELECTOR = "process_queue"

// wrapper for the execute function and solely for processing the queue
const processQueue = async (id: string, timestamp: number, called_system: string, selector: string, args: num.BigNumberish[]) => {
  console.log(`executing ${called_system}-${selector} with args: ${args.join(", ")}`)
  const callData = [
    id,
    timestamp,
    called_system,
    selector,
    args.length,
    ...args
  ]

  console.log(callData)

  if (!botAddress || !botPrivateKey) {
    // const accounts = await fetchApi<AccountType[]>("accounts", "json")
    const master = {
      address: MASTER_ACCOUNT_ADDRESS,
      private_key: MASTER_PRIVATE_KEY
    }
    botAddress = master.address
    botPrivateKey = master.private_key
  }

  const signer = new Account(provider, botAddress, botPrivateKey)
  return execute(signer, CORE_ACTIONS_ADDRESS, CORE_ACTIONS_SELECTOR, callData)
}

// actual queue processing
const processUnlockables = async () => {
  if (!Object.values(eventsToProcess).length) return
  const currentBlock = await provider.getBlock("latest")
  const blockTimeStamp = currentBlock.timestamp
  const unlockables = Object.values(eventsToProcess)
    .filter(eventToProcess => blockTimeStamp >= eventToProcess.timestamp)
    .sort((eventToProcessA, eventToProcessB) => eventToProcessA.timestamp - eventToProcessB.timestamp)

  if (!unlockables.length) return

  for (const unlockable of unlockables) {
    await processQueue(unlockable.id, unlockable.timestamp, unlockable.called_system, unlockable.selector, unlockable.calldata)
  }
}

export default processUnlockables
