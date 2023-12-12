import { Key } from 'react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils.ts'

type PropsType<T> = {
  id?: string
  value?: T,
  options: {label: string, value: T}[],
  onChange?: (newValue: T) => void
}

const ButtonGroup = <T extends Key | null | undefined>({ value, options, onChange, id }: PropsType<T>) => {
  return (
    <div className={'flex gap-[20px]'} id={id}>
      {options.map(option => (
        <Button
          className={cn([
            'flex-1 h-[44px]',
            'bg-[#390754] rounded-[8px]',
            'border border-[#7C0BB4]',
            'text-[#19C0DB] uppercase text-[18px] font-silkscreen'
          ])}
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
