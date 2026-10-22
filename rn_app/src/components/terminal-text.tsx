import { StyleSheet, Text, type TextProps } from 'react-native';

import { Colors, Fonts } from '@/constants/theme';

/** Monospace text in the terminal color. Pass `dim` for secondary text. */
export function TerminalText({ style, dim, ...rest }: TextProps & { dim?: boolean }) {
  return <Text style={[styles.text, dim && styles.dim, style]} {...rest} />;
}

const styles = StyleSheet.create({
  text: {
    color: Colors.text,
    fontFamily: Fonts.mono,
    fontSize: 14,
    lineHeight: 20,
  },
  dim: {
    color: Colors.textDim,
  },
});
