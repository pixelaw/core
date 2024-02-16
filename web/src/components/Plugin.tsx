import React from 'react'
import { cn } from '@/lib/utils'
import Image from '@/components/ui/Image'
import { Button } from '@/components/ui/button'
import Footer from '@/components/Footer'
import { gameModeAtom, positionWithAddressAndTypeAtom } from '@/global/states'
import { useAtom, useAtomValue } from 'jotai'
import { useComponentValue, useEntityQuery } from '@dojoengine/react'
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import { Has, getComponentValue } from '@latticexyz/recs'
import { useDojo } from '@/dojo/useDojo'
import { felt252ToString, felt252ToUnicode } from '@/global/utils'
import { getEntityIdFromKeys } from '@dojoengine/utils'
import { shortString } from 'starknet'

type PluginButtonPropsType = {
  // contract address
  system: string
  onSelect?: (appName: string) => void
  expanded?: boolean,
  selected?: boolean
}

const PluginButton = ({ system, onSelect, expanded, selected }: PluginButtonPropsType) => {
  const {
    setup: {
      clientComponents: {
        App,
      },
    },
  } = useDojo()

  const app = useComponentValue(App, system)
  const name = felt252ToString(app?.name ?? 'app name')
  const icon = felt252ToUnicode(app?.icon ?? 'app icon')
  const isOpen = expanded === true

  return (
    <div
      className={cn([ 'flex justify-center items-center w-full mb-[15px]', { 'gap-xs justify-start': isOpen } ])}
      onClick={() => {
        if (onSelect) onSelect(name)
      }}
    >
      <Button
        variant={'icon'}
        className={cn([
          'h-[48px] w-[48px]  ',
          'bg-[#220630]',
          'font-emoji',
          'text-center text-[36px]',
          'border border-[#220630] rounded-[4px]',
          { 'bg-[#7C0BB4] border-[#7C0BB4]': selected },
        ])}
      >
        {icon}

      </Button>

      <h3 className={cn(
        [ 'text-brand-skyblue text-left text-base uppercase font-silkscreen',
          { 'hidden': !isOpen },
          { 'text-white': selected },
        ])}
      >
        {name}
      </h3>
    </div>
  )
}

export default function Plugin() {

  const {
    setup: {
      clientComponents: {
        App, AppName,
      },
    },
  } = useDojo()
  const [ isOpen, setIsOpen ] = React.useState<boolean>(false)

  const [ gameMode, setGameMode ] = useAtom(gameModeAtom)
  const selectedAppId = getEntityIdFromKeys([ BigInt(shortString.encodeShortString(gameMode)) ])
  const selectedApp = useComponentValue(AppName, selectedAppId)

  const positionWithAddressAndType = useAtomValue(positionWithAddressAndTypeAtom)

  const apps = useEntityQuery([ Has(App) ])

  return (
    <>
      <div
        className={cn([
          'fixed bottom-0  z-20',
          'h-[calc(100vh-var(--header-height))]',
          { 'animate-slide-left-icon right-0': isOpen },
          { 'animate-slide-right-icon right-[72px]': !isOpen },
        ])}
      >
        <Button
          className={cn([
            'bg-[#220630]',
            'w-[16px] h-[30px]',
          ])}
          variant={'icon'}
          size={'icon'}
          onClick={() => setIsOpen(!isOpen)}
        >
          <Image
            className={cn([ 'w-[11px] h-[7px]' ])}
            src={`/assets/svg/icon_chevron_${isOpen ? 'right' : 'left'}.svg`}
            alt={'Arrow left Icon'}
          />
        </Button>
      </div>

      <div
        className={cn([
          'fixed bottom-0 right-0 z-20',
          'h-[calc(100vh-var(--header-height))]',
          'bg-[#2A0D39]',
          { 'animate-slide-left': isOpen },
          { 'animate-slide-right': !isOpen },
        ])}
      >
        <div
          className={cn([
            'flex flex-col',
            'h-full',
          ])}
        >
          <div
            className={cn([
              'py-[15px] gap-[15px]',
              'flex-1 ',
              { 'mx-xs': isOpen },
            ])}
          >
            {
              apps
                .map((app) => {
                  const componentValue = getComponentValue(App, app)
                  return (
                    <PluginButton
                      key={app}
                      system={app as unknown as string}
                      selected={componentValue?.system === selectedApp?.system}
                      onSelect={(name) => setGameMode(name)}
                      expanded={isOpen}
                    />
                  )
                })
            }
          </div>

          <Footer
            coordinates={{ x: Number(positionWithAddressAndType.x), y: Number(positionWithAddressAndType.y) }}
            collapsed={isOpen} type={String(positionWithAddressAndType.pixel)}
            owner={String(positionWithAddressAndType.address)} />
        </div>
      </div>
    </>
  )
}
