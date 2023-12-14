import { useQueryClient } from '@tanstack/react-query'
import { getUrlParam } from '@/global/utils'

const useAccountAddress = () => {
  const queryClient = useQueryClient();
  return queryClient.getQueryData<string>(['createAccount', getUrlParam('account', 0)])
}

export default useAccountAddress
