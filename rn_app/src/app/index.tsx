import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { Alert, Pressable, StyleSheet, View } from 'react-native';

import { Screen } from '@/components/screen';
import { TerminalText } from '@/components/terminal-text';
import { isFinished } from '@/engine/gameState';
import { useGame } from '@/game/game-provider';

const BOOT_LINES = [
  'ROOT/OS bootloader v0.1',
  'cpu0: entropy-vm x86_64 @ 2.6GHz',
  'memory check ............ 4096 MB ok',
  'mounting /home/rookie ... ok',
  'starting netd ........... ok',
  'starting traced ......... ok',
  'loading entropy client .. ok',
  'handshake entropy.net ... ok',
  '',
  'welcome back, rookie.',
];
const LINE_DELAY_MS = 140;

/** First screen: a fake boot sequence (once per launch, tap to skip), then the main menu. */
export default function MainMenu() {
  const { ready, game, progress, newGame, bootShown, markBootShown } = useGame();
  const [shown, setShown] = useState(bootShown ? BOOT_LINES.length : 1);
  const booting = shown < BOOT_LINES.length;

  useEffect(() => {
    if (!booting) {
      markBootShown();
      return;
    }
    const timer = setInterval(() => setShown((n) => n + 1), LINE_DELAY_MS);
    return () => clearInterval(timer);
  }, [booting, markBootShown]);

  function startNewGame() {
    if (!progress) return router.push('/desktop');
    Alert.alert('Start a new game?', 'Your finished jobs and saved files are erased.', [
      { text: 'cancel', style: 'cancel' },
      {
        text: 'erase',
        style: 'destructive',
        onPress: () => {
          newGame();
          router.push('/desktop');
        },
      },
    ]);
  }

  function about() {
    Alert.alert(
      'ROOT_ACCESS v0.1',
      'A Hacknet-style terminal game, built twice: in Flutter and in React Native.\n\n' +
        'Every machine, IP and password is fictional, and nothing here touches a real network. ' +
        "Type 'learn' in the terminal to read about the real ideas behind each command.",
    );
  }

  if (booting) {
    return (
      <Pressable style={styles.fill} onPress={() => setShown(BOOT_LINES.length)}>
        <Screen>
          <View style={styles.fill}>
            {BOOT_LINES.slice(0, shown).map((text, i) => (
              <TerminalText key={i} style={styles.bootLine}>{text}</TerminalText>
            ))}
          </View>
          <TerminalText dim style={styles.center}>tap to skip</TerminalText>
        </Screen>
      </Pressable>
    );
  }

  const total = game.data.missions.length;
  return (
    <Screen>
      <View style={styles.title}>
        <TerminalText style={styles.logo}>ROOT_ACCESS</TerminalText>
        <TerminalText dim>v0.1 // react native build</TerminalText>
        <TerminalText dim style={styles.progress}>
          {!ready ? 'loading...' : isFinished(game) ? 'all jobs complete' : `jobs complete: ${game.completed.length}/${total}`}
        </TerminalText>
      </View>
      {ready && (
        <>
          {progress && <MenuItem label="> continue" onPress={() => router.push('/desktop')} />}
          <MenuItem label="> new game" onPress={startNewGame} />
          <MenuItem label="> settings" onPress={() => router.push('/settings')} />
          <MenuItem label="> about" onPress={about} />
        </>
      )}
    </Screen>
  );
}

function MenuItem({ label, onPress }: { label: string; onPress: () => void }) {
  return (
    <Pressable onPress={onPress} style={styles.item}>
      <TerminalText>{label}</TerminalText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  fill: {
    flex: 1,
  },
  bootLine: {
    fontSize: 13,
  },
  center: {
    textAlign: 'center',
    fontSize: 12,
  },
  title: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  logo: {
    fontSize: 32,
    lineHeight: 40,
    fontWeight: 'bold',
  },
  progress: {
    marginTop: 24,
    fontSize: 12,
  },
  item: {
    paddingVertical: 10,
  },
});
