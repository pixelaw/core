// based on dojo execute command
import { Account, num } from 'starknet'
import { queue } from '../QueueBot/queue'
const execute = async (account: Account, system: string, selector: string, calldata: num.BigNumberish[]) => {
  try {
    const nonce = await account?.getNonce()
    const { transaction_hash } = await account?.execute(
      {
        contractAddress: system,
        entrypoint: selector,
        calldata
      },
      undefined,
      {
        nonce: nonce,
        maxFee: 0 // TODO: Update
      }
    );
    account.waitForTransaction(transaction_hash)
      .then( result => console.log({ result }))
      .catch(error => {
        console.error('could not execute:', error)
        delete queue[calldata[0].toString()]
      })
  } catch (error) {
    console.error('could not execute:', error)
  }
}

export default execute
