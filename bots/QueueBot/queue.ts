import { QUEUE_FINISHED_KEY_EVENT, QUEUE_STARTED_KEY_EVENT } from './constants'
import { gql } from 'graphql-tag'
import { createClient } from '../lib/graphql'
import { TORII_URI } from './constants'

type QueueType = {
  id: string,
  timestamp: bigint,
  called_system: string,
  selector: string,
  calldata: string[]
}

type EventType = {
  edges: {
    node: {
      id: string,
      keys: string[],
      data: string[],
      createdAt: string,
      transactionHash: string
    }
  }[],
  totalCount: number
}

type EntityGqlReturn = {
  data: {
    queueStarted: EventType,
    queueFinished: EventType
  }
}

export const queue: Record<string, QueueType> = {}

const FIRST = 10_000

const EVENT_NODE_TEMPLATE = `
      edges {
        node {
          id
          keys
          data
          createdAt
          transactionHash
        }
      }
      totalCount
`

const QUERY = gql`
  query queue {
    queueStarted: events(keys: ["${QUEUE_STARTED_KEY_EVENT}"], first: ${FIRST}) {
      ${EVENT_NODE_TEMPLATE}
    }
    queueFinished: events(keys: ["${QUEUE_FINISHED_KEY_EVENT}"], first: ${FIRST}) {
      ${EVENT_NODE_TEMPLATE}
    }
  }
`

export const addToQueue = (data: string[]) => {
  const [id, timestamp, called_system, selector, _, ...calldata] = data
  queue[id] = {
    id,
    timestamp: BigInt(timestamp),
    called_system,
    selector,
    calldata
  }
}

export const getQueue = async () => {
  const client = createClient(`${TORII_URI}/graphql`)
  const { data: { queueStarted, queueFinished }}: EntityGqlReturn = await client.query({
    query: QUERY
  })
  const finishedIds = queueFinished.edges.map(edge => edge.node.data[0])
  queueStarted.edges.filter(edge => !finishedIds.includes(edge.node.data[0]))
    .forEach(({ node }) => addToQueue(node.data))
}
