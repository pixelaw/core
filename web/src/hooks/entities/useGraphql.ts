import {QueryKey, useQuery, UseQueryOptions} from "@tanstack/react-query";
import request, {Variables} from "graphql-request";
import {TORII_END_POINT} from '@/global/constants';

const useGraphql = <GQLQueryReturn, ReturnType>(
  queryKey: QueryKey,
  query: string,
  variables?: Variables,
  mapReturn?: (data: GQLQueryReturn) => ReturnType,
  queryOptions?: Omit<UseQueryOptions, "queryKey" | "queryFn">
) => {
  return useQuery({
    queryKey,
    queryFn: async () => {
      const data: GQLQueryReturn = await request(TORII_END_POINT, query, variables)
      if (mapReturn) return mapReturn(data)
      return data
    },
    ...queryOptions
  })

}

export default useGraphql
