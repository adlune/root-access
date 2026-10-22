import MaterialIcons from '@expo/vector-icons/MaterialIcons';
import { router } from 'expo-router';
import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';

import { Colors } from '@/constants/theme';

import { TerminalText } from './terminal-text';

/** Title bar for every "app" opened from the desktop: back arrow, title, optional extras. */
export function AppHeader({ title, children }: { title: string; children?: ReactNode }) {
  return (
    <View style={styles.bar}>
      <Pressable onPress={() => router.back()} hitSlop={12} accessibilityLabel="Back">
        <MaterialIcons name="chevron-left" size={28} color={Colors.text} />
      </Pressable>
      <TerminalText style={styles.title} numberOfLines={1}>{title}</TerminalText>
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 8,
    paddingVertical: 8,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: Colors.textDim,
  },
  title: {
    flex: 1,
    fontWeight: 'bold',
  },
});
