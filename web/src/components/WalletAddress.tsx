import React from "react";
import { Button, ButtonProps } from '@/components/ui/button'

const PLACEHOLDER = "0x0000000000000000000000000000000000000000"

type PropsType = {
  address?: string
}

const WalletAddress: React.FC<ButtonProps & PropsType> = (props) => {
  const { address } = props
  const defaultAddress = (address ?? PLACEHOLDER)
  const shortenedAddress = defaultAddress.substring(0, 6) + '...' + defaultAddress.substring(defaultAddress.length - 4)
  const handleOnClick = () => navigator.clipboard.writeText(address ?? PLACEHOLDER)

  return (
    <Button{...props} onClick={handleOnClick} variant={'outline'} size={'walletHeader'}>
      { shortenedAddress }
    </Button>
  )
}

WalletAddress.displayName = "NavigationBarWalletAddress"

export default WalletAddress
