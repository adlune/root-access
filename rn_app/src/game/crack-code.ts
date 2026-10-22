// Rules for React Native's crack minigame (code guess). Flutter uses a tap-timing game.
// Guess a PIN; after each guess every digit says correct, higher or lower.
// Searching each digit by halves (start at 5) always wins within 4 guesses.

export const CODE_LENGTH = 3;
export const MAX_ATTEMPTS = 5;

export type DigitHint = 'correct' | 'higher' | 'lower';

export function randomCode(random: () => number = Math.random): string {
  return Array.from({ length: CODE_LENGTH }, () => Math.floor(random() * 10)).join('');
}

/** For each digit of `guess`: is the real digit the same, higher or lower? */
export function scoreGuess(code: string, guess: string): DigitHint[] {
  return [...guess].map((g, i) => (g === code[i] ? 'correct' : code[i] > g ? 'higher' : 'lower'));
}

export function isSolved(hints: DigitHint[]): boolean {
  return hints.every((h) => h === 'correct');
}
