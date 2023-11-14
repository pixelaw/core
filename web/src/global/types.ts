import React from 'react'

export enum Active_Page {
  Home,
  Network,
  Lobby,
  Gameplay
}

export type MainLayoutType = {
  setHasNavbar: React.Dispatch<React.SetStateAction<boolean>>
  setHasBackgroundImage: React.Dispatch<React.SetStateAction<boolean>>
  setHasBackgroundOverlay: React.Dispatch<React.SetStateAction<boolean>>
  currentPage:  number
  setCurrentPage:   React.Dispatch<React.SetStateAction<number>>
}

export type Account = {
  address: string,
  active: boolean
}

export type PositionWithAddressAndType = {
  x: number | undefined
  y: number | undefined
  address?: string | number
  pixel?: string | number
}

export type NotificationDataType = {
  x: number | undefined
  y: number | undefined
  pixelType?: string | number
}
