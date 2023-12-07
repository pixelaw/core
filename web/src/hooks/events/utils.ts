import { convertToDecimal, felt252ToString } from '@/global/utils'

/**
 * @notice transforms eventData comprised of an array of strings to an event object
 * @param id is the eventId
 * @param eventData is an ordered array of strings outlined in cairo
* */
export const parseEventData = (id: string, eventData: string[]) => {
  if (eventData.length !== 6) throw new Error('Incorrect Event Data')
  const [
    x,
    y,
    caller,
    player,
    message,
    timestamp
  ] = eventData

  return {
    id,
    position: {
      x: convertToDecimal(x),
      y: convertToDecimal(y)
    },
    caller,
    player,
    message: felt252ToString(message),
    timestamp: BigInt(timestamp)
  }
}
