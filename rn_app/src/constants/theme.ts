/**
 * Terminal look: monochrome black & white, same palette as the Flutter version
 * (flutter_app/lib/theme.dart). Color is reserved for functional text:
 * errors, success, warnings and the trace.
 */

import { Platform } from 'react-native';

import type { LineStyle } from '@/engine/gameState';

export const Colors = {
  background: '#0A0A0A',
  surface: '#161616',
  text: '#EDEDED',
  textDim: '#808080',
  danger: '#FF4D4D',
  success: '#7CFF6B',
  warning: '#FFB000',
} as const;

export const Fonts = {
  mono: Platform.select({ ios: 'Menlo', default: 'monospace' }),
};

export const Spacing = {
  one: 4,
  two: 8,
  three: 16,
  four: 24,
} as const;

export function colorForLine(style: LineStyle): string {
  switch (style) {
    case 'input':
    case 'normal':
      return Colors.text;
    case 'dim':
      return Colors.textDim;
    case 'error':
      return Colors.danger;
    case 'success':
      return Colors.success;
    case 'warning':
      return Colors.warning;
  }
}
