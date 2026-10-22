import { describe, expect, test } from '@jest/globals';

import { CODE_LENGTH, MAX_ATTEMPTS, type DigitHint, isSolved, randomCode, scoreGuess } from '../crack-code';

describe('crack code', () => {
  test('scores each digit as correct, higher or lower', () => {
    expect(scoreGuess('472', '555')).toEqual(['lower', 'higher', 'lower']);
    expect(scoreGuess('472', '472')).toEqual(['correct', 'correct', 'correct']);
    expect(isSolved(scoreGuess('472', '472'))).toBe(true);
    expect(isSolved(scoreGuess('472', '470'))).toBe(false);
  });

  test('random codes have the right length and only digits', () => {
    for (let i = 0; i < 50; i++) expect(randomCode()).toMatch(new RegExp(`^\\d{${CODE_LENGTH}}$`));
    expect(randomCode(() => 0)).toBe('000');
    expect(randomCode(() => 0.999)).toBe('999');
  });

  test('searching each digit by halves cracks every possible PIN in time', () => {
    let worst = 0;
    for (let n = 0; n < 10 ** CODE_LENGTH; n++) {
      const code = String(n).padStart(CODE_LENGTH, '0');
      const low = Array<number>(CODE_LENGTH).fill(0);
      const high = Array<number>(CODE_LENGTH).fill(9);
      let hints: DigitHint[];
      let attempts = 0;
      do {
        const guess = low.map((lo, i) => Math.floor((lo + high[i]) / 2)).join('');
        hints = scoreGuess(code, guess);
        attempts++;
        hints.forEach((h, i) => {
          const g = Number(guess[i]);
          if (h === 'higher') low[i] = g + 1;
          if (h === 'lower') high[i] = g - 1;
          if (h === 'correct') low[i] = high[i] = g;
        });
      } while (!isSolved(hints));
      worst = Math.max(worst, attempts);
    }
    expect(worst).toBe(4);
    expect(worst).toBeLessThanOrEqual(MAX_ATTEMPTS);
  });
});
