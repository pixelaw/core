import { SetupNetworkResult } from './setupNetwork'
import { Account, num } from 'starknet'
import { getEntityIdFromKeys, getEvents, setComponentsFromEvents } from '@dojoengine/utils'
import { EntityIndex } from '@latticexyz/recs'
import { uuid } from '@latticexyz/utils'
import { ClientComponents } from '@/dojo/createClientComponents'
import { ZERO_ADDRESS } from '@/global/constants'

export function createSystemCalls(
    { execute, contractComponents }: SetupNetworkResult,
    { Pixel }: ClientComponents
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

    // for optimistic rendering
    const entityId = getEntityIdFromKeys([BigInt(position.x), BigInt(position.y)]) as EntityIndex
    const pixelId = uuid()
    Pixel.addOverride(pixelId, {
      entity: entityId,
      value: {
        color
      }
    })

    try {
      const tx = await execute(
        signer,
        contractName,
        action,
        [
          ZERO_ADDRESS,
          ZERO_ADDRESS,
          position.x,
          position.y,
          color,
          ...(otherParams ?? [])
        ]
      );

      const receipt = await signer.waitForTransaction(tx.transaction_hash, { retryInterval: 100})
      setComponentsFromEvents(contractComponents, getEvents(receipt))
    } catch (e) {
      console.error(e)
      Pixel.removeOverride(pixelId)
    } finally {
      Pixel.removeOverride(pixelId)
    }
  }

  return {
    interact
  }
}
