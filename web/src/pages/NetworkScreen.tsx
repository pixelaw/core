import React from "react";
import {useMainLayout} from "@/components/layouts/MainLayout";
import {cn} from "@/lib/utils";
import ActionDiv from "@/components/ActionDiv";
import {wallets} from "@/global/config";
import {Active_Page} from "@/global/types";

export default function NetworkScreen() {
    const {setHasBackgroundOverlay, setCurrentPage} = useMainLayout()
    const [wallet, setWallet] = React.useState('')
    const [network, setNetwork] = React.useState('')

    const networks = (wallets[wallet]?.networks ?? []).map((network) => {
        return {
            ...network,
            onClick: () => {
                setNetwork(network.label)
                setCurrentPage(Active_Page.Lobby)
            }
        }
    })

    const walletChoices = Object.values(wallets).map((wallet) => {
        return {
            ...wallet,
            onClick: () => {
                setWallet(wallet.label)
                setNetwork('')
            }
        }
    })

    React.useEffect(() => {
        setHasBackgroundOverlay(true)
    }, [])

    return (
        <div
            className={cn(
                [
                    'flex-center flex-1'
                ])}
        >
            <div
                className={cn(
                    [
                        'flex flex-col gap-y-md',
                        'max-w-[745px] w-full'
                    ])}
            >
                <ActionDiv
                    label={'Select Wallet'}
                    actions={walletChoices}
                    selected={wallet}
                    defaultMessage={'No wallets to display'}
                />

                {
                    !!wallet &&
                    <ActionDiv
                        label={'Select Network'}
                        actions={networks}
                        selected={network}
                        defaultMessage={'No networks to display'}
                    />
                }
            </div>
        </div>
    )
}
