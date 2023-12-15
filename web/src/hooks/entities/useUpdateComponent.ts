import { useDojo } from '@/DojoContext'
import { getComponentValue, setComponent } from '@latticexyz/recs'
import { getEntityIdFromKeys } from '@dojoengine/utils'
import useSubscribe from '@/hooks/utils/useSubscribe'
import _ from 'lodash'
import { InvalidateQueryFilters, useQueryClient } from '@tanstack/react-query'

const QUERY = `
subscription entities {
  entityUpdated {
    id
    keys
    eventId
    createdAt
    updatedAt
    models {
      ... on App {
        system
        name
        manifest
        icon
        action
        __typename
      }
      ... on AppName {
        name
        system
        __typename
      }
      ... on AppUser {
        system
        player
        action
        __typename

      }
      ... on Instruction {
        system
        selector
        instruction
        __typename

      }
      ... on Pixel {
        x
        y
        created_at
        updated_at
        app
        color
        owner
        text
        timestamp
        action
        __typename
      }
    }
  }
}
`

type AppEntity = {
  system: string,
  name: string,
  manifest: string,
  icon: string,
  action: string,
  __typename: 'App'
}

type AppNameEntity = {
  name: string,
  system: string,
  __typename: 'AppName'
}

type AppUserEntity = {
  system: string,
  player: string,
  action: string,
  __typename: 'AppUser'
}

type InstructionEntity = {
  system: string,
  selector: string,
  instruction: string,
  __typename: 'Instruction'
}

type PixelEntity = {
  x: number,
  y: number,
  created_at: number,
  updated_at: number,
  app: string,
  color: number,
  owner: string,
  text: string,
  timestamp: number,
  action: string,
  __typename: 'Pixel'
}

type EntityUpdatedMessage = {
  data: {
    entityUpdated: {
      id: string,
      keys: string[],
      eventId: string,
      createdAt: string,
      updatedAt: string,
      models: (AppEntity| AppNameEntity | AppUserEntity | InstructionEntity | PixelEntity)[]
    },
  }
}

const useUpdateComponent = () => {
  const queryClient = useQueryClient();
  const {
    setup: {
      components,
    }
  } = useDojo()

  const onAlert = ({data: { entityUpdated: { keys, models } }}: EntityUpdatedMessage) => {
    const entityId = getEntityIdFromKeys(keys.map(key => BigInt(key)))

    models.forEach(model => {
      if (!_.has(model, '__typename')) return
      const component = components[model.__typename as keyof typeof components]
      const oldValue = getComponentValue(component, entityId)
      const newValue = _.omit(model,  '__typename')

      if(!_.isEqual(oldValue, newValue)) {
        setComponent(component, entityId, newValue)
        let filters: InvalidateQueryFilters = {}
        switch (model.__typename) {
          case 'App':
          case 'AppName':
            filters = { queryKey: ['apps'] }
            break
          case 'AppUser':
            // did not query this at all yet
            break
          case 'Instruction':
            filters = { queryKey: ['instructions'] }
            break
          case 'Pixel': {
            const pixel: Pick<PixelEntity, 'x'> & Pick<PixelEntity, 'y'> = newValue as unknown as Pick<PixelEntity, 'x'> & Pick<PixelEntity, 'y'>
            filters = {
              predicate: (query) => {
                const [ key, xMin, xMax, yMin, yMax ] = query.queryKey
                if (key !== 'filtered-entities') return false
                return (xMin as number) <= pixel.x && (xMax as number) >= pixel.x && (yMin as number) <= pixel.y && (yMax as number) >= pixel.y
              }
            }
            break
          }
        }
        queryClient.invalidateQueries(filters).then()
      }

    })
  }

  useSubscribe<EntityUpdatedMessage>(QUERY, onAlert)
}

export default useUpdateComponent
