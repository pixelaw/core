import { Provider } from 'starknet'
import { RPC_URL } from './constants'

export const getProvider = () => {
  return new Provider({
    rpc: {
      nodeUrl: RPC_URL
    }
  })
}

