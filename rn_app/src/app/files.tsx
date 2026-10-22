import MaterialIcons from '@expo/vector-icons/MaterialIcons';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { AppHeader } from '@/components/app-header';
import { TerminalText } from '@/components/terminal-text';
import { Colors } from '@/constants/theme';
import { useGame } from '@/game/game-provider';

/** Every file you've downloaded, kept across jobs. Tap one to read it. */
export default function Files() {
  const { files } = useGame();
  const [open, setOpen] = useState<number | null>(null);

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <AppHeader title="FILES  ~/downloads" />
      {files.length === 0 ? (
        <View style={styles.empty}>
          <TerminalText dim style={styles.center}>{"No files yet.\nUse 'download' in the terminal."}</TerminalText>
        </View>
      ) : (
        <ScrollView contentContainerStyle={styles.list}>
          {files.map((file, i) => (
            <Pressable key={`${file.host}:${file.path}`} onPress={() => setOpen(open === i ? null : i)} style={styles.item}>
              <View style={styles.row}>
                <MaterialIcons name="description" size={18} color={Colors.text} />
                <TerminalText style={styles.name}>{file.path.split('/').pop()}</TerminalText>
                <TerminalText dim style={styles.small}>{file.host}</TerminalText>
              </View>
              {open === i && <TerminalText style={styles.contents}>{file.lines.join('\n')}</TerminalText>}
            </Pressable>
          ))}
        </ScrollView>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  empty: {
    flex: 1,
    justifyContent: 'center',
  },
  center: {
    textAlign: 'center',
  },
  list: {
    padding: 12,
  },
  item: {
    paddingVertical: 8,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  name: {
    flex: 1,
  },
  small: {
    fontSize: 12,
  },
  contents: {
    marginTop: 8,
    padding: 12,
    fontSize: 13,
    lineHeight: 19,
    backgroundColor: Colors.surface,
  },
});
