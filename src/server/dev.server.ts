import { RunService } from "@rbxts/services";

declare const _G: Record<string, unknown>;
declare global {
	interface _G {
		__DEV__?: boolean;
	}
}

export {};

if (RunService.IsStudio()) {
	_G.__DEV__ = true;
}
