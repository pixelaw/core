import getEnv from '../utils/getEnv'

export const QUEUE_STARTED_KEY_EVENT = "0x1c4fa7f75d1ea055adccbf8f86b75224181a3036d672762185805e0b999ad65"
export const QUEUE_FINISHED_KEY_EVENT = "0x16c4dd771da9a5cb32846fbb15c1b614da08fb5267af2fcce902a4c416e76cf"
export const RPC_URL = getEnv("PUBLIC_NODE_URL", "http://0.0.0.0:5050")

export const TORII_URI = getEnv<string>("PUBLIC_TORII", 'http://0.0.0.0:8080')
