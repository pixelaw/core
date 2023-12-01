import { Pixel } from './types'
import { createClient } from '../lib/graphql'
import { DEFAULT_COLOR, GET_ENTITIES } from './constants'
import getEnv from '../utils/getEnv'
import { shortString } from 'starknet'

const TORII_URI = getEnv<string>("PUBLIC_TORII", 'http://0.0.0.0:8080')

const client = createClient(`${TORII_URI}/graphql`)

type PixelModelType = {
  node: {
    x: number,
    y: number,
    color: number,
    text: string
    __typename: 'Pixel'
  }
}

type EntityGqlReturn = {
  data: {
    pixelModels: {
      edges: PixelModelType[]
    }
  }
}

const getState: (xMin: number, xMax: number, yMin: number, yMax: number) => Promise<Pixel[]> = async (xMin, xMax, yMin, yMax) => {
  try {
    const response: EntityGqlReturn = await client.query({
      query: GET_ENTITIES,
      fetchPolicy: "network-only",
      variables: {
        first: getEnv<number>('CANVAS_WIDTH', 256) * getEnv<number>('CANVAS_HEIGHT', 256),
        xMin,
        xMax,
        yMin,
        yMax
      }
    });

    return response.data.pixelModels.edges.map(({node}) => {
      const colorARGB = node.color.toString(16)
      const colorArray: [string, string, string, string] =
        (/^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(colorARGB) ?? ['0', '0', '0', '0']) as unknown as [string, string, string, string]

      const [a, r, g, b] = colorArray.map(colorElem => parseInt(colorElem, 16))

      let pixelText = ''
      if (node.text && node.text !== '0x0') {
        pixelText = shortString.isShortText(node.text) ? shortString.decodeShortString(node.text) : node.text
        if (pixelText.includes('U+')) {
          pixelText = pixelText.replace('U+', '')
          const codePoint = parseInt(pixelText, 16)
          pixelText = String.fromCodePoint(codePoint)
        }
      }

      return {
        x: node.x,
        y: node.y,
        color: node.color ? {
          r,
          g,
          b,
          a: a / 255
        } : {
          ...DEFAULT_COLOR,
          a: 1
        },
        text: pixelText
      }
    })
  } catch (error) {
    throw new Error("Could not get Entities", error)
  }
}

export default getState
