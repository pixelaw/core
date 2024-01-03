import { createClientComponents } from "./createClientComponents";
import { createSystemCalls } from "./createSystemCalls";
import { setupNetwork } from "./setupNetwork";
import { getSyncEntities } from '@dojoengine/react'

export type SetupResult = Awaited<ReturnType<typeof setup>>;

export async function setup() {
    const network = await setupNetwork();
    const components = createClientComponents(network);
    const systemCalls = createSystemCalls(network);

    await getSyncEntities(
      network.toriiClient,
      network.contractComponents as any
    );



  return {
        network,
        components,
        systemCalls,
    };
}
