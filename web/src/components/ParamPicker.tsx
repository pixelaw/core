import React from 'react'
import { Dialog, DialogContent, DialogFooter, DialogOverlay } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import ButtonGroup from '@/components/ui/ButtonGroup'
import { cn } from '@/lib/utils.ts'

type ParamDefinition = {
  name: string,
  type: 'number' | 'string' | 'enum',
  variants?: { name: string, value: number }[],
  structDefinition?: Record<string, any>
}

type PropsType = {
  value: Record<string, any>,
  onChange?: (newValue: Record<string, any>) => void,

  // for when the param is only one enum
  onSelect?: (newValue: Record<string, any>) => void,
  params: ParamDefinition[],
  onSubmit?: () => void,
  open?: boolean,
  onOpenChange?: (open: boolean) => void,
  instruction?: string
}

type EnumPickerPropsType = {
  value?: number,
  label: string
  variants: { name: string, value: number }[],
  onChange?: (value: number) => void
}

const EnumPicker: React.FC<EnumPickerPropsType> = ({ label, value, variants, onChange }) => {
  const id = `enum-group-${label}`
  return (
    <div className={'justify-center flex flex-col gap-xs'}>
      <Label
        htmlFor={id}
        className={cn([
          'text-center text-white',
          'capitalize',
        ])}
      >
        {label}
      </Label>

      <ButtonGroup
        id={id}
        options={variants.map(variant => {
          return { label: variant.name, value: variant.value }
        })}
        value={value}
        onChange={(newValue) => {
          if (onChange) onChange(newValue ?? 0)
        }}
      />
    </div>
  )
}

const ParamPicker: React.FC<PropsType> = ({
  instruction,
  value,
  onChange,
  onSelect,
  params,
  onSubmit,
  open,
  onOpenChange,
}) => {
  const needsSubmitButton = params.length > 1 || !!(params.filter(param => param.type === 'number' || param.type === 'string')).length
  const handleOnChange = (newValue: any, paramName: string) => {
    const finalizedValue = { ...value, [paramName]: newValue }

    // means there is only one param and that param is an enum
    if (!needsSubmitButton && !!onSelect) {
      onSelect(finalizedValue)
      return
    }

    if (onChange) onChange(finalizedValue)
  }

  const hasInstruction = !!instruction

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogOverlay className={cn(['bg-[#0F0414] opacity-5'])} />
      <DialogContent
        className={cn([
          'bg-[#220630] p-sm',
          'border-[#220630] rounded-[16px]'
        ])}
      >
        {hasInstruction && (
          <h2
            className={cn([ 'text-[#FFC400] text-center text-base uppercase text-[32px] font-silkscreen' ])}>{instruction}</h2>
        )}
        <div>
          {params.map((param) => {

            switch (param.type) {
              case 'enum':
                return (
                  <EnumPicker
                    key={param.name}
                    value={value[param.name]}
                    label={param.name}
                    variants={param.variants ?? []}
                    onChange={(e) => handleOnChange(e, param.name)}
                  />
                )
              case 'number':
                return (
                  <Input
                    key={`${param.name}-input`}
                    type={'number'}
                    placeholder={param.name}
                    value={value[param.name] ?? ''}
                    className="mb-3"
                    onChange={(e) => handleOnChange(e.target.valueAsNumber, param.name)}
                  />
                )
              case 'string':
                return (
                  <Input
                    key={`${param.name}-input`}
                    type={'text'}
                    placeholder={param.name}
                    value={value[param.name] ?? ''}
                    className="mr-2"
                    onChange={(e) => handleOnChange(e.target.value, param.name)}
                  />
                )
              default:
                return null
            }
          })}
        </div>
        {needsSubmitButton && (
          <DialogFooter>
            <Button size={'sm'} onClick={onSubmit}>confirm</Button>
          </DialogFooter>
        )}

      </DialogContent>

    </Dialog>
  )
}

export default ParamPicker
