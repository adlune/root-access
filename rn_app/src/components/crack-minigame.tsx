import { useEffect, useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';

import { Colors } from '@/constants/theme';
import { CODE_LENGTH, type DigitHint, MAX_ATTEMPTS, isSolved, randomCode, scoreGuess } from '@/game/crack-code';

import { TerminalText } from './terminal-text';

type Props = {
  port: number;
  onFinished: (success: boolean) => void;
  code?: string; // fixed code for testing; random otherwise
};

type Guess = { digits: string; hints: DigitHint[] };

const HINT_SYMBOL: Record<DigitHint, string> = { correct: '●', higher: '▲', lower: '▼' };
const HINT_COLOR: Record<DigitHint, string> = { correct: Colors.success, higher: Colors.text, lower: Colors.text };
const KEYS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'del', '0', 'ok'];

/** React Native's crack minigame: brute-force a PIN with higher/lower hints. */
export function CrackMinigame({ port, onFinished, code: fixedCode }: Props) {
  const [code] = useState(() => fixedCode ?? randomCode());
  const [guesses, setGuesses] = useState<Guess[]>([]);
  const [entry, setEntry] = useState('');
  const [result, setResult] = useState<boolean | null>(null);

  // Show the result for a moment before closing.
  useEffect(() => {
    if (result === null) return;
    const timer = setTimeout(() => onFinished(result), 900);
    return () => clearTimeout(timer);
  }, [result, onFinished]);

  function press(key: string) {
    if (result !== null) return;
    if (key === 'del') return setEntry((e) => e.slice(0, -1));
    if (key !== 'ok') return setEntry((e) => (e.length < CODE_LENGTH ? e + key : e));
    if (entry.length < CODE_LENGTH) return;

    const hints = scoreGuess(code, entry);
    const next = [...guesses, { digits: entry, hints }];
    setGuesses(next);
    setEntry('');
    if (isSolved(hints)) setResult(true);
    else if (next.length >= MAX_ATTEMPTS) setResult(false);
  }

  const status =
    result === true ? 'ACCESS GRANTED' : result === false ? `LOCKED OUT. PIN was ${code}` : `attempts left: ${MAX_ATTEMPTS - guesses.length}`;

  return (
    <View style={styles.backdrop}>
      <View style={styles.card}>
        <TerminalText style={styles.title}>BRUTE-FORCING PORT {port}</TerminalText>
        <TerminalText dim style={styles.center}>
          Guess the {CODE_LENGTH}-digit PIN. ▲ higher ▼ lower ● correct
        </TerminalText>

        <View style={styles.history}>
          {guesses.map((g, i) => (
            <View key={i} style={styles.guessRow}>
              <TerminalText style={styles.digits}>{g.digits.split('').join(' ')}</TerminalText>
              <TerminalText style={styles.digits}>
                {g.hints.map((h, j) => (
                  <TerminalText key={j} style={[styles.digits, { color: HINT_COLOR[h] }]}>
                    {HINT_SYMBOL[h]}{j < g.hints.length - 1 ? ' ' : ''}
                  </TerminalText>
                ))}
              </TerminalText>
            </View>
          ))}
          {result === null && (
            <TerminalText style={[styles.digits, styles.entry]}>
              {entry.padEnd(CODE_LENGTH, '_').split('').join(' ')}
            </TerminalText>
          )}
        </View>

        <TerminalText
          style={[styles.center, result === true && { color: Colors.success }, result === false && { color: Colors.danger }]}
        >
          {status}
        </TerminalText>

        <View style={styles.keypad}>
          {KEYS.map((key) => (
            <Pressable
              key={key}
              onPress={() => press(key)}
              style={({ pressed }) => [styles.key, pressed && styles.keyPressed]}
              accessibilityLabel={key === 'del' ? 'delete' : key === 'ok' ? 'submit guess' : key}
            >
              <TerminalText style={styles.keyLabel}>{key === 'del' ? '⌫' : key === 'ok' ? '↵' : key}</TerminalText>
            </Pressable>
          ))}
        </View>

        <Pressable onPress={() => result === null && setResult(false)} style={styles.abort}>
          <TerminalText dim>abort</TerminalText>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    ...StyleSheet.absoluteFill,
    backgroundColor: 'rgba(0,0,0,0.85)',
    justifyContent: 'center',
    padding: 24,
  },
  card: {
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.text,
    padding: 20,
    gap: 12,
  },
  title: {
    fontSize: 18,
    lineHeight: 24,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  center: {
    textAlign: 'center',
    fontSize: 12,
  },
  history: {
    alignItems: 'center',
    gap: 4,
    minHeight: 40,
  },
  guessRow: {
    flexDirection: 'row',
    gap: 24,
  },
  digits: {
    fontSize: 20,
    lineHeight: 28,
  },
  entry: {
    fontWeight: 'bold',
  },
  keypad: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    rowGap: 8,
  },
  key: {
    width: '31%',
    borderWidth: 1,
    borderColor: Colors.text,
    paddingVertical: 12,
    alignItems: 'center',
  },
  keyPressed: {
    backgroundColor: Colors.textDim,
  },
  keyLabel: {
    fontSize: 20,
    lineHeight: 26,
  },
  abort: {
    alignSelf: 'center',
    padding: 8,
  },
});
