// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import { overridableComponent } from "@latticexyz/recs";
import { SetupNetworkResult } from "./setupNetwork";

export type ClientComponents = ReturnType<typeof createClientComponents>;

export function createClientComponents({ contractComponents }: SetupNetworkResult) {
    return {
        ...contractComponents,
      Pixel: overridableComponent(contractComponents.Pixel)
    };
}
