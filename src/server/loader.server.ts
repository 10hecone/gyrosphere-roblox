import { PhysicsService } from "@rbxts/services";

PhysicsService.RegisterCollisionGroup("Players");
PhysicsService.RegisterCollisionGroup("NoPlayers");
PhysicsService.CollisionGroupSetCollidable("Players", "Players", false);
PhysicsService.CollisionGroupSetCollidable("Players", "NoPlayers", false);
