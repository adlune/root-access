// Player settings. Port of flutter_app/lib/settings.dart.

export type TextSpeed = 'instant' | 'fast' | 'classic';

export const TEXT_SPEEDS: TextSpeed[] = ['instant', 'fast', 'classic'];

/** How fast terminal output types out (0 = show everything at once). */
export const CHARS_PER_SECOND: Record<TextSpeed, number> = { instant: 0, fast: 1500, classic: 400 };

export type Settings = {
  textSpeed: TextSpeed;
  haptics: boolean;
};

export const DEFAULT_SETTINGS: Settings = { textSpeed: 'fast', haptics: true };
