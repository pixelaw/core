import React from 'react'
import { useDojo } from '@/DojoContext'
import Plugin from '@/components/Plugin'
import { ColorResult, CompactPicker } from 'react-color'
import DrawPanel from '@/components/shared/DrawPanel'
import { useFilteredEntities } from '@/hooks/entities/useFilteredEntities'
import { Account } from '@/global/types'
import DrawPanelProvider, { useDrawPanel } from '@/providers/DrawPanelProvider.tsx'
import { useAtom } from 'jotai'
import { colorAtom } from '@/global/states.ts'
import useAnnounceAlert from '@/hooks/events/useAnnounceAlert'
import useUpdateComponent from '@/hooks/entities/useUpdateComponent'

const FilteredComponents: React.FC = () => {
  const { visibleAreaStart, visibleAreaEnd } = useDrawPanel()
  useFilteredEntities(visibleAreaStart[0], visibleAreaEnd[0], visibleAreaStart[1], visibleAreaEnd[1])
  return <></>
}

const Main = () => {
  const {
    account: {
      create,
      list,
      select,
      isDeploying,
      account
    },
  } = useDojo()
  //return list of accounts ({address: '0x00...', active: boolean})[]
  const accounts = list()

  const urlParams = new URLSearchParams(window.location.search)
  const accountParam = urlParams.get('account')

  const accountParamInt = parseInt(accountParam ?? '1')
  const index = isNaN(accountParamInt) ? 1 : accountParamInt

  const selectedAccount = accounts[index - 1] as Account | undefined
  const hasAccount = !!selectedAccount
  const isAlreadySelected = account.address === selectedAccount?.address

  const [ isLoading, setIsLoading ] = React.useState(true)

  //selected color in color pallete
  const [ selectedHexColor, setColor ] = useAtom(colorAtom)

  React.useEffect(() => {
    if (isDeploying || isNaN(index) || hasAccount) return
    create()
  }, [ setIsLoading, hasAccount, index, isDeploying, create ])

  React.useEffect(() => {
    if (isAlreadySelected) {
      setIsLoading(false)
      return
    }

    if (!hasAccount) return

    select(selectedAccount?.address ?? '')
  }, [ setIsLoading, isAlreadySelected, selectedAccount?.address, select, hasAccount ])

  const handleColorChange = (color: ColorResult) => {
    setColor(color.hex)
  }

  // subscribe to torii messages to announce alerts and automatically update the components
  useAnnounceAlert()
  useUpdateComponent()

  return (
      <React.Fragment>
          {
              !isLoading ?
                <DrawPanelProvider>
                      <div className={'m-sm'}>
                        <DrawPanel />

                          <div className="fixed bottom-5 right-20">
                            {/* eslint-disable-next-line @typescript-eslint/ban-ts-comment */}
                            {/*// @ts-ignore*/}
                            <CompactPicker color={selectedHexColor} onChangeComplete={handleColorChange} />
                          </div>
                      </div>

                      <Plugin/>

                  <FilteredComponents />

                </DrawPanelProvider>
                  :
                  <div className={'fixed top-0 bottom-0 left-0 w-full bg-brand-body z-40 flex-center'}>
                      <div
                          className={'w-16 h-16 border-t-2 border-brand-violetAccent border-solid rounded-full animate-spin'}/>
                      <h2 className={'text-lg uppercase font-silkscreen text-brand-violetAccent ml-xs'}>Loading...</h2>
                  </div>
          }
      </React.Fragment>
  )
};

export default Main
