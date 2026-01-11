import { CollectionService, Workspace } from "@rbxts/services";
import { Ball } from "../../../types/Ball";
import Remotes from "../../shared/remotes";

interface GrappleData {
	token: string;
	hookPart: BasePart;
	rope: RopeConstraint;
	attachement: Attachment;
	model: BasePart;
	clone: BasePart;
}

export class GrappleService {
	activeGrapples: Map<Player, GrappleData>;

	constructor() {
		this.activeGrapples = new Map<Player, GrappleData>();

		Remotes.Server.Get("GrappleHook").SetCallback((player: Player, position: Vector3) => {
			return this.grappleHook(player, position);
		});
		Remotes.Server.Get("UnGrappleHook").SetCallback((player: Player) => {
			return this.unGrappleHook(player);
		});
	}

	private getBallFromPlayer(player: Player): Ball | undefined {
		const ball = CollectionService.GetTagged(tostring(player.UserId))[0] as Ball | undefined;
		return ball;
	}
	
	createRope(hook: Vector3, grapple: BasePart, distance: number) {
		const hookPart = new Instance("Part");

		hookPart.Anchored = true;
		hookPart.CanCollide = false;
		hookPart.Transparency = 1;
		hookPart.Position = hook;
		hookPart.Parent = Workspace;

		const attachment0 = new Instance("Attachment");

		const attachement1 = new Instance("Attachment");

		attachment0.Parent = hookPart;
		attachement1.Parent = grapple;

		const rope = new Instance("RopeConstraint");

		rope.Visible = true;
		rope.Length = distance;

		rope.Attachment0 = attachment0;
		rope.Attachment1 = attachement1;
		rope.Parent = hookPart;
		return { rope, hookPart, attachement1 };
	}

	grappleHook(player: Player, position: Vector3) {
		if (this.activeGrapples.has(player)) return false;

		const ball = this.getBallFromPlayer(player);
		if (!ball || ball.PrimaryPart === undefined) return false;

		const character = player.Character;
		if (!character) return false;

		const distanceRope = (position.sub(ball.PrimaryPart.Position)).Magnitude
		if(distanceRope > 200) return false
		
		const grapple = ball.Interior.Rope.Grapple;
		const model = ball.Interior.Rope.GrappleModel;

		const distance = position.sub(grapple.Position).Magnitude * 0.9;

		const rope = this.createRope(position, grapple, distance);

		const clone = model.Clone() as BasePart;
		clone.ClearAllChildren();
		clone.Anchored = true;
		clone.CFrame = new CFrame(position);
		clone.Parent = Workspace;

		model.Transparency = 1;

		const token = tostring(player.UserId) + "_" + tostring(tick());

		const grappleData: GrappleData = {
			token: token,
			hookPart: rope.hookPart,
			rope: rope.rope,
			attachement: rope.attachement1,
			model: model,
			clone: clone,
		};

		this.activeGrapples.set(player, grappleData);

		const minLength = 17;
		const retractTime = 1.3;

		player.SetAttribute("isAttached", true);

		task.spawn(() => {
			const startLength = rope.rope.Length;
			let elapsed = 0;

			while (rope && rope.hookPart && elapsed < retractTime) {
				const delta = task.wait();
				elapsed += delta;
				const alpha = math.clamp(elapsed / retractTime, 0, 1);
				rope.rope.Length = startLength + (minLength - startLength) * alpha;
			}
			rope.rope.Length = minLength;
		});
		task.delay(15, () => {
			pcall(() => {
				if (this.activeGrapples.has(player) && this.activeGrapples.get(player)?.token === token) {
					this.unGrappleHook(player);
				}
			});
		});

		return true;
	}

	unGrappleHook(player: Player) {
		const grappleData = this.activeGrapples.get(player);

		player.SetAttribute("isAttached", false);

		if (!grappleData) return false;

		grappleData.attachement.Destroy();
		grappleData.rope.Destroy();
		grappleData.hookPart.Destroy();
		grappleData.clone.Destroy();
		grappleData.model.Transparency = 0;

		this.activeGrapples.delete(player);
		return true;
	}
}
