import { useDojo } from '@/DojoContext'
import { useMutation } from '@tanstack/react-query'
import { convertToDecimal, felt252ToString } from '@/global/utils'
import { EntityIndex, getComponentValue } from '@latticexyz/recs'
import { getEntityIdFromKeys } from '@dojoengine/utils'
import manifest from './../../dojo/manifest.json'
import { num } from 'starknet'
import interpret, { isInstruction, ParamDefinitionType } from '@/lib/Instruction'

const DEFAULT_PARAMETERS_TYPE = 'pixelaw::core::utils::DefaultParameters'

const convertSnakeToPascal = (snakeCaseString: string) => {
  return snakeCaseString.split('_').map(function(word) {
    return word.charAt(0).toUpperCase() + word.slice(1);
  }).join('')
}

/// @dev this does not handle struct params yet...will support this on a later iteration
const useInteract = (
  contractName: string,
  color: string,
  position: {x: number, y: number}
) => {

  const {
    setup: {
      systemCalls: {interact},
      components: {Pixel}
    },
    account: { account }
  } = useDojo()

  const solidColor = color.replace('#', '0xFF')
  const decimalColor = convertToDecimal(solidColor)

  const entityId = getEntityIdFromKeys([BigInt(position.x), BigInt(position.y)]) as EntityIndex
  const pixelValue = getComponentValue(Pixel, entityId)

  const action = (!pixelValue?.action || pixelValue?.action.toString() === '0x0') ? 'interact' : pixelValue.action
  const methodName = felt252ToString(action)

  const contract = manifest.contracts.find(contract => contract.name === contractName)
  if (!contract) throw new Error(`unknown contract: ${contractName}`)
  const interfaceName = `I${convertSnakeToPascal(contractName)}`
  const methods = contract.abi.find(x => x.type === 'interface' && x.name.includes(interfaceName))
  if (!methods) throw new Error(`unknown interface: ${interfaceName}`)
  if (!methods?.items) throw new Error(`no methods for interface: ${interfaceName}`)

  let functionDef = methods.items.find(method => method.name === methodName && method.type === 'function')
  if (!functionDef) {
    functionDef = methods.items.find(method => method.name === 'interact' && method.type === 'function')
    if (!functionDef) throw new Error(`function ${methodName} not found`)
  }
  const parameters = functionDef.inputs.filter(input => input.type !== DEFAULT_PARAMETERS_TYPE)

  const paramsDef: ParamDefinitionType[] = parameters.map(param => {
    if (isInstruction(param.name)) {
      // problem with types on contract.abi
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      return interpret(contractName, position, param.name, contract.abi)
    }
    const isPrimitiveType = param.type.includes("core::integer") || param.type.includes("core::felt252")
    let type: 'number' | 'string' | 'enum' = 'number'
    let variants: {name: string, value: number}[] = []
    if (!isPrimitiveType) {
        const typeDefinition = contract.abi.find(x => x.name === param.type)
        if (typeDefinition?.type === "enum") {
          variants = (typeDefinition?.variants ?? [])
            .map((variant, index) => {
              return {
                name: variant.name,
                value: index
              }
            })
            .filter(variant => variant.name !== 'None')
          type = 'enum'
        }
    } else if (param.type.includes("core::felt252")) {
      type = 'string'
    }
    return {
      name: param.name,
      type,

      // if is not primitive type fill these out
      variants,

      // for interpret instruction only
      transformValue: undefined,
      value: undefined,

    }
  })

  const fillableParamDefs = paramsDef.filter(paramDef => paramDef?.value == null)

  return {
    interact: useMutation({
      mutationKey: ['useInteract', contractName, color],
      mutationFn: async ({otherParams}: {
        otherParams?: Record<string, any>
      }) => {
        if (!otherParams && fillableParamDefs.length > 0) throw new Error('incomplete parameters')
        else if (!otherParams && !paramsDef.length) {
          return interact(account, contractName, position, decimalColor, methodName)
        }

        const additionalParams: num.BigNumberish[] = []

        for (const paramDef of paramsDef) {
          if (paramDef.value) {
            additionalParams.push(paramDef.value)
          } else {
            if(!otherParams) continue
            let param = otherParams[paramDef.name]
            if (!param && paramDef.variants.length) {
              param = paramDef.variants[0].value
            }
            if (
              (paramDef.type === 'string' && typeof param !== 'string') ||
              (paramDef.type === 'number' && typeof param !== 'number')
            ) throw new Error(`incorrect parameter for ${paramDef.name}. supplied is ${param}`)

            // TODO handle structs
            if (paramDef.transformValue) {
              additionalParams.push(paramDef.transformValue(param))
            }
            else additionalParams.push(param)
          }
        }

        interact(account, contractName, position, decimalColor, methodName, additionalParams)
      }
    }),
    params: fillableParamDefs
  }
}

export default useInteract
