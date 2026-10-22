import { type ReactNode, useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';

import { Colors } from '@/constants/theme';
import { connectedNode } from '@/engine/gameState';
import { useGame } from '@/game/game-provider';

import { TerminalText } from './terminal-text';

/** The desktop's top bar: who and where you are, the trace (if any) and a clock. */
export function StatusBar({ leading }: { leading?: ReactNode }) {
  const { game } = useGame();
  const node = connectedNode(game);
  const trace = game.traceRemaining;
  return (
    <View style={styles.bar}>
      {leading}
      <TerminalText numberOfLines={1} style={[styles.small, styles.who, { color: node ? Colors.success : Colors.text }]}>
        {game.data.player.user}@{node?.hostname ?? game.data.player.hostname}
      </TerminalText>
      {trace !== null && (
        <TerminalText style={[styles.small, styles.trace, { color: trace <= 10 ? Colors.danger : Colors.warning }]}>
          TRACE {trace}s
        </TerminalText>
      )}
      <Clock />
    </View>
  );
}

function Clock() {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const timer = setInterval(() => setNow(new Date()), 15_000);
    return () => clearInterval(timer);
  }, []);
  const two = (n: number) => String(n).padStart(2, '0');
  return <TerminalText style={styles.small}>{two(now.getHours())}:{two(now.getMinutes())}</TerminalText>;
}

const styles = StyleSheet.create({
  bar: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: Colors.surface,
  },
  small: {
    fontSize: 12,
  },
  who: {
    flex: 1,
  },
  trace: {
    fontWeight: 'bold',
  },
});
