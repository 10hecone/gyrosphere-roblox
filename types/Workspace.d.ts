interface Workspace extends Model {
	Ball: Model & {
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
	};
	Camera: Camera;
	Grapple: Folder;
	World: Folder & {
		Part: Part;
		World1: Folder;
		SpawnLocation: SpawnLocation;
		Build: Model & {
			DynamicOutlinePart: Part & {
				SurfaceGui: SurfaceGui & {
					Frame: Frame & {
						["1"]: Frame;
						["4"]: Frame;
						["3"]: Frame;
						["2"]: Frame;
					};
				};
				Texture: Texture;
			};
		};
	};
}
