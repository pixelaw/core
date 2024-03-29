import { getSyncEntities } from "@dojoengine/state";
import { DojoConfig, DojoProvider } from "@dojoengine/core";
import * as torii from "@dojoengine/torii-client";
import { createClientComponents } from "./createClientComponents";
import { createSystemCalls } from "./createSystemCalls";
import { defineContractComponents } from "./contractComponents";
import { world } from "./world";
import { setupWorld } from "./generated";
import { Account } from "starknet";
import { BurnerManager } from "@dojoengine/create-burner";
import { getSdk } from '@/generated/graphql'
import { GraphQLClient } from 'graphql-request'
import { PUBLIC_TORII } from '@/global/constants'

export type SetupResult = Awaited<ReturnType<typeof setup>>;

export async function setup({ ...config }: DojoConfig) {
  console.group('setup');

  console.log("torii.createClient")
  // torii client
  const toriiClient = await torii.createClient([], {
    rpcUrl: config.rpcUrl,
    toriiUrl: config.toriiUrl,
    worldAddress: config.manifest.world.address || "",
  });

  console.log("defineContractComponents")

  // create contract components
  const contractComponents = defineContractComponents(world);

  console.log("createClientComponents")

  // create client components
  const clientComponents = createClientComponents({ contractComponents });

  console.log("getSyncEntities")
  // fetch all existing entities from torii
  await getSyncEntities(toriiClient, contractComponents as any);

  console.log("new DojoProvider")

  // create dojo provider
  const dojoProvider = new DojoProvider(config.manifest, config.rpcUrl);

  console.log("setupWorld")

  // setup world
  const client = await setupWorld(dojoProvider);

  console.log("new BurnerManager")
  // create burner manager
  const burnerManager = new BurnerManager({
    masterAccount: new Account(
      dojoProvider.provider,
      config.masterAddress,
      config.masterPrivateKey
    ),
    accountClassHash: config.accountClassHash,
    rpcProvider: dojoProvider.provider,
  });

  if (burnerManager.list().length === 0) {
    try {
      await burnerManager.create();
    } catch (e) {
      console.error(e);
    }
  }
  console.log("burnerManager.init()")

  await burnerManager.init();

  // Utility function to get the SDK.
  // Add in new queries or subscriptions in src/graphql/schema.graphql
  // then generate them using the codegen and fix-codegen commands in package.json
  const createGraphSdk = () => getSdk(new GraphQLClient(`${PUBLIC_TORII}/graphql`));
  console.groupEnd();
  return {
    client,
    clientComponents,
    contractComponents,
    // Define the graph SDK instance.
    graphSdk: createGraphSdk(),
    systemCalls: createSystemCalls(
      { client }
    ),
    config,
    dojoProvider,
    burnerManager,
    switchManifest: (manifest: any) => dojoProvider.manifest = manifest
  };
}
