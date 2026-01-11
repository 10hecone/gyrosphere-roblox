import { Players, RunService, TweenService, UserInputService, Workspace } from "@rbxts/services";
import { ShiftLock } from "client/utils/ShiftLock";
import { CrossHairBall } from "../../../../types/CrossHairBall";
import { Ball } from "../../../../types/Ball";
import { ReplicatedStorage } from "@rbxts/services";

let rotating = false;
let currentTween: Tween | undefined;
let enabled: RBXScriptConnection | undefined = undefined;
let lastFieldOfView = 50;

export class CameraBall {
	ball: undefined | Ball;
	chb: CrossHairBall | undefined;

	constructor() {
		this.ball = undefined;
		this.chb = undefined;
	}

	private removeCrosshair() {
		this.chb?.Destroy();

		this.chb = undefined;
	}

	private mouseIcon(enable: boolean) {
		UserInputService.MouseIconEnabled = enable;
	}

	private setTweenTransparency(frame: Frame, state: boolean) {
		const tweenInfo = new TweenInfo(0.1);

		const hit = frame.FindFirstChild("Hit") as ImageButton | undefined;
		const stud = frame.FindFirstChild("Stud") as TextLabel | undefined;
		const pointer = frame.FindFirstChild("Pointer") as ImageButton | undefined;
		const border = frame.FindFirstChild("Border") as ImageButton | undefined;

		if (hit === undefined || pointer === undefined || border === undefined || stud === undefined) return;

		TweenService.Create(hit, tweenInfo, {
			ImageTransparency: state ? 0 : 1,
		}).Play();

		TweenService.Create(stud, tweenInfo, {
			TextTransparency: state ? 0 : 1,
		}).Play();

		TweenService.Create(pointer, tweenInfo, {
			ImageTransparency: state ? 1 : 0,
		}).Play();

		TweenService.Create(border, tweenInfo, {
			ImageTransparency: state ? 0 : 1,
		}).Play();
	}

	private numLerp(a: number, b: number, t: number): number {
		return a + (b - a) * t;
	}

	private updateFieldOfView(camera: Camera, deltaTime: number) {
		const ball = this.ball;
		if (!ball) return;
		const ballVelocity = ball.PrimaryPart!.AssemblyLinearVelocity;

		// Limitation de la magnitude pour le calcul du FOV
		const magnitude = math.min(ballVelocity.Magnitude, 80);

		// Proportion par rapport à la vitesse maximale
		const proportion = magnitude / 80;
		const newFOV = 50 + proportion * (65 - 50);

		// Mise à jour du FieldOfView avec interpolation
		camera.FieldOfView = this.numLerp(lastFieldOfView, newFOV, math.min(deltaTime * 4, 1));

		lastFieldOfView = camera.FieldOfView;
	}

	private setTweenRotation(state: boolean, uiElement: GuiObject) {
		if (state && !rotating) {
			rotating = true;

			task.spawn(() => {
				while (rotating) {
					const tweenInfo = new TweenInfo(1, Enum.EasingStyle.Linear);
					currentTween = TweenService.Create(uiElement, tweenInfo, {
						Rotation: uiElement.Rotation + 180,
					});

					currentTween.Play();
					currentTween.Completed.Wait();
				}
			});
		} else {
			rotating = false;

			if (currentTween) {
				currentTween.Cancel();
				currentTween = undefined;
			}
		}
	}

	static getAllGrappleFolders() {
		const grappleFolders: Folder[] = [];
		const descendants = Workspace.World.GetDescendants();

		for (const descendant of descendants) {
			if (descendant.IsA("Folder") && descendant.Name === "Grapple") {
				grappleFolders.push(descendant);
			}
		}

		return grappleFolders;
	}

	static canSimplyHook(camera: CFrame, root: CFrame): Vector3 | undefined {
		const getCanAttach = Workspace.Grapple.GetChildren();

		let minDist = math.huge;
		let closest = undefined;

		for (const canAttach of getCanAttach) {
			if (!canAttach.IsA("Part")) continue;
			const toPart = canAttach.Position.sub(root.Position);

			const t = toPart.Dot(camera.LookVector.Unit);

			if (t < 0 || t > 200) continue;

			const closestPoint = root.Position.add(camera.LookVector.Unit.mul(t));

			const dist = canAttach.Position.sub(closestPoint).Magnitude;

			if (dist > 60) continue;
			if (dist < minDist) {
				minDist = dist;
				closest = canAttach.Position;
			}
		}

		return closest;
	}

