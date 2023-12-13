import { cn } from '@/lib/utils'
import React from 'react'

type PropsType = {
  children?: string
}
const Loading: React.FC<PropsType> = ({ children }) => {
  const loadingMessage = children ?? 'Loading...'
  return(
    <div
      className={cn(
        [
          'flex-1',
          'bg-brand-body'
        ]
      )}
    >
      <div className={'fixed top-0 bottom-0 left-0 w-full bg-brand-body z-40 flex-center'}>
        <div
          className={'w-16 h-16 border-t-2 border-brand-violetAccent border-solid rounded-full animate-spin'}/>
        <h2 className={'text-lg uppercase font-silkscreen text-brand-violetAccent ml-xs'}>{ loadingMessage }</h2>
      </div>
    </div>
  )
}

export default Loading
