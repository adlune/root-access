import { Pressable, StyleSheet, Switch, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { AppHeader } from '@/components/app-header';
import { TerminalText } from '@/components/terminal-text';
import { Colors } from '@/constants/theme';
import { useGame } from '@/game/game-provider';
import { TEXT_SPEEDS } from '@/game/settings';

export default function SettingsScreen() {
  const { settings, setSettings } = useGame();

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <AppHeader title="SETTINGS" />
      <View style={styles.body}>
        <TerminalText>Text speed</TerminalText>
        <TerminalText dim style={styles.small}>How fast terminal output types out. Tap the output to skip.</TerminalText>
        <View style={styles.chips}>
          {TEXT_SPEEDS.map((speed) => {
            const selected = settings.textSpeed === speed;
            return (
              <Pressable
                key={speed}
                onPress={() => setSettings({ ...settings, textSpeed: speed })}
                style={[styles.chip, selected && styles.chipSelected]}
                accessibilityState={{ selected }}
              >
                <TerminalText style={selected && { color: Colors.background }}>{speed}</TerminalText>
              </Pressable>
            );
          })}
        </View>

        <View style={styles.switchRow}>
          <View style={styles.fill}>
            <TerminalText>Haptics</TerminalText>
            <TerminalText dim style={styles.small}>Vibrate when a job is done or a trace catches you.</TerminalText>
          </View>
          <Switch
            value={settings.haptics}
            onValueChange={(on) => setSettings({ ...settings, haptics: on })}
            trackColor={{ false: Colors.surface, true: Colors.text }}
            thumbColor={settings.haptics ? Colors.background : Colors.textDim}
          />
        </View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  body: {
    padding: 16,
    gap: 4,
  },
  fill: {
    flex: 1,
  },
  small: {
    fontSize: 12,
  },
  chips: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 8,
    marginBottom: 24,
  },
  chip: {
    borderWidth: 1,
    borderColor: Colors.textDim,
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 6,
    backgroundColor: Colors.surface,
  },
  chipSelected: {
    backgroundColor: Colors.text,
  },
  switchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
});
