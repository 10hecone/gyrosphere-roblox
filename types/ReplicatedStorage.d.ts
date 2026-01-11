interface ReplicatedStorage extends Instance {
	Gyro: Folder & {
		Ball: Model & {
			Exterior: Model & {
				Main: Folder & {
					["Sphere.001_Material.001"]: MeshPart & {
						WeldConstraint: WeldConstraint;
					};
					Door: Folder;
				};
				CollisionBall: Part & {
					LinearVelocity: Attachment;
					Attachment: Attachment;
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
					LV: Attachment;
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
			LinearVelocity: LinearVelocity;
			Events: Folder & {
				ToggleInputControlsRemoteEvent: RemoteEvent;
			};
			Scripts: Folder & {
				getPlayerFromSeat: ModuleScript;
				Client: Folder & {
					InputControls: ModuleScript & {
						stopBallMovement: ModuleScript;
						getVelocityVector: ModuleScript;
						["Ultrakill - Clink"]: Sound;
					};
					Camera: ModuleScript & {
						ShiftLock: ModuleScript;
						Config: ModuleScript;
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
			EnterPrompt: ProximityPrompt;
			DriverSeat: Seat & {
				WeldConstraint: WeldConstraint;
			};
			NoCollisionConstraints: Folder;
			Constraints: Folder & {
				BallSocketConstraint: BallSocketConstraint;
				LinearVelocity: VectorForce;
				DashVelocity: VectorForce;
				JumpVelocity: VectorForce;
				ControlAlignOrientation: AlignOrientation;
				ControlAngularVelocity: AngularVelocity;
			};
		};
	};
	TS: Folder & {
		remotes: ModuleScript;
	};
	Asset: Folder & {
		Vfx: Folder & {
			Speedlines: Model & {
				Speedlines: Part & {
					Attachment: Attachment & {
						ParticleEmitter: ParticleEmitter;
					};
				};
			};
			Eboulement: Part & {
				ParticleEmitter: ParticleEmitter;
			};
		};
		UI: Folder & {
			CrossHairBall: ScreenGui & {
				Frame: Frame & {
					Hit: ImageLabel;
					Stud: TextLabel;
					Pointer: ImageLabel;
					Border: ImageLabel;
					UIAspectRatioConstraint: UIAspectRatioConstraint;
				};
			};
		};
	};
	rbxts_include: Folder & {
		RuntimeLib: ModuleScript;
		Promise: ModuleScript;
		node_modules: Folder & {
			["@rbxts"]: Folder & {
				net: Folder & {
					out: ModuleScript & {
						definitions: ModuleScript & {
							ServerDefinitionBuilder: ModuleScript;
							NamespaceBuilder: ModuleScript;
							ClientDefinitionBuilder: ModuleScript;
							Types: ModuleScript;
						};
						messaging: Folder & {
							ExperienceBroadcastEvent: ModuleScript;
							MessagingService: ModuleScript;
						};
						client: ModuleScript & {
							ClientFunction: ModuleScript;
							ClientEvent: ModuleScript;
							ClientAsyncFunction: ModuleScript;
						};
						internal: ModuleScript & {
							validator: ModuleScript;
							tables: ModuleScript;
						};
						middleware: ModuleScript & {
							RateLimitMiddleware: ModuleScript & {
								throttle: ModuleScript;
							};
							LoggerMiddleware: ModuleScript;
							TypeCheckMiddleware: ModuleScript;
						};
						server: ModuleScript & {
							ServerEvent: ModuleScript;
							ServerAsyncFunction: ModuleScript;
							ServerFunction: ModuleScript;
							MiddlewareFunction: ModuleScript;
							NetServerScriptSignal: ModuleScript;
							CreateServerListener: ModuleScript;
							ServerMessagingEvent: ModuleScript;
							MiddlewareEvent: ModuleScript;
						};
					};
				};
				types: Folder & {
					include: Folder & {
						generated: Folder;
					};
				};
				["compiler-types"]: Folder & {
					types: Folder;
				};
				services: ModuleScript;
			};
		};
	};
}
