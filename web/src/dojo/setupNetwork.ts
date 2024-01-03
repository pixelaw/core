import { defineContractComponents } from "./contractComponents";
import { world } from "./world";
import { DojoProvider } from '@dojoengine/core'
import { Account, num } from "starknet";
import { Manifest } from '@/global/types'
import { streamToString } from '@/global/utils'
import { PUBLIC_NODE_URL, PUBLIC_TORII } from '@/global/constants'
import * as torii from '@dojoengine/torii-client'
import { GraphQLClient } from 'graphql-request';
import { getSdk } from '@/generated/graphql';

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

  // Utility function to get the SDK.
  // Add in new queries or subscriptions in src/graphql/schema.graphql
  // then generate them using the codegen and fix-codegen commands in package.json
  const createGraphSdk = () => getSdk(new GraphQLClient(`${PUBLIC_TORII}/graphql`));

  // Return the setup object.
  return {
    provider,
    world,
    toriiClient,

    // Define contract components for the world.
    contractComponents: defineContractComponents(world),

    // Define the graph SDK instance.
    graphSdk: createGraphSdk(),

    // Execute function.
    execute: async (signer: Account, contractName: string, system: string, call_data: num.BigNumberish[]) => {
      return provider.execute(signer, contractName, system, call_data);
    },

    switchManifest: (manifest: Manifest) => {
      provider.manifest = manifest
    }
  };
}
