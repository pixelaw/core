import { Provider } from 'starknet'
import getEnv from '../utils/getEnv'

export const QUEUE_STARTED_KEY_EVENT = "0x1c4fa7f75d1ea055adccbf8f86b75224181a3036d672762185805e0b999ad65"
export const QUEUE_FINISHED_KEY_EVENT = "0x16c4dd771da9a5cb32846fbb15c1b614da08fb5267af2fcce902a4c416e76cf"
export const PROCESS_QUEUE_SYSTEM_IN_HEX = "0x70726f636573735f71756575655f73797374656d"
export const RPC_URL = getEnv("RPC_URL", "http://0.0.0.0:5050")

export const MASTER_ACCOUNT_ADDRESS="0x517ececd29116499f4a1b64b094da79ba08dfd54a3edaa316134c41f8160973"
export const MASTER_PRIVATE_KEY="0x1800000000300000180000000000030000000000003006001800006600"

export const provider = new Provider({
  rpc: {
    nodeUrl: RPC_URL
  }
})
