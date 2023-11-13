// for now storing events to process in memory
export const eventsToProcess: Record<string, { id: string, timestamp: number, called_system: string, selector: string, calldata: any[] }> = {}
