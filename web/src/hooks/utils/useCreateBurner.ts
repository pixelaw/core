import { useDojo } from '@/dojo/useDojo'
import { useQuery } from '@tanstack/react-query'

const useCreateBurner = (accountIndex: number) => {
  const {
    account: {
      create
    },
  } = useDojo()

  return useQuery({
    queryKey: ['createAccount', accountIndex],
    queryFn: async () => {
      const accounts: string[] = Object.keys(JSON.parse(localStorage.getItem('burners') ?? '{}'))
      const selectedAccount = accounts[accountIndex]
      if (selectedAccount) {
        return selectedAccount
      }
      const accountsToCreate = accountIndex - accounts.length + 1
      const account = { address: ''}
      for (let i = 0; i < accountsToCreate; i ++) {
        await create()
      }
      return account.address
    },
    staleTime: Infinity
  })
}

export default useCreateBurner
