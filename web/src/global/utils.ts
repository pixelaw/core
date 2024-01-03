import { shortString } from 'starknet'

/*
* @notice converts a number to hexadecimal
* @param n is the decimal number to convert to hexadecimal
* */
export const convertToHexadecimal = (n: number) => n.toString(16)
export const prefixString = (prefix: string, base: string) => `${prefix}${base}`
export const convertToHexadecimalAndLeadWithOx = (n: number) => prefixString('0x', convertToHexadecimal(n))
export const convertToDecimal = (hexadecimalString: string) => {
  const n = hexadecimalString.replace("0x", "")
  return parseInt(n, 16);
}

// Function to convert a ReadableStream to a string
export async function streamToString(readableStream: ReadableStream) {
  const textDecoder = new TextDecoder();
  const reader = readableStream.getReader();
  let result = '';

  try {
    // eslint-disable-next-line no-constant-condition
    while (true) {
      const { done, value } = await reader.read();

      if (done) {
        break; // The stream has ended
      }

      result += textDecoder.decode(value);
    }

    return result;
  } finally {
    reader.releaseLock();
  }
}

export const felt252ToString = (felt252: string | number | bigint) => {
  if (typeof felt252 === 'bigint' || typeof felt252 === 'object') {
    felt252 = `0x${felt252.toString(16)}`
  }
  if (felt252 === '0x0' || felt252 === '0') return ''
  if (typeof felt252 === 'string') {
    try {
      return shortString.decodeShortString(felt252)
    } catch (e) {
      return felt252
    }
  }
  return felt252.toString()
}

export const felt252ToUnicode = (felt252: string | number) => {
  const string = felt252ToString(felt252)
  if (string.includes('U+')) {
    const text = string.replace('U+', '')
    const codePoint = parseInt(text, 16)
    return String.fromCodePoint(codePoint)
  }
  return string
}

export const formatAddress = (address: string) => {
  if (address.length > 30) {
    return address.substr(0, 6) + '...' + address.substr(address.length - 4, address.length)
  }

  return address
}

export const getUrlParam = <T extends string | number>(param: string, defaultVal: T): T => {
  const urlParams = new URLSearchParams(window.location.search);
  const paramValue = urlParams.get(param);

  if (!paramValue) return defaultVal

  if (typeof defaultVal === 'number') {
    const numParamValue = parseInt(paramValue)
    return isNaN(numParamValue) ? defaultVal : numParamValue as T
  }

  return paramValue as T
}

export const argbToHex = (argb: number) => {
  const hexCode = convertToHexadecimalAndLeadWithOx(argb)
  return hexCode.replace("0xff", "#")
}

export const removeNullsFromArray = <T>(array: (T | null)[]) => {
  return array.filter(element => element !== null) as T[]
}
