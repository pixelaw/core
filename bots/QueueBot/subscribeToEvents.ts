import { createClient as createWsClient } from 'graphql-transport-ws/lib/client'
import { QUEUE_FINISHED_KEY_EVENT, QUEUE_STARTED_KEY_EVENT, TORII_URI } from './constants'
import { addToQueue, queue } from './queue'
import { WebSocket } from 'ws'

type SubscriptionEvent = {
  data: {
    eventEmitted: {
      data: string[]
    }
  }
}

export const subscribeToEvents = () => {
  const QUEUE_STARTED_SUBSCRIPTION = `
    subscription queueStarted {
      eventEmitted(keys: ["${QUEUE_STARTED_KEY_EVENT}"]) {
        data
      }
    }
  `

  const QUEUE_FINISHED_SUBSCRIPTION = `
    subscription queueStarted {
      eventEmitted(keys: ["${QUEUE_FINISHED_KEY_EVENT}"]) {
        data
      }
    }
  `

  const client = createWsClient({
    url: `${TORII_URI}/graphql`.replace('http', 'ws'),
    webSocketImpl: WebSocket,
  })

  const cleanup1 = client.subscribe<SubscriptionEvent>(
    { query: QUEUE_STARTED_SUBSCRIPTION },
    {
      next: (d) => addToQueue(d.data.eventEmitted.data),
      error: (err) => console.error(err),
      complete: () => console.log('Subscription completed')
    }
  )

  const cleanup2 = client.subscribe<SubscriptionEvent>(
    { query: QUEUE_FINISHED_SUBSCRIPTION },
    {
      next: (d) => delete queue[d.data.eventEmitted.data[0]],
      error: (err) => console.error(err),
      complete: () => console.log('Subscription completed')
    }
  )

  return [cleanup1, cleanup2]
}
