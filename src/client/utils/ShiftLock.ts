import { UserInputService, Players, RunService } from "@rbxts/services";

const player = Players.LocalPlayer;
let shiftLockEnabled = false;

UserInputService.InputBegan.Connect((input, gameProcessed) => {
	if (gameProcessed) return;

	if (input.KeyCode === Enum.KeyCode.LeftShift || input.KeyCode === Enum.KeyCode.RightShift) {
		const playerGui = Players.LocalPlayer.FindFirstChild("PlayerGui");
		if (!playerGui) return;
		const shiftLockGui = playerGui.FindFirstChild("ShiftLock") as ScreenGui | undefined;
		if (!shiftLockGui) return;
		const shiftLockButton = shiftLockGui.FindFirstChildWhichIsA("GuiButton") as GuiButton | undefined;
		if (!shiftLockButton) return;

		if (shiftLockButton.Modal === false) {
			shiftLockButton.Modal = true;
			UserInputService.MouseIconEnabled = true;
		} else {
			shiftLockButton.Modal = false;
			UserInputService.MouseIconEnabled = false;
		}
	}
});

export class ShiftLock {
	static Lock(active: boolean) {
		const character = player.Character || player.CharacterAdded.Wait()[0];

		const humanoid = character.FindFirstChild("Humanoid") as Humanoid | undefined;

		if (!humanoid) return;

		if (active) {
			shiftLockEnabled = true;
			humanoid.CameraOffset = new Vector3(0, 3.5, -3);
			humanoid.AutoRotate = false;

			RunService.BindToRenderStep("ShiftLock", Enum.RenderPriority.Character.Value, () => {
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
			});
		} else {
			shiftLockEnabled = false;
			humanoid.CameraOffset = new Vector3(0, 0, 0);
			RunService.UnbindFromRenderStep("ShiftLock");
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
			humanoid.AutoRotate = true;
		}
	}
}
