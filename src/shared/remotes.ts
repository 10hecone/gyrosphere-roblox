import Net from "@rbxts/net";
import { Ball } from "../../types/Ball";
const { Create } = Net.Definitions;

const Remotes = Create({
  Ball: Net.Definitions.ServerToClientEvent<[enabled: boolean, ball: Ball | undefined]>(),
  GrappleHook: Net.Definitions.ServerAsyncFunction<(position: Vector3) => boolean>(),
  UnGrappleHook: Net.Definitions.ServerAsyncFunction<() => boolean>(),
});

export default Remotes;
