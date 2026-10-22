/**
 * Terminal look for the React Native version (amber phosphor).
 * The Flutter version uses the same layout with a green palette.
 */

import { Platform } from 'react-native';

export const Colors = {
  background: '#0A0A0A',
  surface: '#141414',
  text: '#FFB000',
  textDim: '#8A6000',
  danger: '#FF4D4D',
  success: '#7CFF6B',
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
