import type { Ref } from 'react';
import { StyleSheet, TextInput, type TextInputInstance, View } from 'react-native';

import { Colors, Fonts } from '@/constants/theme';

import { TerminalText } from './terminal-text';

type Props = {
  prompt: string;
  value: string;
  onChangeText: (text: string) => void;
  onSubmit: () => void;
  inputRef: Ref<TextInputInstance>;
};

/** The prompt and the command input. */
export function PromptRow({ prompt, value, onChangeText, onSubmit, inputRef }: Props) {
  return (
    <View style={styles.row}>
      <TerminalText style={styles.prompt}>{prompt}</TerminalText>
      <TextInput
        ref={inputRef}
        value={value}
        onChangeText={onChangeText}
        onSubmitEditing={onSubmit}
        submitBehavior="submit" // keep the keyboard open after each command
        autoFocus
        // Terminal input: no autocorrect, suggestions or auto-capitals.
        autoCorrect={false}
        autoCapitalize="none"
        spellCheck={false}
        keyboardType="visible-password"
        returnKeyType="send"
        cursorColor={Colors.text}
        selectionColor={Colors.textDim}
        style={styles.input}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    backgroundColor: Colors.surface,
  },
  prompt: {
    fontWeight: 'bold',
    fontSize: 13,
  },
  input: {
    flex: 1,
    color: Colors.text,
    fontFamily: Fonts.mono,
    fontSize: 13,
    paddingVertical: 10,
  },
});
