import {
	CollectionService,
	ContextActionService,
	Players,
	RunService,
	UserInputService,
	Workspace,
} from "@rbxts/services";
import { Ball } from "../../../../types/Ball";
import Remotes from "../../../shared/remotes";
import { ContextInput } from "../../../../types/ContextInput";
import { CameraBall } from "../Camera/Camera";

const player = Players.LocalPlayer;

export class InputControls {
	enabled: boolean;
	ballControlsConnection: RBXScriptConnection | undefined;
	canAttach: boolean;
	ball: undefined | Ball;

	constructor() {
		this.ball = undefined;
		this.enabled = false;
		this.ballControlsConnection;
		this.canAttach = false;
	}

	private getHumanoid(): Humanoid | undefined {
		const character = Players.LocalPlayer.Character;
		if (!character) return undefined;
		const humanoid = character.FindFirstChildWhichIsA("Humanoid");
		if (humanoid === undefined || humanoid.Health <= 0) return undefined;
		return humanoid;
	}

	private getBallFromPlayer(): Ball | undefined {
		if (this.ball && this.ball.Parent) return this.ball;
		const ball = CollectionService.GetTagged(tostring(player.UserId))[0] as Ball | undefined;
		this.ball = ball;
		return ball;
	}

	private getPrimaryPart(ball: Ball): BasePart | undefined {
		const root = ball.PrimaryPart;
		if (!root) return undefined;
		return root;
	}

	private jumpBoost() {
		const ball = this.getBallFromPlayer();
		if (!ball) return;

		const root = this.getPrimaryPart(ball);
		if (!root) return;

		const v = root.AssemblyLinearVelocity;
		root.AssemblyLinearVelocity = new Vector3(v.X, 0, v.Z);

		const jumpVelocity = 70;
		const impulse = Vector3.yAxis.mul(jumpVelocity * root.AssemblyMass);

		root.ApplyImpulse(impulse);
	}

	private async onMouseDown() {
		const camera = Workspace.CurrentCamera;

		if (!camera) return;

		const ball = this.getBallFromPlayer();
		if (!ball) return;
		const ballPrimaryPart = this.getPrimaryPart(ball);
		if (!ballPrimaryPart) return;

		//const hook = CameraBall.canHook(camera.CFrame, grappleFolder);
		const hookSimply = CameraBall.canSimplyHook(camera.CFrame, ballPrimaryPart.CFrame);

		if (!hookSimply) return;

		const succes = await Remotes.Client.Get("GrappleHook").CallServerAsync(hookSimply);
		if (!succes) return;
	}

	private async onMouseUp() {
		const succes = await Remotes.Client.Get("UnGrappleHook").CallServerAsync();
		if (!succes) return;
	}

	private isAirborne(root: BasePart | undefined): boolean {
		if (root?.Parent === undefined) return false;
		const ball = this.getBallFromPlayer();
		if (!ball) return false;
		const rayOrigin = root.Position;
		const rayDirection = new Vector3(0, -8, 0);
		const raycastParams = new RaycastParams();

		raycastParams.FilterDescendantsInstances = [root.Parent!, ball];
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude;

		const result = Workspace.Raycast(rayOrigin, rayDirection, raycastParams);

		if (result) {
			return false;
		}
		return true;
	}

	private isAgainstWall(root: BasePart | undefined): boolean {
		if (root?.Parent === undefined) return false;
		const ball = this.getBallFromPlayer();
		if (!ball) return false;
		const rayOrigin = root.Position.sub(new Vector3(0, 1.75, 0));
		const look = root.CFrame.LookVector;
		const horizontalLook = new Vector3(look.X, 0, look.Z);

		if (horizontalLook.Magnitude === 0) return false;

		const rayDirection = horizontalLook.Unit.mul(7.5);
		const raycastParams = new RaycastParams();

		raycastParams.FilterDescendantsInstances = [root.Parent!, ball];
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude;

		const result = Workspace.Raycast(rayOrigin, rayDirection, raycastParams);
		if (result) {
			return result.Instance.CanCollide === true;
		}
		return result !== undefined;
	}

