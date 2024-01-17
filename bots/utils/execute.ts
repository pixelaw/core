// based on dojo execute command
import { Account, num, TransactionStatus } from 'starknet'
import { queue } from '../QueueBot/queue'

const FAILURE_REASON_REGEX = /Failure reason: ".+"/;
const execute = async (account: Account, system: string, selector: string, calldata: num.BigNumberish[]) => {
  try {
    const nonce = await account?.getNonce()
    const tx =  await account?.execute(
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
    const receipt = await account.waitForTransaction(tx.transaction_hash, { retryInterval: 100 })

    // if the transaction was reverted, remove from queue
    if ('execution_status' in receipt && receipt.execution_status === TransactionStatus.REVERTED) {
      if ('revert_reason' in receipt && !!receipt.revert_reason) {
        delete queue[calldata[0] as string]
        throw receipt.revert_reason.match(FAILURE_REASON_REGEX)?.[0] ?? receipt.revert_reason
      }
      else throw new Error('transaction reverted')
    }

    if (receipt.status === TransactionStatus.REJECTED) {
      if ('transaction_failure_reason' in receipt) throw  receipt.transaction_failure_reason.error_message
      else throw new Error('transaction rejected')
    }
  } catch (error) {
    console.error('could not execute:', error)
    throw error;
  }
}

export default execute
