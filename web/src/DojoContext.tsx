import { createContext, ReactNode, useContext, useMemo } from "react";
import { SetupResult } from "./dojo/setup";
import { Account, RpcProvider } from "starknet";
import { BurnerProvider, useBurner } from '@dojoengine/create-burner'
import { PUBLIC_NODE_URL } from '@/global/constants'

interface DojoContextType extends SetupResult {
  masterAccount: Account
}

const DojoContext = createContext<DojoContextType | null>(null);

type Props = {
  children: ReactNode;
  value: SetupResult;
  master: {
    address: string,
    classHash: string,
    privateKey: string
  }
};

export const DojoProvider = ({ children, value, master }: Props) => {

  const currentValue = useContext(DojoContext);
  if (currentValue) throw new Error("DojoProvider can only be used once");

  const rpcProvider = useMemo(
    () =>
      new RpcProvider({
        nodeUrl: PUBLIC_NODE_URL,
      }),
    [],
  );

  const masterAddress = master.address;
  const privateKey = master.privateKey;
  const masterAccount = useMemo(
    () => new Account(rpcProvider, masterAddress, privateKey),
    [rpcProvider, masterAddress, privateKey],
  );

  return (
    <BurnerProvider initOptions={{ masterAccount, accountClassHash: master.classHash, rpcProvider }}>
      <DojoContext.Provider value={{ ...value, masterAccount }}>
        {children}
      </DojoContext.Provider>
    </BurnerProvider>
  )
};

export const useDojo = () => {
  const contextValue = useContext(DojoContext);
  if (!contextValue)
    throw new Error("The `useDojo` hook must be used within a `DojoProvider`");

  const {
    create,
    list,
    get,
    account,
    select,
    isDeploying,
    clear,
    copyToClipboard,
    applyFromClipboard,
  } = useBurner();

  return {
    setup: contextValue,
    account: {
      create,
      list,
      get,
      select,
      clear,
      account: account ?? contextValue.masterAccount,
      isDeploying,
      copyToClipboard,
      applyFromClipboard,
    },
  };
};
