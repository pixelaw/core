import React from 'react'

import { PAPER, ROCK, SCISSORS } from './constants'

export type OptionType = typeof ROCK | typeof PAPER | typeof SCISSORS

export type OwnerComponent = {
  address: string,
  __typename: "Owner"
}

export type PositionComponent = {
  x: number,
  y: number,
  __typename: "Position"
}

export type PixelTypeComponent = {
  name: string,
  __typename: "PixelType"
}

export type TimestampComponent = {
  created_at: number
  updated_at: number
  __typename: "Timestamp"
}

export type ColorComponent = {
  r: number
  g: number
  b: number
  __typename: "Color"
}

export type ColorCountComponent = {
  count: string
  __typename: "ColorCount"
}


export type PixelEntity = {
  id: string,
  owner?: string,
  position?: { x: number, y: number },
  pixelType?: string,
  createdAt?: number,
  updatedAt?: number,
  color?: {
    r: number,
    g: number,
    b: number
  },
  colorCount?: number
}

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
