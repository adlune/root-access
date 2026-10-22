import MaterialIcons from '@expo/vector-icons/MaterialIcons';
import { type Href, router } from 'expo-router';
import type { ComponentProps } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { StatusBar } from '@/components/status-bar';
import { TerminalText } from '@/components/terminal-text';
import { Colors } from '@/constants/theme';
import { currentMission } from '@/engine/gameState';
import { useGame } from '@/game/game-provider';

/** ROOT/OS home screen: a status bar, app icons and the current job.
 *  Everything you *do* happens in the Terminal; the other apps are for reading. */
export default function Desktop() {
  const { game, files, unreadMail } = useGame();
  const mission = currentMission(game);

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <StatusBar
        leading={
          <Pressable onPress={() => router.back()} hitSlop={10} accessibilityLabel="Main menu">
            <MaterialIcons name="power-settings-new" size={18} color={Colors.textDim} />
          </Pressable>
        }
      />
      <TerminalText style={styles.os}>ROOT/OS</TerminalText>
      <View style={styles.grid}>
        <AppIcon icon="terminal" label="Terminal" href="/terminal" />
        <AppIcon icon="mail-outline" label="Mail" href="/inbox" badge={unreadMail ? '1' : undefined} />
        <AppIcon icon="folder-open" label="Files" href="/files" badge={files.length ? String(files.length) : undefined} dimBadge />
        <AppIcon icon="settings" label="Settings" href="/settings" />
      </View>
      <View style={styles.fill} />
      <Pressable onPress={() => router.push('/inbox')} style={styles.job}>
        {mission === null ? (
          <TerminalText style={{ color: Colors.success }}>ALL JOBS COMPLETE</TerminalText>
        ) : (
          <>
            <TerminalText dim style={styles.small}>
              CURRENT JOB {game.missionIndex + 1}/{game.data.missions.length}
            </TerminalText>
            <TerminalText style={styles.jobTitle}>{mission.title}</TerminalText>
            <TerminalText dim style={styles.small}>{mission.sender}</TerminalText>
          </>
        )}
      </Pressable>
    </SafeAreaView>
  );
}

function AppIcon({ icon, label, href, badge, dimBadge = false }: {
  icon: ComponentProps<typeof MaterialIcons>['name'];
  label: string;
  href: Href;
  badge?: string;
  dimBadge?: boolean; // a count, not something waiting for you
}) {
  return (
    <Pressable onPress={() => router.push(href)} style={styles.app} accessibilityLabel={label}>
      <View style={styles.icon}>
        <MaterialIcons name={icon} size={28} color={Colors.text} />
        {badge !== undefined && (
          <View style={[styles.badge, { backgroundColor: dimBadge ? Colors.textDim : Colors.danger }]}>
            <TerminalText style={styles.badgeText}>{badge}</TerminalText>
          </View>
        )}
      </View>
      <TerminalText style={styles.small}>{label}</TerminalText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  fill: {
    flex: 1,
  },
  os: {
    textAlign: 'center',
    fontSize: 22,
    lineHeight: 30,
    letterSpacing: 4,
    marginTop: 24,
    marginBottom: 32,
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: 24,
  },
  app: {
    width: 72,
    alignItems: 'center',
    gap: 6,
  },
  icon: {
    width: 60,
    height: 60,
    borderWidth: 1,
    borderColor: Colors.text,
    borderRadius: 12,
    backgroundColor: Colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
  },
  badge: {
    position: 'absolute',
    top: -6,
    right: -6,
    borderRadius: 10,
    paddingHorizontal: 6,
  },
  badgeText: {
    fontSize: 11,
    lineHeight: 16,
    color: Colors.background,
  },
  small: {
    fontSize: 12,
  },
  job: {
    margin: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: Colors.textDim,
  },
  jobTitle: {
    fontWeight: 'bold',
    marginTop: 4,
  },
});
