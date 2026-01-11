export type Ball = Model & {
	Exterior: Model & {
		Main: Folder & {
			["Sphere.001_Material.001"]: MeshPart & {
				WeldConstraint: WeldConstraint;
			};
			Door: Folder;
		};
		CollisionBall: Part & {
			LinearVelocity: Attachment;
			BallSocketAttachment0: Attachment;
			AngularVelocityAttachment0: Attachment;
		};
	};
	AnimSaves: ObjectValue;
	Interior: Model & {
		AnimationController: AnimationController & {
			Animator: Animator;
		};
		["Cylinder.004_Material.003"]: MeshPart & {
			WeldConstraint: WeldConstraint;
		};
		Rope: Folder & {
			["Cylinder.011_Material.010"]: MeshPart & {
				WeldConstraint: WeldConstraint;
			};
			["Cylinder.006_Material.003"]: MeshPart & {
				WeldConstraint: WeldConstraint;
			};
			["Cylinder.009_Material.008"]: MeshPart & {
				WeldConstraint: WeldConstraint;
			};
			["Sphere.004_Material.008"]: MeshPart & {
				WeldConstraint: WeldConstraint;
			};
			GrappleModel: MeshPart & {
				WeldConstraint: WeldConstraint;
			};
			["Cylinder.008_Material.003"]: MeshPart & {
				WeldConstraint: WeldConstraint;
			};
			["Cylinder.007_Material.008"]: MeshPart & {
				WeldConstraint: WeldConstraint;
			};
			Grapple: Part & {
				WeldConstraint: WeldConstraint;
			};
			["Plane_Material.003"]: MeshPart & {
				WeldConstraint: WeldConstraint;
			};
		};
		["Circle_Material.003"]: MeshPart & {
			WeldConstraint: WeldConstraint;
		};
		InteriorPrimary: Part & {
			AlignOrientationAttachment: Attachment;
			BallSocketAttachment1: Attachment;
		};
		AnimSaves: ObjectValue;
		["Seat 1"]: Folder & {
			Dossier_Contour: MeshPart & {
				["Cylinder_Material.003"]: Motor6D;
				["Cylinder.005_Material.003"]: Motor6D;
				WeldConstraint: WeldConstraint;
			};
			AppuiTete_Contour: MeshPart & {
				WeldConstraint: WeldConstraint;
			};
			AppuiTete_Center: MeshPart & {
				WeldConstraint: WeldConstraint;
			};
			Trigger: Folder & {
				Left: Folder & {
					["Cylinder.001_Material.003"]: MeshPart & {
						WeldConstraint: WeldConstraint;
					};
					["Cylinder.003_Material.007"]: MeshPart & {
						WeldConstraint: WeldConstraint;
					};
					["Cylinder.012_Material.003"]: MeshPart & {
						WeldConstraint: WeldConstraint;
					};
					["Cylinder_Material.003"]: MeshPart;
					["Cylinder.002_Material.007"]: MeshPart & {
						WeldConstraint: WeldConstraint;
					};
				};
				Right: Folder & {
					["Cylinder.014_Material.003"]: MeshPart & {
						WeldConstraint: WeldConstraint;
					};
					["Cylinder.005_Material.003"]: MeshPart;
					["Cylinder.016_Material.007"]: MeshPart & {
						WeldConstraint: WeldConstraint;
					};
					["Cylinder.015_Material.007"]: MeshPart & {
						WeldConstraint: WeldConstraint;
					};
					["Cylinder.013_Material.003"]: MeshPart & {
						WeldConstraint: WeldConstraint;
					};
				};
			};
			Dossier_Center: MeshPart & {
				WeldConstraint: WeldConstraint;
			};
		};
	};
	ExitPrompt: ProximityPrompt;
	Events: Folder & {
		ToggleInputControlsRemoteEvent: RemoteEvent;
	};
	Constraints: Folder & {
		BallSocketConstraint: BallSocketConstraint;
		LinearVelocity: LinearVelocity;
		JumpVelocity: LinearVelocity;
		ControlAlignOrientation: AlignOrientation;
		ControlAngularVelocity: AngularVelocity;
	};
	EnterPrompt: ProximityPrompt;
	DriverSeat: Seat & {
		WeldConstraint: WeldConstraint;
	};
	NoCollisionConstraints: Folder;
	Scripts: Folder & {
		getPlayerFromSeat: ModuleScript;
		Client: Folder & {
			InputControls: ModuleScript & {
				getVelocityVector: ModuleScript;
				stopBallMovement: ModuleScript;
			};
			Camera: ModuleScript & {
				ShiftLock: ModuleScript;
				Config: ModuleScript;
				CrossHairBall: ScreenGui & {
					Frame: Frame & {
						Pointer: ImageLabel;
						Border: ImageLabel;
						Hit: ImageLabel;
					};
				};
				numLerp: ModuleScript;
			};
			ClientController: Script & {
				setJumpingEnabled: ModuleScript;
			};
		};
		Server: Folder & {
			Occupant: Script & {
				enterBall: ModuleScript;
				exitBall: ModuleScript;
			};
		};
	};
}
