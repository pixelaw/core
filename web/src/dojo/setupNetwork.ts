import { defineContractComponents } from "./contractComponents";
import { world } from "./world";
import { RPCProvider, Query, } from "@dojoengine/core";
import { Account, num } from "starknet";
import { GraphQLClient } from 'graphql-request';
import { getSdk } from '@/generated/graphql';
// import { streamToString } from '@/global/utils'
import manifest from './manifest.json'

export type SetupNetworkResult = Awaited<ReturnType<typeof setupNetwork>>;

// const getManifest: () => Promise<{ world: { address?: string }, contracts: { name: string, address: string }[]}> = async () => {
//   const result = await  fetch("/world/manifest.json")
//   const stream = result.body
//   if (!stream) return {}
//   return JSON.parse( await streamToString(stream))
// }

export async function setupNetwork() {
  // Extract environment variables for better readability.
  const { VITE_PUBLIC_NODE_URL, VITE_PUBLIC_TORII } = import.meta.env;

  // const manifest = await getManifest()

  const worldAddress = manifest.world.address

  // Create a new RPCProvider instance.
  const provider = new RPCProvider(worldAddress, manifest, VITE_PUBLIC_NODE_URL);

  // Utility function to get the SDK.
  // Add in new queries or subscriptions in src/graphql/schema.graphql
  // then generate them using the codegen and fix-codegen commands in package.json
  const createGraphSdk = () => getSdk(new GraphQLClient(VITE_PUBLIC_TORII));

  // Return the setup object.
  return {
    provider,
    world,

    // Define contract components for the world.
    contractComponents: defineContractComponents(world),

    // Define the graph SDK instance.
    graphSdk: createGraphSdk(),

    // Execute function.
    execute: async (signer: Account, contractName: string, system: string, call_data: num.BigNumberish[]) => {
      return provider.execute(signer, contractName, system, call_data);
    },

    // Entity query function.
    entity: async (component: string, query: Query) => {
      return provider.entity(component, query);
    },

    // Entities query function.
    entities: async (component: string, partition: number) => {
      return provider.entities(component, partition);
    },

    switchManifest: (manifest: any) => {
      provider.manifest = manifest
    }
  };
}
