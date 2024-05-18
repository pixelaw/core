// based on dojo execute command
import { Account, AllowArray, Call, num } from 'starknet'

let nonce = -1
const execute = async (account: Account, calls: AllowArray<Call>) => {
  try {
    if (nonce === -1) {
      nonce = Number(BigInt(await account?.getNonce()))
    }


    // TODO this fails?
    const {suggestedMaxFee: estimatedFee1} = await account.estimateInvokeFee(
      calls
    );

    const {transaction_hash} = await account?.execute(
      calls,
      undefined,
      {
        nonce: nonce++,
        maxFee: 0 // TODO: Update
      }
    );

    // const result = await account.waitForTransaction(transaction_hash);

  } catch (error) {
    console.error('could not execute:', error)
    throw error;
  }
}

export default execute
