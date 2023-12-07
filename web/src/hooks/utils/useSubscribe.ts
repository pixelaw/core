import { PUBLIC_TORII } from '@/global/constants'
import { createClient, ExecutionResult } from 'graphql-ws'
import React from 'react'

const client = createClient({
  url: PUBLIC_TORII.replace('http', 'ws') + '/graphql'
})

type BaseDataType = ExecutionResult<Record<string, unknown>, unknown>

/**
 * @notice react hook for subscribing to torii
 * @param query is the query string used to subscribe to data changes
 * @param onMessage is the function that takes in the value returned from a subscription
* */
const useSubscribe = <T extends BaseDataType>(
  query: string,
  onMessage: (value: T) => void
) => {
  React.useEffect(() => {
    const unsubscribe = client.subscribe(
      { query },
      {
        next: onMessage,
        error: (err) => console.error(err),
        complete: () => console.log('Subscription completed')
      }
    )
    return () => unsubscribe()
  }, [onMessage, query])
}

export default useSubscribe
