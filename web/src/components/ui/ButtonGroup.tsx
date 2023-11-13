import { Key } from 'react'
import { Button } from '@/components/ui/button'

type PropsType<T> = {
  id?: string
  value?: T,
  options: {label: string, value: T}[],
  onChange?: (newValue: T) => void
}

const ButtonGroup = <T extends Key | null | undefined>({ value, options, onChange, id }: PropsType<T>) => {
  return (
    <div className={'flex gap-2'} id={id}>
      {options.map(option => (
        <Button
          className={'flex-1'}
          size={'sm'}
          key={option.value}
          variant={value === option.value ? 'destructive' : 'secondary'}
          onClick={() => {
            if (onChange) onChange(option.value)}}
        >
          {option.label}
        </Button>
      ))}
    </div>
  )
}

export default ButtonGroup
