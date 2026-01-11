import { CollectionService, Players, ReplicatedStorage, Workspace } from "@rbxts/services";
import { Ball } from "../../../types/Ball";
import Remotes from "../../shared/remotes";

const ballOriginel = ReplicatedStorage.Gyro.FindFirstChild("Ball") as Ball | undefined;

export class BallService {
	private setCollisionConstraint(ball: Ball, character: Model) {
		for (const instance of character?.GetDescendants()) {
			if (!instance.IsA("BasePart")) continue;
			const noCollisionConstraint = new Instance("NoCollisionConstraint");
			noCollisionConstraint.Part0 = ball.Exterior.CollisionBall;
			noCollisionConstraint.Part1 = instance;
			noCollisionConstraint.Parent = ball.NoCollisionConstraints;
		}
	}

	private getBallFolder(): Folder {
		let balls = CollectionService.GetTagged("Balls");

		if (balls.size() === 0) {
			balls[0] = new Instance("Folder");
			balls[0].Name = "Balls";
			balls[0].Parent = Workspace;
			balls[0].AddTag("Balls");
		}

		return balls[0] as Folder;
	}

	private createBall(player: Player, spawnCFrame?: CFrame): Ball | false {
		if (CollectionService.GetTagged(tostring(player.UserId)).size() > 0) return false;
		if (ballOriginel === undefined) return false;

		const ball = ballOriginel.Clone();

		let balls = this.getBallFolder();

		ball.Name = `Ball_${player.Name}_${player.UserId}`;

		ball.AddTag(tostring(player.UserId));

		(ball.PrimaryPart as BasePart).CollisionGroup = "Players";

		ball.GetDescendants().forEach((descendant) => {
			if (!descendant.IsA("BasePart")) return;
			descendant.SetAttribute("UserId", tostring(player.UserId));
		});

		if (spawnCFrame) {
			const rotation = CFrame.Angles(0, math.rad(-90), 0);

			ball.PivotTo(new CFrame(spawnCFrame.Position).mul(rotation));
		}

		player.AddTag("Ball");
		ball.Parent = balls;

		if (ball.PrimaryPart) {
			ball.PrimaryPart.SetNetworkOwner(player);
		}

		return ball;
	}

	private hasCharacterAndHumanoid(player: Player): (Model & { Humanoid: Humanoid }) | false {
		const character = player.Character;
		if (character === undefined) return false;

		const humanoid = character.FindFirstChildWhichIsA("Humanoid") as Humanoid | undefined;

		if (!humanoid || humanoid.Health <= 0) return false;

		return character as Model & { Humanoid: Humanoid };
	}

	connectSpawner(part: Part) {
		part.Touched.Connect((part) => {
			const player = Players.GetPlayerFromCharacter(part.Parent);
			if (!player) return;

			this.equip(player);
		});
	}

	equip(player: Player, spawnCFrame?: CFrame) {
		const character = this.hasCharacterAndHumanoid(player);
		if (character === false) return;

		const humanoid = character.Humanoid;

		const ball = this.createBall(player, spawnCFrame);

		if (!ball) return;

		const driverSeat = ball.DriverSeat;

		if (driverSeat.Occupant !== undefined) return;

		driverSeat.Sit(humanoid);
		this.setCollisionConstraint(ball, character);

		humanoid.Died.Once(() => {
			this.unequip(player);
		});

		Remotes.Server.Get("Ball").SendToPlayer(player, true, ball);
	}

	unequip(player: Player) {
		Remotes.Server.Get("Ball").SendToPlayer(player, false, undefined);

		player.RemoveTag("Ball");
		const ball = CollectionService.GetTagged(tostring(player.UserId))[0] as Ball | undefined;
		if (!ball) return;

		const driverSeat = ball.FindFirstChild("DriverSeat") as VehicleSeat | undefined;

		if (!driverSeat) return;
		const seatDirection = driverSeat.CFrame.LookVector.Unit.mul(new Vector3(1, 0, 1));

		let stateConnection = driverSeat.Occupant?.StateChanged.Once((old) => {
			if (old !== Enum.HumanoidStateType.Seated) return;
			if (ball?.Parent === undefined) return;
			const exterior = ball.FindFirstChild("Exterior");
			if (exterior) {
				(driverSeat.Occupant?.Parent as Model).PivotTo(
					driverSeat.CFrame.sub(seatDirection.mul(ball.Exterior.CollisionBall.Size.X)),
				);
			}
			ball.NoCollisionConstraints.ClearAllChildren();
			stateConnection?.Disconnect();
		});

		const seatWeld = driverSeat.FindFirstChild("SeatWeld");
		seatWeld?.Destroy();
		ball.Destroy();
	}
}
