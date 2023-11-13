import {gql} from "graphql-request";
import useGraphql from "./useGraphql";
import {
  ColorComponent, ColorCountComponent,
  OwnerComponent,
  PixelEntity,
  PixelTypeComponent,
  TimestampComponent
} from "../../global/types";
import {BigNumber} from "ethers";
import { convertToDecimal, convertToHexadecimalAndLeadWithOx } from '@/global/utils'


const query = gql`
query PixelEntity($x: String!, $y: String!) {
  entities(keys: [$x, $y]) {
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

type EntityType = {
  node: {
    keys: string[],
    components: [OwnerComponent, PixelTypeComponent, TimestampComponent, ColorComponent, ColorCountComponent]
  }
}

export type QueryReturn = {
  entities: {
    edges: EntityType[]
  }
}

export const convertEntityToPixelEntity = (entity: EntityType) => {
  let ownerComponent: OwnerComponent | undefined = undefined
  let pixelTypeComponent: PixelTypeComponent | undefined = undefined
  let timestampComponent: TimestampComponent | undefined = undefined
  let colorComponent: ColorComponent | undefined = undefined
  let colorCountComponent: ColorCountComponent | undefined = undefined

  for (const component of entity.node.components) {
    switch (component.__typename) {
      case "Color": {
        colorComponent = component
        break
      }
      case "ColorCount": {
        colorCountComponent = component
        break
      }
      case "Owner": {
        ownerComponent = component
        break
      }
      case "PixelType": {
        pixelTypeComponent = component
        break
      }
      case "Timestamp": {
        timestampComponent = component
        break
      }
    }
  }

  return {
    id: entity.node.keys[0] + '-' + entity.node.keys[1],
    owner: ownerComponent?.address ?? '',
    position: {
      x: convertToDecimal(entity.node.keys[0]),
      y: convertToDecimal(entity.node.keys[1]),
    },
    pixelType: pixelTypeComponent?.name,
    createdAt: timestampComponent?.created_at,
    updatedAt: timestampComponent?.updated_at,
    color: colorComponent ? {
      r: colorComponent.r,
      g: colorComponent.g,
      b: colorComponent.b
    } : undefined,
    colorCount: Number(BigNumber.from(colorCountComponent?.count ?? 0))
  }
}

const convertQueryReturnToPixelEntity = ({entities}: QueryReturn) => {
  const [res] = entities.edges
  if (!res) return undefined
  return convertEntityToPixelEntity(res)
}

const usePixelEntity = ([x, y]: [number, number]) => {
  const xKey = convertToHexadecimalAndLeadWithOx(x)
  const yKey = convertToHexadecimalAndLeadWithOx(y)

  return useGraphql<QueryReturn, PixelEntity | undefined>(
    ['pixelEntity', x, y],
    query,
    { x: xKey, y: yKey },
    convertQueryReturnToPixelEntity
  )

}

export default usePixelEntity
