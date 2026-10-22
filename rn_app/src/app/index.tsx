import { Link } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { Screen } from '@/components/screen';
import { TerminalText } from '@/components/terminal-text';

// Boot / title screen. TODO (Day 9): boot-sequence typewriter animation.
export default function BootScreen() {
  return (
    <Screen>
      <View style={styles.center}>
        <TerminalText style={styles.title}>ROOT_ACCESS</TerminalText>
        <TerminalText dim>v0.1 // react native build</TerminalText>
      </View>
      <Link href="/terminal" style={styles.link}>
        <TerminalText>{'> start session'}</TerminalText>
      </Link>
      <Link href="/inbox" style={styles.link}>
        <TerminalText>{'> open inbox'}</TerminalText>
      </Link>
    </Screen>
  );
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  title: {
    fontSize: 32,
    lineHeight: 40,
    fontWeight: 'bold',
  },
  link: {
    paddingVertical: 8,
  },
});
