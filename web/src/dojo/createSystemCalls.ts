import { SetupNetworkResult } from './setupNetwork'
import { Account, num, Event } from 'starknet'
import { getEntityIdFromKeys, getEvents, hexToAscii, setComponentsFromEvents } from '@dojoengine/utils'
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

      // these events could contain custom components not just core components so filtering out non-core components
      const events: Event[] = getEvents(receipt)
      const filteredEvents = events.filter(event => {
        const componentName = hexToAscii(event.data?.[0] ?? '0x0')
        const component = contractComponents[componentName as keyof typeof contractComponents]
        return !!component
      })

      setComponentsFromEvents(contractComponents, filteredEvents)

    } catch (e) {
      Pixel.removeOverride(pixelId)
      console.error(e)
      throw new Error(e?.toString() ?? 'interaction failed')
    } finally {
      Pixel.removeOverride(pixelId)
    }
  }

  return {
    interact
  }
}
