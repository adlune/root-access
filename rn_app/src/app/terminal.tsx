import MaterialIcons from '@expo/vector-icons/MaterialIcons';
import { router } from 'expo-router';
import { useEffect, useRef, useState } from 'react';
import { Keyboard, KeyboardAvoidingView, Pressable, StyleSheet, type TextInputInstance, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { CrackMinigame } from '@/components/crack-minigame';
import { PromptRow } from '@/components/prompt-row';
import { QuickCommands } from '@/components/quick-commands';
import { TerminalOutput } from '@/components/terminal-output';
import { TerminalText } from '@/components/terminal-text';
import { TraceBar } from '@/components/trace-bar';
import { Colors } from '@/constants/theme';
import { connectedNode, isFinished } from '@/engine/gameState';
import { useGame } from '@/game/game-provider';
import { CHARS_PER_SECOND } from '@/game/settings';

/** The main game screen: status bar, scrollback, quick commands and the prompt. */
export default function TerminalScreen() {
  const { game, lines, linesAdded, settings, prompt, submit, finishCrack } = useGame();
  const [text, setText] = useState('');
  const input = useRef<TextInputInstance>(null);
  const node = connectedNode(game);

  // Hide the keyboard while the crack minigame is open, then bring it back.
  useEffect(() => {
    if (game.crackPort !== null) Keyboard.dismiss();
    else input.current?.focus();
  }, [game.crackPort]);

  function run(command: string) {
    submit(command);
    setText('');
  }

  function quickCommand(command: string) {
    if (command.endsWith(' ')) {
      setText(command);
      input.current?.focus();
    } else {
      run(command);
    }
  }

  const total = game.data.missions.length;
  const job = isFinished(game) ? 'ALL JOBS DONE' : `JOB ${game.missionIndex + 1}/${total}`;

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <KeyboardAvoidingView style={styles.container} behavior="padding">
        <View style={styles.header}>
          <Pressable onPress={() => router.back()} hitSlop={12} accessibilityLabel="Back">
            <MaterialIcons name="chevron-left" size={28} color={Colors.text} />
          </Pressable>
          <TerminalText
            numberOfLines={1}
            style={[styles.host, { color: node ? Colors.success : Colors.textDim }]}
          >
            {node ? `${node.hostname} (${node.ip})` : 'localhost'}
          </TerminalText>
          <TerminalText dim style={styles.job}>{job}</TerminalText>
          <Pressable onPress={() => router.push('/inbox')} hitSlop={12} accessibilityLabel="Inbox">
            <MaterialIcons name="mail-outline" size={24} color={Colors.text} />
          </Pressable>
        </View>
        {game.traceRemaining !== null && <TraceBar remaining={game.traceRemaining} total={node?.traceSeconds ?? 0} />}
        <View style={styles.divider} />
        <View style={styles.container}>
          <TerminalOutput lines={lines} linesAdded={linesAdded} charsPerSecond={CHARS_PER_SECOND[settings.textSpeed]} />
        </View>
        <QuickCommands onTap={quickCommand} />
        <PromptRow prompt={prompt} value={text} onChangeText={setText} onSubmit={() => run(text)} inputRef={input} />
      </KeyboardAvoidingView>

      {game.crackPort !== null && (
        <CrackMinigame key={game.crackPort} port={game.crackPort} onFinished={finishCrack} />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  host: {
    flex: 1,
  },
  job: {
    fontSize: 12,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: Colors.textDim,
  },
});
