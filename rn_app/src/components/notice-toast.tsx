import { useEffect, useState } from 'react';
import { Pressable, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Colors, colorForLine } from '@/constants/theme';
import { useGame } from '@/game/game-provider';

import { TerminalText } from './terminal-text';

const SHOW_FOR_MS = 3000;

/** Shows the latest notice (new mail, trace warnings...) at the top of any screen. */
export function NoticeToast() {
  const { notice } = useGame();
  const [hiddenId, setHiddenId] = useState<number | null>(null);

  useEffect(() => {
    if (!notice) return;
    const timer = setTimeout(() => setHiddenId(notice.id), SHOW_FOR_MS);
    return () => clearTimeout(timer);
  }, [notice]);

  if (!notice || notice.id === hiddenId) return null;
  const color = colorForLine(notice.style);
  return (
    <SafeAreaView style={styles.overlay} edges={['top']} pointerEvents="box-none">
      <Pressable onPress={() => setHiddenId(notice.id)} style={[styles.toast, { borderColor: color }]}>
        <TerminalText style={[styles.text, { color }]}>{notice.message}</TerminalText>
      </Pressable>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
  },
  toast: {
    marginTop: 44,
    marginHorizontal: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderWidth: 1,
    borderRadius: 8,
    backgroundColor: Colors.surface,
  },
  text: {
    fontSize: 13,
  },
});
