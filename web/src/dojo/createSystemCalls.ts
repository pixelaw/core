import { SetupNetworkResult } from './setupNetwork'
import { Account, num } from 'starknet'
import { getEntityIdFromKeys, getEvents, setComponentsFromEvents } from '@dojoengine/utils'
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import { EntityIndex } from '@latticexyz/recs'
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import { uuid } from '@latticexyz/utils'
import { ClientComponents } from '@/dojo/createClientComponents'
import { ZERO_ADDRESS } from '@/global/constants'

export function createSystemCalls(
    { execute, contractComponents }: SetupNetworkResult,
    { Pixel }: ClientComponents
) {

  const interact = async (
    signer: Account,
    contractName: string,
    position: { x: number, y: number },
    color: number,
    action = 'interact',
    otherParams?: num.BigNumberish[]
  ) => {

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
