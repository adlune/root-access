import { StyleSheet, View } from 'react-native';

import { Colors } from '@/constants/theme';

import { TerminalText } from './terminal-text';

/** Countdown bar shown while a machine is tracing you. Turns red near the end. */
export function TraceBar({ remaining, total }: { remaining: number; total: number }) {
  const color = remaining <= 10 ? Colors.danger : Colors.warning;
  const fraction = total === 0 ? 0 : remaining / total;
  return (
    <View style={styles.row}>
      <TerminalText style={[styles.label, { color }]}>TRACE</TerminalText>
      <View style={styles.track}>
        <View style={[styles.fill, { width: `${fraction * 100}%`, backgroundColor: color }]} />
      </View>
      <TerminalText style={{ color }}>{remaining}s</TerminalText>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  label: {
    fontWeight: 'bold',
  },
  track: {
    flex: 1,
    height: 6,
    backgroundColor: Colors.surface,
  },
  fill: {
    height: '100%',
  },
});
