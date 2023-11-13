import {atom} from "jotai";
import { NotificationDataType, PositionWithAddressAndType } from '@/global/types.ts'

export const colorAtom = atom('#FFFFFF')

export const gameModeAtom = atom<"none" |"paint" | "rps" | "snake">("paint")

export const zoomLevelAtom = atom<number>(50)

export const positionWithAddressAndTypeAtom = atom<PositionWithAddressAndType>({
  x: 0,
  y: 0,
  address: '',
  pixel: '',
})

export const notificationDataAtom = atom<NotificationDataType | undefined>(undefined)
