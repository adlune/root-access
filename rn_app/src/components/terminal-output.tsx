import { useEffect, useRef, useState } from 'react';
import { FlatList, Pressable, StyleSheet } from 'react-native';

import { colorForLine } from '@/constants/theme';
import type { OutputLine } from '@/engine/gameState';
import { type Typing, advanceTyping, startTyping, visibleLines } from '@/game/typewriter';

import { TerminalText } from './terminal-text';

type Props = {
  lines: OutputLine[];
  linesAdded: number; // total ever printed; tells us which lines are new
  charsPerSecond: number; // 0 = instant
};

/** The scrollback, colored by style, with a typewriter effect.
 *  Your own commands appear at once; tapping the output skips to the end. */
export function TerminalOutput({ lines, linesAdded, charsPerSecond }: Props) {
  const list = useRef<FlatList<OutputLine>>(null);
  const [typing, setTyping] = useState<Typing>(() => startTyping(linesAdded));

  // Catch up with new lines without waiting for a tick: echoes (and, at
  // 'instant' speed, everything) show at once. Pure, so it's fine during render.
  const current = advanceTyping(typing, lines, linesAdded, charsPerSecond, 0);

  // Type out the rest, about once per frame.
  const busy = current.done < linesAdded;
  useEffect(() => {
    if (!busy) return;
    let last = Date.now();
    const timer = setInterval(() => {
      const now = Date.now();
      const elapsed = now - last; // measure before the (lazily run) updater below
      last = now;
      setTyping((t) => advanceTyping(t, lines, linesAdded, charsPerSecond, elapsed));
    }, 16);
    return () => clearInterval(timer);
  }, [busy, lines, linesAdded, charsPerSecond]);

  const { full, partial } = visibleLines(current, lines, linesAdded);
  const shown = partial ? [...lines.slice(0, full), { ...partial.line, text: `${partial.text}█` }] : lines.slice(0, full);

  return (
    <Pressable style={styles.container} onPress={() => setTyping(startTyping(linesAdded))}>
      <FlatList
        ref={list}
        data={shown}
        keyExtractor={(_, i) => String(i)}
        contentContainerStyle={styles.content}
        onContentSizeChange={() => list.current?.scrollToEnd({ animated: false })}
        keyboardShouldPersistTaps="handled"
        renderItem={({ item }) => (
          <TerminalText style={[styles.line, { color: colorForLine(item.style) }, item.style === 'input' && styles.input]}>
            {item.text}
          </TerminalText>
        )}
      />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  content: {
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  line: {
    fontSize: 13,
    lineHeight: 18,
  },
  input: {
    fontWeight: 'bold',
  },
});
