// The terminal's typewriter effect as a pure function (Flutter keeps the same
// logic inside its TerminalOutput widget). New output types out at a set
// speed; your own commands (style 'input') appear at once.

import type { OutputLine } from '../engine/gameState';

export type Typing = {
  done: number; // lines fully shown, counted like linesAdded
  chars: number; // characters typed so far of the next line
  budget: number; // characters we may type but haven't yet
};

export const startTyping = (linesAdded: number): Typing => ({ done: linesAdded, chars: 0, budget: 0 });

/** Moves the typewriter forward by `elapsedMs` at `charsPerSecond` (0 = instant). */
export function advanceTyping(
  t: Typing,
  lines: OutputLine[],
  linesAdded: number,
  charsPerSecond: number,
  elapsedMs: number,
): Typing {
  if (charsPerSecond === 0) return startTyping(linesAdded);

  let { done, chars, budget } = t;
  if (linesAdded - done > lines.length) {
    // Lines were cleared or scrolled away before they finished typing.
    done = linesAdded - lines.length;
    chars = 0;
  }

  budget += (elapsedMs / 1000) * charsPerSecond;
  while (linesAdded - done > 0) {
    const line = lines[lines.length - (linesAdded - done)];
    const left = line.text.length - chars;
    if (line.style === 'input' || budget >= left) {
      if (line.style !== 'input') budget -= left;
      done++;
      chars = 0;
    } else {
      const typed = Math.floor(budget);
      chars += typed;
      budget -= typed;
      break;
    }
  }
  if (done === linesAdded) budget = 0;
  return { done, chars, budget };
}

/** How many lines to show fully, and the partly typed one (if any). */
export function visibleLines(t: Typing, lines: OutputLine[], linesAdded: number) {
  const pending = Math.min(linesAdded - t.done, lines.length);
  const full = lines.length - pending;
  const partial = pending > 0 ? { line: lines[full], text: lines[full].text.slice(0, t.chars) } : null;
  return { full, partial };
}
