import {atom} from "jotai";
import { NotificationDataType, PositionWithAddressAndType } from '@/global/types.ts'

export const colorAtom = atom('#FFFFFF')

export const gameModeAtom = atom<string>("paint")

export const zoomLevelAtom = atom<number>(25)

export const positionWithAddressAndTypeAtom = atom<PositionWithAddressAndType>({
  x: 0,
  y: 0,
  address: '',
  pixel: '',
})

export const notificationDataAtom = atom<NotificationDataType | undefined>(undefined)
