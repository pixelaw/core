import { Account, Event, num, TransactionStatus } from 'starknet'
import { getEvents, hexToAscii, setComponentsFromEvents } from '@dojoengine/utils'
import { ZERO_ADDRESS } from '@/global/constants'
import { IWorld } from '@/dojo/generated'
import { ContractComponents } from '@/dojo/contractComponents'

const FAILURE_REASON_REGEX = /Failure reason: ".+"/;

export type SystemCalls = ReturnType<typeof createSystemCalls>;

export function createSystemCalls(
  { client }: { client: IWorld },
  contractComponents: ContractComponents,
) {

  /**
   * @notice calls an action in a specific pixel
   * @dev the only value being optimistically rendered is color
   * @param signer is the account that's calling an action
   * @param contractName is the name of the contract that owns the action being called
   * @param position is where the pixel is located
   * @param color is expressed in argb
   * @param action is the function being called (defaults to interact)
   * @param otherParams are other param meters that follow the defaultParams
   * */
  const interact = async (
    signer: Account,
    contractName: string,
    position: { x: number, y: number },
    color: number,
    action = 'interact',
    otherParams?: num.BigNumberish[]
  ) => {
    try {

      const tx = await client.actions.interact({
        account: signer,
        contract_name: contractName,
        call: action,
        calldata: [
          ZERO_ADDRESS,
        ZERO_ADDRESS,
        position.x,
        position.y,
        color,
        ...(otherParams ?? [])
    ]
    });

      const receipt = await signer.waitForTransaction(tx.transaction_hash, { retryInterval: 100})

      if ('execution_status' in receipt && receipt.execution_status === TransactionStatus.REVERTED) {
        if ('revert_reason' in receipt && !!receipt.revert_reason) {
          throw receipt.revert_reason.match(FAILURE_REASON_REGEX)?.[0] ?? receipt.revert_reason
        }
        else throw new Error('transaction reverted')
      }

      if (receipt.status === TransactionStatus.REJECTED) {
        if ('transaction_failure_reason' in receipt) throw  receipt.transaction_failure_reason.error_message
        else throw new Error('transaction rejected')
      }

      // these events could contain custom components not just core components so filtering out non-core components
      const events: Event[] = getEvents(receipt)
      const filteredEvents = events.filter(event => {
        const componentName = hexToAscii(event.data?.[0] ?? '0x0')
        const component = contractComponents[componentName as keyof typeof contractComponents]
        return !!component
      })

      setComponentsFromEvents(contractComponents, filteredEvents)

    } catch (e) {
      console.error(e)
      throw e
    }
  }

  return {
    interact
  }
}
