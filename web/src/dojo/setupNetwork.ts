import { defineContractComponents } from "./contractComponents";
import { world } from "./world";
import { DojoProvider } from '@dojoengine/core'
import { Account, num } from "starknet";
import { Manifest } from '@/global/types'
import { streamToString } from '@/global/utils'
import { PUBLIC_NODE_URL, PUBLIC_TORII } from '@/global/constants'
import * as torii from '@dojoengine/torii-client'

export type SetupNetworkResult = Awaited<ReturnType<typeof setupNetwork>>;
const MANIFEST_URL = '/manifests/core'

export async function setupNetwork() {

  const manifest: Manifest = await (async () => {
    const result = await fetch(MANIFEST_URL)
    if (!result.body) return {}
    const string = await streamToString(result.body)
    return JSON.parse(string)
  })()

  const worldAddress = manifest.world.address ?? ''

  // Create a new RPCProvider instance.
  const provider = new DojoProvider(worldAddress, manifest, PUBLIC_NODE_URL);

  const toriiClient = await torii.createClient([], {
    rpcUrl: PUBLIC_NODE_URL,
    toriiUrl: PUBLIC_TORII,
    worldAddress: worldAddress,
  });

  // Return the setup object.
  return {
    provider,
    world,
    toriiClient,

    // Define contract components for the world.
    contractComponents: defineContractComponents(world),

    // Execute function.
    execute: async (signer: Account, contractName: string, system: string, call_data: num.BigNumberish[]) => {
      return provider.execute(signer, contractName, system, call_data);
    },

    switchManifest: (manifest: Manifest) => {
      provider.manifest = manifest
    }
  };
}
