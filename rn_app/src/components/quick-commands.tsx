import { Pressable, ScrollView, StyleSheet } from 'react-native';

import { Colors } from '@/constants/theme';

import { TerminalText } from './terminal-text';

/** Typing on a phone is slow, so common commands are one tap away.
 *  Entries ending in a space need an argument: they fill the input instead of running. */
export const QUICK_COMMANDS = ['help', 'mail', 'scan', 'connect ', 'probe', 'ls', 'cd ', 'cat ', 'disconnect', 'hint'];

export function QuickCommands({ onTap }: { onTap: (command: string) => void }) {
  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      keyboardShouldPersistTaps="always"
      style={styles.bar}
      contentContainerStyle={styles.row}
    >
      {QUICK_COMMANDS.map((cmd) => (
        <Pressable
          key={cmd}
          onPress={() => onTap(cmd)}
          style={({ pressed }) => [styles.chip, pressed && styles.pressed]}
        >
          <TerminalText style={styles.label}>{cmd.trim()}</TerminalText>
        </Pressable>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  bar: {
    flexGrow: 0, // a horizontal ScrollView otherwise stretches to fill the screen's free height
  },
  row: {
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 8,
    paddingVertical: 6,
  },
  chip: {
    borderWidth: 1,
    borderColor: Colors.textDim,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: Colors.surface,
  },
  pressed: {
    backgroundColor: Colors.textDim,
  },
  label: {
    fontSize: 12,
    lineHeight: 16,
  },
});
