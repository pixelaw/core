// something to add to torii
import { provider, QUEUE_FINISHED_KEY_EVENT, QUEUE_STARTED_KEY_EVENT } from './constants'
import { eventsToProcess } from './memory'

let lastBlockIndexed = 0

async function indexEvents () {
  const currentBlock = await provider.getBlock("latest")

  if (lastBlockIndexed === currentBlock.block_number) return
  console.log(`INDEXING FROM ${lastBlockIndexed} TO ${currentBlock.block_number}`)

  for (let i = lastBlockIndexed; i <= currentBlock.block_number; i++) {
    let blockI = await provider.getBlock(i)
    console.log('indexing block: ', blockI.block_number)
    const receiptPromises = blockI
      .transactions
      .map(txHash => provider.getTransactionReceipt(txHash))


    const receipts = (
      await Promise.allSettled(receiptPromises))
      // @ts-ignore
      .filter(x => x.status === "fulfilled").map(x => x.value)
    for (const receipt of receipts) {
      const queueStartedEvents = receipt.events.filter(event => event.keys[0] === QUEUE_STARTED_KEY_EVENT)
      const queueFinishedIds = receipt.events
        .filter(event => event.keys[0] === QUEUE_FINISHED_KEY_EVENT)
        .map(event => event.data[0])

      for (const queueStartedEvent of queueStartedEvents) {
        const [id, timestamp, called_system, selector, _, ...calldata] = queueStartedEvent.data
        if (queueFinishedIds.includes(id)) delete eventsToProcess[id]
        else if (!eventsToProcess[id])  {
          eventsToProcess[id] = {
            id,
            timestamp,
            called_system,
            selector,
            calldata
          }
        }
      }
      for (const queueFinishedId of queueFinishedIds) {
        delete eventsToProcess[queueFinishedId]
      }
    }

    lastBlockIndexed = i
  }
}

export default indexEvents
