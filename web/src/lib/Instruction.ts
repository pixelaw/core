import { poseidonHashMany } from 'micro-starknet'

type ImplType = {
  type: 'impl',
  name: string,
  interface_name: string
}

type BaseType = {
  name: string,
  type: string
}

type FunctionType = {
  type: 'function',
  name: string,
  inputs: BaseType[],
  outputs: {type: string}[],
  state_mutability: 'external' | 'view'
}

type InterfaceType = {
  type: 'interface',
  name: string,
  items: FunctionType[]
}

type StructType = {
  type: 'struct',
  name: string,
  members: BaseType[]
}

type EnumType = {
  type: 'enum',
  name: string,
  variants: BaseType[]
}

type EventMember = {
  name: string,
  type: string,
  kind: string
}

type EventStructType = {
  type: 'event',
  name: string,
  kind: 'struct',
  members: EventMember[]
}

type EventEnumType = {
  type: 'event',
  name: string,
  kind: 'enum',
  variants: EventMember[]
}

type AbiType = (ImplType | InterfaceType | StructType | EnumType | FunctionType | EventStructType | EventEnumType)[]

// TODO: change SALT to a dynamic constant
const SALT = 12345

const PREFIX = 'pixelaw'

const setStorage = (appName: string, paramName: string, position: { x: number, y: number }, value: Record<string, number>) => {
  const storageKey = `${PREFIX}::${appName}::${position.x}::${position.y}::${paramName}`
  localStorage.setItem(storageKey, JSON.stringify(value))
}

const getStorage = (appName: string, paramName: string, position: { x: number, y: number }, key: string) => {
  const storageKey = `${PREFIX}::${appName}::${position.x}::${position.y}::${paramName}`
  const storageItem = localStorage.getItem(storageKey)
  if (!storageItem) return null

  const parsedItem = JSON.parse(storageItem)
  return parsedItem[key] as number
}

const isPrimitive = (type: string) => {
  return type === 'u8' ||
    type === 'u16' ||
    type === 'u32' ||
    type === 'u64' ||
    type === 'u128' ||
    type === 'u256' ||
    type === 'usize' ||
    type === 'bool' ||
    type === 'felt252'
}

export const isInstruction = (paramName: string) => {
  const [instruction, ...otherValues] = paramName.split("_")
  switch (instruction) {
    case 'cr': return otherValues.length === 2
    case 'rv':
    case 'rs':
      return otherValues.length === 1
    default: return false
  }
}

export type Variant = {
  name: string,
  value: number,
}

export type ParamDefinitionType = {
  name: string,
  type: 'string' | 'number' | 'enum',
  variants: Variant[],
  transformValue?: (value: number) => bigint,
  value?: number | null
}

type InterpretType = (appName: string, position: {x: number, y: number}, typeInstruction: string, abi: AbiType) => ParamDefinitionType

const interpret: InterpretType = (appName: string, position: {x: number, y: number}, typeInstruction: string, abi: AbiType) => {
  const [instruction, ...otherValues] = typeInstruction.split("_")
  switch (instruction) {
    case 'cr': {
      let finalizedType: 'number' | 'string' | 'enum' = 'number'
      const [type, name] = otherValues
      let variants: {name: string, value: number}[] = []
      if (!isPrimitive(type)) {
        // for now assuming that all nonPrimitives are enums
        const typeDefinition: EnumType | undefined = abi.find(
          typeDef => typeDef.name.includes(type) && typeDef.type === 'enum'
        ) as unknown as EnumType | undefined
        if (!typeDefinition) throw new Error(`unknown type definition: ${type}`)
        variants = typeDefinition.variants
          .map((variant, index) => {
            return {
              name: variant.name,
              value: index
            }
          })
          .filter(variant => variant.name !== 'None')
        finalizedType = 'enum'
      } else if (type === 'felt252') finalizedType = 'string'
      return {
        value: undefined,
        name,
        transformValue: (value: number) => {
          setStorage(appName, name, position, { value, salt: SALT })
          return poseidonHashMany([BigInt(value), BigInt(SALT)])
        },
        variants,
        type: finalizedType
      }
    }
    case 'rv': {
      const [name] = otherValues
      return {
        transformValue: undefined,
        name,
        variants: [],
        type: 'number',
        value: getStorage(appName, name, position, 'value') ?? 0
      }
    }
    case 'rs': {
      const [name] = otherValues
      return {
        transformValue: undefined,
        name,
        variants: [],
        type: 'number',
        value: getStorage(appName, name, position, 'salt') ?? 0
      }
    }
    default: throw new Error(`unknown instruction: ${typeInstruction}`)
  }
}

export default interpret
