import React from 'react'
import { Dialog, DialogContent, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import ButtonGroup from '@/components/ui/ButtonGroup'

type ParamDefinition = {
  name: string,
  type: 'number' | 'string' | 'enum',
  variants?: {name: string, value: number}[],
  structDefinition?: Record<string, any>
}

type PropsType = {
  value: Record<string, any>,
  setAdditionalParams: (newValue: Record<string, any>) => void,
  onChange: (newValue: Record<string, any>) => void,
  params: ParamDefinition[],
  onSubmit?: () => void,
  open?: boolean,
  onOpenChange?: (open: boolean) => void
}

type EnumPickerPropsType = {
  value?: number,
  label: string
  variants: {name: string, value: number}[],
  onChange?: (value: number) => void
}

const EnumPicker: React.FC<EnumPickerPropsType> = ( { label, value, variants, onChange }) => {
  const id = `enum-group-${label}`
  return (
    <>
      <Label htmlFor={id} className={'capitalize'}>{label}</Label>
      <ButtonGroup
        id={id}
        options={variants.map(variant => { return { label: variant.name, value: variant.value }})}
        value={value}
        onChange={(newValue) => {
          if (onChange) onChange(newValue ?? 0)
        }}
      />
    </>
  )
}

const ParamPicker: React.FC<PropsType> = ({ value, setAdditionalParams, onChange, params, onSubmit, open, onOpenChange }) => {
  const hasOnSubmit = !!onSubmit
  let needConfirm = false;
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className={'p-md'}>
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
                    onChange={(e) => onChange({...value, [param.name]: e})}
                  />
                );
              case 'number':
                needConfirm = true;
                return (
                    <Input
                      key={`${param.name}-input`}
                      type={'number'}
                      placeholder={param.name}
                      value={value[param.name]}
                      className='mb-3'
                      onChange={(e) => setAdditionalParams({...value, [param.name]: Number(e.target.value)})}
                    />
                );
              case 'string':
                needConfirm = true;
                return (
                    <Input
                      key={`${param.name}-input`}
                      type={'text'}
                      placeholder={param.name}
                      value={value[param.name]}
                      className='mr-2'
                      onChange={(e) => setAdditionalParams({...value, [param.name]: Number(e.target.value)})}
                    />
                );
              default:
                return null;
            }
          })}
        {needConfirm && <Button 
          className={"w-[50%]"} onClick={() => onChange(value)}>
          Confirm
        </Button>}
        </div>
        {hasOnSubmit && (
          <DialogFooter>
            <Button size={"sm"} onClick={onSubmit}>confirm</Button>
          </DialogFooter>
        )}

      </DialogContent>

    </Dialog>
  );
}

export default ParamPicker;
