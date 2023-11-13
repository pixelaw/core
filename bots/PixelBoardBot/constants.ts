import { gql } from 'graphql-tag'
import getEnv from '../utils/getEnv'
import hexToRGB from '../utils/hexToRGB'
export const GET_ENTITIES = gql`query getPixels(
  $first: Int
  $xMin: u64
  $xMax: u64
  $yMin: u64
  $yMax: u64
) {
  pixelModels(
    first: $first
    where: { xGTE: $xMin, xLTE: $xMax, yGTE: $yMin, yLTE: $yMax }
  ) {
    edges {
      node {
        x
        y
        color
        text
        __typename
      }
    }
  }
}
`;

export const DEFAULT_COLOR = hexToRGB(getEnv<string>('DEFAULT_PIXEL_COLOR', "#2f1643"))
