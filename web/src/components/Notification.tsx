import React from 'react'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import Image from '@/components/ui/Image'
import { useComponentValue } from '@dojoengine/react'
import { useDojo } from '@/DojoContext'
import { felt252ToString } from '@/global/utils'
import { notificationDataAtom } from '@/global/states.ts'
import { useSetAtom } from 'jotai'
import useAlerts from '@/hooks/events/useAlerts'
import { getEntityIdFromKeys } from '@dojoengine/utils'
import useLocalStorage from '@/hooks/useLocalStorage'

type AlertType = {
  id: string,
  position: {
    x: number,
    y: number
  },
  caller: string,
  player: string,
  message: string,
  timestamp: bigint
}

type AlertProp = AlertType & {
  className?: string
}
const Alert: React.FC<AlertProp> = ({ position, caller, message, className, id }) => {
  const {
    setup: {
      components: { App },
    },
    account: {
      account
    }
  } = useDojo()

  const [ readAlerts, setReadAlerts ] = useLocalStorage<string[]>(`pixelaw::read_alerts::${account.address}`, [])
  const hasReadAlert = readAlerts.includes(id)

  const app = useComponentValue(App, getEntityIdFromKeys([BigInt(caller)]))
  const name = felt252ToString(app?.name ?? 'caller')

  const setNotificationData = useSetAtom(notificationDataAtom)

  const handleOnClickNotification = () => {
    if (!hasReadAlert) setReadAlerts(prevReadAlerts => [...prevReadAlerts, id])
    setNotificationData({
      x: position.x,
      y: position.y,
      pixelType: caller,
    })
  }

  return (
    <div
      className={cn(
        [
          'flex items-center',
          'w-full',
          'text-new-primary',
          className ?? ''
        ])}
    >
      <div onClick={handleOnClickNotification} className={'cursor-pointer w-[95%] pr-[5px]'}>{name} - {message}</div>
      {!hasReadAlert && (
        <div className={cn(['grow-0'])}>
          <div className={cn(['h-2 w-2 rounded-full bg-brand-danger'])}/>
        </div>
      )}
    </div>
  )
}

export default function Notification() {
  const [ isOpen, setIsOpen ] = React.useState<boolean>(false)

  const alerts = useAlerts()

  const {
    account: {
      account
    }
  } = useDojo()

  const [ readAlerts ] = useLocalStorage<string[]>(`pixelaw::read_alerts::${account.address}`, [])

  const hasNotification = alerts.data ?
    alerts.data.filter(alert => !readAlerts.includes(alert.id)).length > 0 : false

    return (
        <>
          {!isOpen && (
            <Button
              variant={'notification'}
              size={'notification'}
              className={cn(
                [
                  'fixed left-5 top-20 z-40',
                  'font-emoji text-[28px]',
                ])}
              onClick={() => setIsOpen(true)}
            >
                <span className={cn(['relative'])}>
                    <Image src={'/assets/svg/icon_logs.svg'} alt={'Event logs icon'}/>
                    <div
                      className={cn([ 'absolute top-[-5px] right-[-5px] border h-2 w-2 rounded-full bg-brand-danger', { 'hidden': !hasNotification } ])} />
                </span>
            </Button>
          )}

            <div
                className={cn(
                    [
                      'fixed bottom-0 z-50 overflow-y-auto',
                        'h-[calc(100vh-var(--header-height))] w-[237px]',
                        'bg-brand-body border-r-[1px] border-black',
                        'p-xs',
                        'transform transition-transform duration-300',
                        '-translate-x-full',
                        'opacity-[.88]',
                        {'translate-x-0': isOpen}
                    ])}
            >
                <div
                    className={cn(
                        [
                            'h-full',
                            'flex flex-col'
                        ])}
                >
                    <div
                        className={cn(
                            [
                                'flex items-center'
                            ])}
                    >
                        <div className={cn(['grow py-xs'])}>
                            <h2 className={cn(['text-[#FFC400] text-left text-base uppercase font-silkscreen'])}>Event Logs</h2>
                        </div>
                        <Button
                            variant={'icon'}
                            size={'icon'}
                            className={cn(['w-[20px] grow-0'])}
                            onClick={() => setIsOpen(false)}
                        >
                            <Image src={'/assets/svg/icon_close.svg'} alt={'Arrow Left Icon'}/>
                        </Button>
                    </div>

                    {(alerts?.data ?? []).map(alert => (
                      <Alert {...alert} key={alert.id} className={'mb-xs'} />
                    ))}

                </div>
            </div>
        </>
    )
}
