import React from 'react'
import {cn} from "@/lib/utils";
import Logo from "@/components/shared/Logo";
import useLocalStorage from "@/hooks/useLocalStorage";
import {Active_Page, MainLayoutType} from "@/global/types";
import ZoomControl from "@/components/ZoomControl";
import { useDojo } from '@/DojoContext'
import WalletAddress from '@/components/WalletAddress'
import Loading from '@/components/Loading'
import { getUrlParam } from '@/global/utils'
import useCreateBurner from '@/hooks/utils/useCreateBurner'

export const MainLayoutContext = React.createContext<MainLayoutType>({} as MainLayoutType)

const WideWrapper = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({className, children, ...props}, ref) => {
    return (
      <div className={cn(
        [
          'w-full',
          'flex items-center justify-between',
          'mx-sm',
          className
        ])}
           ref={ref}
           {...props}
      >
        {children}
      </div>
    )
  }
)

WideWrapper.displayName = 'WideWrapper'

export default function MainLayout({children}: { children: React.ReactNode }) {
  const [hasNavbar, setHasNavbar] = React.useState<boolean>(false)
  const [hasBackgroundImage, setHasBackgroundImage] = React.useState<boolean>(true)
  const [hasBackgroundOverlay, setHasBackgroundOverlay] = React.useState<boolean>(false)
  const [currentPage, setCurrentPage] = useLocalStorage('current-page', 3)

  const {
    account: {
      account,
      select
    },
  } = useDojo()

  const index = getUrlParam('account', 0)

  const { isLoading, data, isSuccess } = useCreateBurner(index)

  React.useEffect(() => {
    if (account.address === data || !data || !isSuccess) return
    select(data)
  }, [select, account.address, data, isSuccess])

  if (isLoading) {
    return <Loading>Deploying burner wallet</Loading>
  }




  return (
    <MainLayoutContext.Provider value={{
      setHasNavbar,
      setHasBackgroundImage,
      setHasBackgroundOverlay,
      currentPage,
      setCurrentPage
    }}>
      <main
        className={cn(
          [
            'min-h-screen',
            'flex flex-col',
            'bg-brand-body text-white',
            {'bg-main bg-cover bg-center': hasBackgroundImage},
          ])}
      >
        <div
          className={cn(
            [
              'h-screen w-screen bg-black/70 absolute bottom-0 z-10',
              {"h-[calc(100vh-var(--header-height))]": currentPage === Active_Page.Lobby || currentPage === Active_Page.Gameplay},
              {'invisible': !hasBackgroundOverlay}
            ])}
        />
        <header
          className={cn([
            'min-h-[var(--header-height)] w-full',
            'fixed z-50',
            'flex items-center flex-grow-0',
            'bg-brand-blackAccent',
            {'invisible': !hasNavbar}
          ])}
        >
          <WideWrapper>
            <Logo
              className={cn(
                [
                  'w-[139px] h-[46px]',
                ]
              )}
              onClick={() => setCurrentPage(Active_Page.Lobby)}
            />

            <ZoomControl
              max={100}
              min={25}
              steps={5}
            />

            <WalletAddress address={account.address} />
          </WideWrapper>
        </header>

        <div
          className={cn(
            [
              'flex flex-col flex-1 z-20',
              {'pt-[var(--header-height)]': hasNavbar}
            ]
          )}
        >
          {children}
        </div>
      </main>
    </MainLayoutContext.Provider>
  )
}

export function useMainLayout() {
  return React.useContext(MainLayoutContext)
}
