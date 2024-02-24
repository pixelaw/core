// @ts-ignore
import { overridableComponent } from "@dojoengine/recs";
import { ContractComponents } from "./contractComponents";

export type ClientComponents = ReturnType<typeof createClientComponents>;

export function createClientComponents({
  contractComponents,
}: {
  contractComponents: ContractComponents;
}) {
  return {
    ...contractComponents,
    Pixel: overridableComponent(contractComponents.Pixel)
  };
}