	static canHook(camera: CFrame, folder: Folder[]): RaycastResult | undefined {
		const raycastParams = new RaycastParams();
		raycastParams.FilterDescendantsInstances = [Workspace.Grapple, ...folder];
		raycastParams.FilterType = Enum.RaycastFilterType.Include;

		const direction = camera.LookVector.mul(200);
		const result = Workspace.Raycast(camera.Position, direction, raycastParams);
		return result;
	}

	private speedLine(ball: Ball) {
		const camera = Workspace.CurrentCamera;
		if (!camera) return;

		type SpeedLine = Part & {
			Attachment: Attachment & {
				ParticleEmitter: ParticleEmitter;
			};
		};

		let speedLine = Workspace.FindFirstChild("Speedlines") as SpeedLine;
		if (!speedLine) {
			const clone = ReplicatedStorage.Asset.Vfx.Speedlines.Speedlines.Clone();
			clone.Parent = Workspace;
			speedLine = clone;
		}

		const velocity = math.floor(ball.PrimaryPart?.AssemblyLinearVelocity.Magnitude ?? 0);

		const pos = camera.CFrame.Position.add(camera.CFrame.LookVector.mul(15.5));

		const y = math.clamp((velocity - 35) * 2, 0, 50);
		speedLine.Attachment.ParticleEmitter.Rate = y;
		speedLine.PivotTo(new CFrame(pos, pos.add(camera.CFrame.LookVector)));
	}
	private onStepped(dt: number, chb: ScreenGui, ball: Ball) {
		const camera = Workspace.CurrentCamera;
		if (camera === undefined) return;

		const frame = chb.FindFirstChild("Frame") as Frame;
		if (frame === undefined) return;

		const border = frame.FindFirstChild("Border") as ImageLabel;
		if (border === undefined) return;

		const stud = frame.FindFirstChild("Stud") as TextLabel | undefined;
		if (stud === undefined) return;

		const ballPrimaryPart = ball.PrimaryPart;

		if (!ballPrimaryPart) return;

		const canHook = CameraBall.canSimplyHook(camera.CFrame, ballPrimaryPart.CFrame);

		if (canHook) {
			stud.Visible = false;
			const isGrappled = Players.LocalPlayer.GetAttribute("isAttached");
			if (isGrappled === true) {
				this.setTweenRotation(true, border);
			} else {
				this.setTweenRotation(false, border);
				border.Rotation = 0;
			}
			this.setTweenTransparency(frame, true);
		} else {
			this.setTweenTransparency(frame, false);
		}
	}

	private addCrossHair(chb: ScreenGui) {
		chb.Enabled = true;
	}

	enable(ball: Ball) {
		this.chb = ReplicatedStorage.Asset.UI.CrossHairBall.Clone();
		this.chb.Parent = Players.LocalPlayer.WaitForChild("PlayerGui") as PlayerGui;
		this.addCrossHair(this.chb);
		enabled = RunService.Heartbeat.Connect((dt) => {
			if (this.chb === undefined) return enabled?.Disconnect();
			this.speedLine(ball);
			this.onStepped(dt, this.chb, ball);
		});
		this.mouseIcon(false);
		ShiftLock.Lock(true);

		// task.wait(1)
		const cam = Workspace.CurrentCamera as Camera;
		cam.CameraType = Enum.CameraType.Scriptable;

		const currentCFrame = cam.CFrame;
		const rotatedCFrame = currentCFrame.mul(CFrame.Angles(0, math.rad(90), 0));

		cam.CFrame = rotatedCFrame;

		task.wait();

		cam.CameraType = Enum.CameraType.Custom;
		// player.CameraMinZoomDistance = 25;
		// Workspace.Camera.FieldOfView = lastFieldOfView;
	}

	disable() {
		this.removeCrosshair();
		enabled?.Disconnect();
		this.mouseIcon(true);
		ShiftLock.Lock(false);
	}
}

export const grappleFolder = CameraBall.getAllGrappleFolders();
