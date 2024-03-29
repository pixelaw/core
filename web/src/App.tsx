import MainLayout from "@/components/layouts/MainLayout";
import ScreenAtomRenderer from "@/components/ScreenAtomRenderer";
import { Toaster } from '@/components/ui/toaster'
import { useQuery } from '@tanstack/react-query'
import { setup } from '@/dojo/setup'
import { CORE_VERSION, PUBLIC_NODE_URL, PUBLIC_TORII } from '@/global/constants'
import { DojoProvider } from './DojoContext';
import Loading from '@/components/Loading'
import { cn } from '@/lib/utils'
import React from 'react'
import { createDojoConfig } from '@dojoengine/core'
import { streamToString } from '@/global/utils'

const DO_NOT_EXCEED_MS = 30_000

function App() {
  React.useEffect(() => {
    document.title = `PixeLAW ${CORE_VERSION}`
  }, [CORE_VERSION])

  const checkRpcUrl = useQuery(
    {
      queryKey: ['rpcUrl'],
      queryFn: async () => await fetch(PUBLIC_NODE_URL),
      retryDelay: attemptIndex => Math.min(1000 * 2 ** attemptIndex, DO_NOT_EXCEED_MS),
      retry: 8
    }
  )

  const checkTorii = useQuery(
    {
      queryKey: ['toriiUrl'],
      queryFn: async () => await fetch(PUBLIC_TORII),
      retryDelay: attemptIndex => Math.min(1000 * 2 ** attemptIndex, DO_NOT_EXCEED_MS),
      retry: 8,
      enabled: checkRpcUrl.isSuccess
    }
  )

  const checkManifests = useQuery(
    {
      queryKey: ['coreManifest'],
      queryFn: async () => {
        const result = await fetch('/manifests/core')
        if (!result.body) return {}
        const string = await streamToString(result.body)
        return JSON.parse(string)
      },
      retryDelay: attemptIndex => Math.min(1000 * 2 ** attemptIndex, DO_NOT_EXCEED_MS),
      retry: 8,
      enabled: checkRpcUrl.isSuccess
    }
  )

  const setupQuery = useQuery(
    {
      queryKey: ['setup'],
      queryFn: async() => {
        return setup(
          createDojoConfig({
            manifest: checkManifests.data,
            masterAddress: '0x003c4dd268780ef738920c801edc3a75b6337bc17558c74795b530c0ff502486',
            masterPrivateKey: '0x2bbf4f9fd0bbb2e60b0316c1fe0b76cf7a4d0198bd493ced9b8df2a3a24d68a',
            rpcUrl: PUBLIC_NODE_URL,
            toriiUrl: PUBLIC_TORII
          })
        )
      },
      retry: false,
      retryDelay: attemptIndex => Math.min(1000 * 2 ** attemptIndex, DO_NOT_EXCEED_MS),
      enabled: checkManifests.isSuccess
    }
  )

  if (checkRpcUrl.isLoading) {
    return <Loading>Loading Public Node URL</Loading>
  }

  if (checkTorii.isLoading) {
    return <Loading>Contracts are being deployed</Loading>
  }

  if (checkManifests.isLoading) {
    return <Loading>Core Manifest</Loading>
  }

  if (setupQuery.isLoading) {
    return <Loading >Loading setupQuery</Loading>
  }

  if (setupQuery.data) {
    return (
      <DojoProvider value={setupQuery.data}>
        <MainLayout>
          <ScreenAtomRenderer/>
          <Toaster />
        </MainLayout>
      </DojoProvider>
    );
  }

  let errorMessage = ''
  if(setupQuery.isError){
    errorMessage = `setupQuery Error: ${setupQuery.error}`
  }
  console.log({ setupQuery, checkManifests })

  if (checkRpcUrl.isError) {
    errorMessage = `PUBLIC_NODE_URL error: ${checkRpcUrl.error.message}. If this is happening in your local environment, Katana might not be up.`
  }

  if (checkTorii.isError) {
    errorMessage = `PUBLIC_TORII error: ${checkTorii.error.message}. If this is happening in your local environment, Torii might not be up.`
  }

  if (checkManifests.isError) {
    errorMessage = `Core Manifest Error: ${checkManifests.error.message}. If this is happening in your local environment, Keiko might not be up or the Core Manifest might not have been uploaded yet.`
  }

  return (
    <div
      className={cn(
        [
          'fixed top-0 bottom-0 left-0 w-full bg-brand-body z-40 flex-center'
        ]
      )}
    >
        <div className={'w-[25%]'}>
          <h1 className={'text-lg uppercase font-silkscreen text-brand-danger text-center'}>Something went wrong</h1>
          {errorMessage !== '' && <p className={'text-sm text-brand-violetAccent text-white mt-xs'}>{errorMessage}</p>}
          <p className={'text-sm text-brand-violetAccent text-white mt-xs'}>Try to refresh this page. If issue still persists, alert the team at Discord.</p>
        </div>
    </div>
  );
}

export default App;
