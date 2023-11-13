import React from 'react'
import { cn } from '@/lib/utils'
import Image from '@/components/ui/Image'
import { plugins } from '@/global/config'
import { Button } from '@/components/ui/button'
import Footer from '@/components/Footer'
import { gameModeAtom, positionWithAddressAndTypeAtom } from '@/global/states'
import { useAtom, useAtomValue } from 'jotai'
import { useApps } from '@/hooks/entities/useApps'
import { useEntityQuery } from '@dojoengine/react'
import { Has } from '@latticexyz/recs'
import { useDojo } from '@/DojoContext'
import { felt252ToString } from '@/global/utils'

const Apps: React.FC = () => {
  useApps()
  return <></>
}

export default function Plugin() {

  const {
    setup: {
      components: {
        AppName
      }
    },
  } = useDojo()
    const [isOpen, setIsOpen] = React.useState<boolean>(false)

  const [gameMode, setGameMode] = useAtom(gameModeAtom)
  const positionWithAddressAndType = useAtomValue(positionWithAddressAndTypeAtom)


  // TODO: ideally the icons should also come from the contracts instead of hardcoded in
  const apps = useEntityQuery([Has(AppName)])
    .map(name => felt252ToString(name))

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
                            plugins
                              .filter(plugin => apps.includes(plugin.name))
                              .map((plugin, index) => {
                              const selected = plugin.name === gameMode
                                return (
                                    <div
                                      key={index}
                                      className={cn(['flex justify-center items-center w-full ', {'gap-x-xs justify-start': isOpen}])}
                                      onClick={() => setGameMode(plugin.name as "none" | "paint" | "rps" | "snake")}
                                    >
                                        <Button
                                            key={index}
                                            variant={'icon'}
                                            size={'icon'}
                                            className={cn([
                                                'font-emoji',
                                                'my-xs',
                                                'text-center text-[36px]',
                                                'border border-brand-violetAccent rounded',
                                                {'border-white': selected}
                                            ])}
                                        >
                                            {plugin.icon}

                                        </Button>

                                        <h3 className={cn(
                                            ['text-brand-skyblue text-left text-base uppercase font-silkscreen',
                                                {'hidden': !isOpen},
                                              {'text-white': selected}
                                            ])}
                                        >
                                            {plugin.name}
                                        </h3>
                                    </div>
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
