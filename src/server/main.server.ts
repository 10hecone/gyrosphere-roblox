import { BallService } from "./services/BallService";
import { CollectionService, Players, Workspace } from "@rbxts/services";

import { GrappleService } from "./services/GrappleService";

const bs = new BallService();
new GrappleService();

Players.PlayerAdded.Connect((ply) => {
	ply.CharacterAdded.Connect((char) => {
		task.wait()
		char.GetDescendants().forEach((descendant) => {
			if (!descendant.IsA("BasePart")) return;
			descendant.CollisionGroup = "Players";
		});
		
		let spawnLocation = CollectionService.GetTagged("SpawnLocation")[0] as SpawnLocation | undefined;
		if (!spawnLocation) {
			spawnLocation = Workspace.World.SpawnLocation as SpawnLocation;
		}
		bs.equip(ply, spawnLocation.CFrame);
	});
});

Players.PlayerRemoving.Connect((ply) => {
	bs.unequip(ply);
});