	private handleAirMovement(enabled: boolean, ball: Ball, humanoid: Humanoid) {
		const mass = ball.PrimaryPart?.GetMass() ?? 1;
		const lv = ball.Constraints.LinearVelocity as unknown as VectorForce;

		if (enabled) {
			const camera = Workspace.CurrentCamera;
			if(!camera) return;
			const forward = new Vector3(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit;

			const right = Vector3.yAxis.Cross(forward).Unit;
			const input = humanoid.MoveDirection;
			const moveDir = forward.mul(-input.Z).add(right.mul(input.X));
			const horizontal = new Vector3(-moveDir.X, 0, moveDir.Z);

			const accel = 100;
			const force = mass * accel;

			lv.Force = horizontal.mul(force);
			lv.Enabled = true;
		} else {
			lv.Force = new Vector3(0, 0, 0);
			lv.Enabled = false;
		}
	}

	private handleWallBoost(ballPrimaryPart: BasePart) {
		ballPrimaryPart.AssemblyLinearVelocity = new Vector3(
			ballPrimaryPart.AssemblyLinearVelocity.X,
			30,
			ballPrimaryPart.AssemblyLinearVelocity.Z,
		);
	}

	private onStepped() {
		if (this.enabled === false) return this.ballControlsConnection?.Disconnect();

		const humanoid = this.getHumanoid();

		if (!humanoid) return this.disable();

		const ball = this.getBallFromPlayer();

		if (!ball) return this.disable();

		const ballPrimaryPart = this.getPrimaryPart(ball);

		if (!ballPrimaryPart) return;
		if (
			this.isAgainstWall(humanoid.RootPart!) &&
			math.floor(ballPrimaryPart?.AssemblyLinearVelocity.Magnitude) >= 1
		) {
			this.handleWallBoost(ballPrimaryPart)
		}

		this.handleAirMovement(this.isAirborne(humanoid.RootPart!), ball, humanoid);
	}

	public enable(ball: Ball) {
		task.wait();
		this.enabled = true;

		this.ballControlsConnection = RunService.Stepped.Connect(() => this.onStepped());

		const playerGui = player.FindFirstChild("PlayerGui") as PlayerGui;
		const input = playerGui.FindFirstChild("PlayContext") as InputContext;
		const jump = input.FindFirstChild("Jump") as InputAction;
		const inputGui = playerGui.FindFirstChild("ContextInput") as ContextInput;
		const grappleHook = input.FindFirstChild("GrappleHook") as InputAction;

		const hud = playerGui.FindFirstChild("HUD") as ScreenGui;
		const main = hud.FindFirstChild("FrameMain") as Frame;
		const help = main.FindFirstChild("FrameHelp") as Frame;

		ball.Destroying.Connect(() => {
			this.enabled = false;
			this.disable();
		});

		if (input) {
			input.Enabled = true;
		}
		if (UserInputService.TouchEnabled) {
			inputGui.Enabled = true;
			help.Visible = false;
		} else {
			help.Visible = true;
		}

		grappleHook.Pressed.Connect(() => {
			this.onMouseDown();
		});

		grappleHook.Released.Connect(() => {
			this.onMouseUp();
		});

		jump.Pressed.Connect(() => {
			const humanoid = this.getHumanoid();
			if (!humanoid) return;

			if (!this.isAirborne(humanoid.RootPart!)) {
				this.jumpBoost();
			}
		});
	}

	public disable() {
		this.enabled = false;
		const playerGui = player.FindFirstChild("PlayerGui") as PlayerGui | undefined;
		if (playerGui === undefined) return;
		const input = playerGui.FindFirstChild("PlayContext") as InputContext | undefined;
		const inputGui = playerGui.FindFirstChild("ContextInput") as ScreenGui | undefined;

		if (inputGui) {
			inputGui.Enabled = false;
		}
		if (input) {
			input.Enabled = false;
		}
		ContextActionService.UnbindAction("GrappleHook");
		this.ballControlsConnection?.Disconnect();
	}
}
