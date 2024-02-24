import { createClient } from '../lib/graphql'
import { TORII_URI } from './constants'
import { gql } from 'graphql-tag'

const QUERY_CORE_ADDRESS = gql`
  query coreActionsAddress {
    coreActionsAddressModels {
      edges {
        node {
          key
          value
        }
      }
    }
  }
`

type CoreActionsAddressType = {
  data: {
    coreActionsAddressModels: {
      edges: {
        node: {
          key: string,
          value: string
        }
      }[]
    }
  }
}

const getCoreAddress = async () => {
  const client = createClient(`${TORII_URI}/graphql`)
  const { data: { coreActionsAddressModels: { edges: [{ node: { value }}]}}}: CoreActionsAddressType =  await client.query({
    query: QUERY_CORE_ADDRESS
  })
  if (!value) throw new Error('core actions has not been initialized')
  return value
}

export default getCoreAddress
