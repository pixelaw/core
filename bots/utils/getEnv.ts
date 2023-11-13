import * as dotenv from 'dotenv'

dotenv.config()

const ACCEPTED_VARIABLES = [
  'PIXEL_BOARD_REFRESH_RATE',
  'BOARD_PATH_FILE',
  'CANVAS_WIDTH',
  'CANVAS_HEIGHT',
  'PIXEL_HEIGHT',
  'PIXEL_WIDTH',
  'DEFAULT_PIXEL_COLOR',
  'WORLD_WIDTH',
  'WORLD_HEIGHT',
  'QUEUE_BOT_REFRESH_RATE',
  'TORII_URI',
  'RPC_URL',
  'API_URL'
] as const

const getEnv = <T>(variable: typeof ACCEPTED_VARIABLES[number], def: T) => {
  const value = process.env[variable]
  if (!value) return def
  if (typeof def === "number") return parseInt(value) as T
  else return value as T
}

export default getEnv
