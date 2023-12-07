import fetchApi from '../utils/fetchApi'
import { Account, num } from 'starknet'
import execute from '../utils/execute'
import { eventsToProcess } from './memory'
import { getProvider } from './utils'
import getEnv from '../utils/getEnv'
import streamToString from '../utils/streamToString'

let botPrivateKey = ''
let botAddress = ''

type AccountType = {
  address: string,
  balance: string,
  class_hash: string,
  private_key: string,
  public_key: string
}

let coreActionsAddress = ''
const CORE_ACTIONS_SELECTOR = "process_queue"

const API_URL = getEnv("API_URL", "http://0.0.0.0:3000")

const fetchCoreAddress: () => Promise<string> = async () => {
  const result = await fetch(`${API_URL}/manifests/core`)
  const stream = result.body
  if (!stream) throw new Error("Stream not found")
  const processedStream = await streamToString(stream)
  const { contracts } = JSON.parse(processedStream)
  return contracts.find(contract => contract.name === 'actions')?.address ?? ''
}

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
    const [master] = await fetchApi<AccountType[]>("accounts", "json")
    botAddress = master.address
    botPrivateKey = master.private_key
  }

  if (!coreActionsAddress) {
    coreActionsAddress = await fetchCoreAddress()
  }

  const signer = new Account(getProvider(), botAddress, botPrivateKey)
  return execute(signer, coreActionsAddress, CORE_ACTIONS_SELECTOR, callData)
}

// actual queue processing
const processUnlockables = async () => {
  if (!Object.values(eventsToProcess).length) return
  const currentBlock = await getProvider().getBlock("latest")
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
