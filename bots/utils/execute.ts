// based on dojo execute command
import { Account, num } from 'starknet'
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
    const result = await account.waitForTransaction(transaction_hash);
    console.log({result});
  } catch (error) {
    console.error('could not execute:', error)
    throw error;
  }
}

export default execute
