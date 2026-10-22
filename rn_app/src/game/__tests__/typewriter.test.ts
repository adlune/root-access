import { describe, expect, test } from '@jest/globals';

import { line } from '../../engine/gameState';
import { advanceTyping, startTyping, visibleLines } from '../typewriter';

const output = [line('$ help', 'input'), line('0123456789'), line(''), line('abcde')];

describe('typewriter', () => {
  test('your command shows at once; output waits for time to pass', () => {
    const t = advanceTyping(startTyping(0), output, 4, 100, 0);
    expect(visibleLines(t, output, 4)).toEqual({ full: 1, partial: { line: output[1], text: '' } });
  });

  test('types at the given speed, carrying over to the next lines', () => {
    let t = advanceTyping(startTyping(0), output, 4, 100, 50); // 5 characters
    expect(visibleLines(t, output, 4).partial?.text).toBe('01234');

    t = advanceTyping(t, output, 4, 100, 80); // 8 more: finish line 2 (5), skip the empty line, 3 into line 4
    expect(visibleLines(t, output, 4)).toEqual({ full: 3, partial: { line: output[3], text: 'abc' } });

    t = advanceTyping(t, output, 4, 100, 1000);
    expect(t).toEqual(startTyping(4)); // all done, nothing left over
  });

  test('instant speed shows everything', () => {
    expect(advanceTyping(startTyping(0), output, 4, 0, 0)).toEqual(startTyping(4));
  });

  test('copes with lines that were cleared before they finished typing', () => {
    const t = advanceTyping(startTyping(0), [], 4, 100, 10); // `clear` emptied the screen
    expect(visibleLines(t, [], 4)).toEqual({ full: 0, partial: null });
  });
});
