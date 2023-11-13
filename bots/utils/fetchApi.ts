import streamToString from './streamToString'
import getEnv from './getEnv'

const API_URL = getEnv("API_URL", "http://0.0.0.0:3000")

async function fetchApi<T>(endpoint: string, returnType: 'json' | 'string' | 'number') {
  const result = await fetch(`${API_URL}/api/${endpoint}`)
  const stream = result.body
  if (!stream) throw new Error("Stream not found")
  const processedStream = await streamToString(stream)
  let returnValue: T;

  if (returnType === 'json') {
    returnValue = JSON.parse(processedStream) as T;
  } else if (returnType === 'string') {
    returnValue = processedStream as unknown as T;
  } else if (returnType === 'number') {
    returnValue = parseInt(processedStream) as unknown as T;
  }

  return returnValue;
}

export default fetchApi
