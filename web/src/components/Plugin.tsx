import React from 'react'
import { cn } from '@/lib/utils'
import Image from '@/components/ui/Image'
import { Button } from '@/components/ui/button'
import Footer from '@/components/Footer'
import { gameModeAtom, positionWithAddressAndTypeAtom } from '@/global/states'
import { useAtom, useAtomValue } from 'jotai'
import { useApps } from '@/hooks/entities/useApps'
import { useComponentValue, useEntityQuery } from '@dojoengine/react'
import { Has } from '@latticexyz/recs'
import { useDojo } from '@/DojoContext'
import { felt252ToString, felt252ToUnicode } from '@/global/utils'
import { getEntityIdFromKeys } from '@dojoengine/utils'
import { shortString } from 'starknet'

const Apps: React.FC = () => {
  useApps()
  return <></>
}

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
      components: {
        App
      }
    },
  } = useDojo()

  const entityId = getEntityIdFromKeys([BigInt(system)])
  const app = useComponentValue(App, entityId)
  const name = felt252ToString(app?.name ?? 'app name')
  const icon = felt252ToUnicode(app?.icon ?? 'app icon')
  const isOpen = expanded === true

  return (
    <div
      className={cn(['flex justify-center items-center w-full ', {'gap-x-xs justify-start': isOpen}])}
      onClick={() => {
        if (onSelect) onSelect(name)
      }}
    >
      <Button
        variant={'icon'}
        size={'icon'}
        className={cn([
          'font-emoji',
          'my-xs',
          'text-center text-[36px]',
          'w-[1.25em]',
          'border border-brand-violetAccent rounded',
          {'border-white': selected}
        ])}
      >
        {icon}

      </Button>

      <h3 className={cn(
        ['text-brand-skyblue text-left text-base uppercase font-silkscreen',
          {'hidden': !isOpen},
          {'text-white': selected}
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
      components: {
        App, AppName
      }
    },
  } = useDojo()
    const [isOpen, setIsOpen] = React.useState<boolean>(false)

  const [gameMode, setGameMode] = useAtom(gameModeAtom)
  const selectedAppId = getEntityIdFromKeys([BigInt(shortString.encodeShortString(gameMode))])
  const selectedApp = useComponentValue(AppName, selectedAppId)

  const positionWithAddressAndType = useAtomValue(positionWithAddressAndTypeAtom)

  const apps = useEntityQuery([Has(App)])

    return (
        <>
            <div
                className={cn([
                    'fixed bottom-0 right-0 z-20',
                    'h-[calc(100vh-var(--header-height))]',
                    'bg-[#3E0C57] border-l-[1px] border-black',
                    {'animate-slide-left': isOpen},
                    {'animate-slide-right': !isOpen},
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
                            'h-[190px] w-full',
                            'flex items-start justify-center',
                            'pt-xs',
                            'border-b-[1px] border-brand-violetAccent',
                            {'justify-start border-none': isOpen}
                        ])}
                    >
                        <Button
                            className={cn([{'mx-xs': isOpen}])}
                            variant={'icon'}
                            size={'icon'}
                            onClick={() => setIsOpen(!isOpen)}
                        >
                            <Image
                                className={cn(['w-[14px]'])}
                                src={`/assets/svg/icon_chevron_${isOpen ? 'right' : 'left'}.svg`}
                                alt={'Arrow left Icon'}
                            />
                        </Button>
                    </div>

                    <div
                        className={cn([
                            'flex-1 ',
                            {'mx-xs': isOpen}
                        ])}
                    >
                        {
                            apps
                              .map((app) => {
                                return (
                                    <PluginButton
                                      key={app}
                                      system={app as unknown as string}
                                      selected={(app as unknown as string) === selectedApp?.system}
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
          <Apps />
        </>
    )
}
