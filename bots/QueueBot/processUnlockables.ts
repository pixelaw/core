import fetchApi from '../utils/fetchApi'
import { Account, num } from 'starknet'
import execute from '../utils/execute'
import { getProvider } from './utils'
import { queue } from './queue'
import getCoreAddress from './getCoreAddress'

let botPrivateKey = '0x2bbf4f9fd0bbb2e60b0316c1fe0b76cf7a4d0198bd493ced9b8df2a3a24d68a'
let botAddress = '0x003c4dd268780ef738920c801edc3a75b6337bc17558c74795b530c0ff502486'

type AccountType = {
  address: string,
  balance: string,
  class_hash: string,
  private_key: string,
  public_key: string
}

let coreActionsAddress = ''
const CORE_ACTIONS_SELECTOR = "process_queue"

// wrapper for the execute function and solely for processing the queue
const processQueue = async (id: string, timestamp: bigint, called_system: string, selector: string, args: num.BigNumberish[]) => {
  console.log(`executing ${called_system}-${selector} with args: ${args.join(", ")}`)
  const callData = [
    id,
    timestamp,
    called_system,
    selector,
    args.length,
    ...args
  ]

  if (!botAddress || !botPrivateKey) {
    const [master] = await fetchApi<AccountType[]>("accounts", "json")
    botAddress = master.address
    botPrivateKey = master.private_key
  }

  if (!coreActionsAddress) {
    coreActionsAddress = await getCoreAddress()
  }

  const signer = new Account(getProvider(), botAddress, botPrivateKey)
  // console.log('check', signer, coreActionsAddress, CORE_ACTIONS_SELECTOR, callData)
  let result = await execute(signer, coreActionsAddress, CORE_ACTIONS_SELECTOR, callData)
  return result
}

// actual queue processing
const processUnlockables = async () => {
  if (!Object.values(queue).length) return
  const currentBlock = await getProvider().getBlock("latest")
  const blockTimeStamp = currentBlock.timestamp
  const unlockables = Object.values(queue)
    .filter(eventToProcess => blockTimeStamp >= eventToProcess.timestamp)
    .sort((eventToProcessA, eventToProcessB) => Number(eventToProcessA.timestamp - eventToProcessB.timestamp))

  if (!unlockables.length) return

  for (const unlockable of unlockables) {
    try {
      await processQueue(unlockable.id, unlockable.timestamp, unlockable.called_system, unlockable.selector, unlockable.calldata)
    }catch(error){
      console.error("Error while processing ", unlockable, error)
    }
  }
}

export default processUnlockables
