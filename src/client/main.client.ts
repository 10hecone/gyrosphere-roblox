import { InputControls } from "./Ball/Input/InputController";
import Remotes from "../shared/remotes";
import { CameraBall } from "./Ball/Camera/Camera";
import { CollectionService, Players, Workspace } from "@rbxts/services";
import { Ball } from "../../types/Ball";

const ballInputControls = new InputControls();
const cameraBallController = new CameraBall();

const balls = CollectionService.GetTagged("Balls")[0];

if (balls) {
	const ball = balls.FindFirstChild(`Ball_${Players.LocalPlayer.Name}_${Players.LocalPlayer.UserId}`);
	if (ball) {
		ballInputControls.enable(ball as Ball);
		cameraBallController.enable(ball as Ball);
	}
}

Workspace.DescendantAdded.Connect((c) => {
	if (c.Name !== `Ball_${Players.LocalPlayer.Name}_${Players.LocalPlayer.UserId}`) return;

	ballInputControls.enable(c as Ball);
	cameraBallController.enable(c as Ball);
});

Remotes.Client.Get("Ball").Connect((enabled) => {
	if (enabled === false) {
		cameraBallController.disable();
		ballInputControls.disable();
		print("No ball found for the player or ball disabled.");
	}
});
