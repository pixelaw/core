import useGraphql from "./useGraphql";
import {gql} from "graphql-request";
import {PixelEntity} from '@/global/types.ts';
import {
  convertEntityToPixelEntity,
  QueryReturn,
} from './usePixelEntity'
import {BLOCK_TIME} from '@/global/constants.ts';

export const QUERY_KEY = ["paintedPixels"]

const query = gql`
query all_entities{
  entities(keys: ["%"] first: 4096) {
    edges {
      node {
        keys
        components {
          ... on Color {
            __typename
            r
            g
            b
          }
          ... on Timestamp {
            created_at
            updated_at
            __typename
          }
          ... on Owner {
            address
            __typename
          }
          ... on PixelType {
            name
            __typename
          }
          ... on ColorCount {
            count
            __typename
          }
        }
      }
    }
  }
}
`
const PAINTED = "0x7061696e74"
const usePaintedPixels = () => {
  return useGraphql<QueryReturn, PixelEntity[]>(
    QUERY_KEY,
    query,
    undefined,
    ({entities}) => entities.edges
      .map(convertEntityToPixelEntity)
      .filter(entity => entity.pixelType === PAINTED),
    {
      refetchInterval: BLOCK_TIME,
      initialData: []
    }
  )
}

export default usePaintedPixels
