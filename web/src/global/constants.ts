import { getProductionUrl } from '@/global/utils'

export const PUBLIC_TORII: string =  import.meta.env.VITE_PUBLIC_TORII ?? getProductionUrl('torii')

export const PUBLIC_NODE_URL: string = import.meta.env.VITE_PUBLIC_NODE_URL ?? getProductionUrl('katana')

export const BLOCK_TIME = 1_000

export const MAX_CELL_SIZE = 128

export const MAX_ROWS_COLS = 256

export const CANVAS_WIDTH = 1728
export const CANVAS_HEIGHT = 704

export const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000000000000000000000000000'
