import fetchApi from '../utils/fetchApi'
import { Account, num } from 'starknet'
import execute from '../utils/execute'
import { getProvider } from './utils'
import { queue } from './queue'
import getCoreAddress from './getCoreAddress'
import { sleep } from '../utils/sleep'
const _ = require("lodash");

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

const MAX_TRANSACTIONS_AT_A_TIME = 10

// actual queue processing
const processUnlockables = async () => {
  if (!Object.values(queue).length) return
  const currentBlock = await getProvider().getBlock("latest")
  const blockTimeStamp = currentBlock.timestamp

  if (!botAddress || !botPrivateKey) {
    const [master] = await fetchApi<AccountType[]>("accounts", "json")
    botAddress = master.address
    botPrivateKey = master.private_key
  }

  if (!coreActionsAddress) {
    coreActionsAddress = await getCoreAddress()
  }


  const unlockables = Object.values(queue)
    .filter(eventToProcess => blockTimeStamp >= eventToProcess.timestamp)
    .sort((eventToProcessA, eventToProcessB) => Number(eventToProcessA.timestamp - eventToProcessB.timestamp))
    .map(unlockable => {
      return {
        contractAddress: coreActionsAddress,
        entrypoint: CORE_ACTIONS_SELECTOR,
        calldata: [
          unlockable.id,
          unlockable.timestamp,
          unlockable.called_system,
          unlockable.selector,
          unlockable.calldata.length,
          ...unlockable.calldata
        ]
      }
    })

  if (!unlockables.length) return

  const signer = new Account(getProvider(), botAddress, botPrivateKey)

  const unlockableChunks = _.chunk(unlockables, MAX_TRANSACTIONS_AT_A_TIME)

  for (const unlockableChunk of unlockableChunks) {
    console.log(`[${Date.now()}] executing (${unlockableChunk.length}): ${unlockableChunk.map(unlockable => unlockable.calldata[0]).join(', ')}`)
    console.log('--------------------------------------------------------------------------------------------------------\n')
    try{
      await execute(signer, unlockableChunk)
      sleep(1)
    }catch(e){
      console.error("Error unlockableChunk", e)
    }
  }


}

export default processUnlockables
