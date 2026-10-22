import { useEffect, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { AppHeader } from '@/components/app-header';
import { TerminalText } from '@/components/terminal-text';
import { Colors } from '@/constants/theme';
import type { Mission } from '@/engine/types';
import { useGame } from '@/game/game-provider';

type MailStatus = 'done' | 'current' | 'locked';

/** Mission emails: finished jobs, the current one (opened by default),
 *  and locked future ones shown as encrypted. */
export default function Mail() {
  const { game, markMailRead } = useGame();
  const [open, setOpen] = useState<number | null>(game.missionIndex);
  const missions = game.data.missions;

  // Opening Mail reads the current job's message (clears the desktop badge).
  useEffect(() => markMailRead(), [markMailRead]);

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <AppHeader title="MAIL">
        <TerminalText dim style={styles.count}>
          {game.completed.length}/{missions.length} done
        </TerminalText>
      </AppHeader>
      <ScrollView contentContainerStyle={styles.list}>
        {missions.map((mission, i) => (
          <MailItem
            key={mission.id}
            mission={mission}
            status={i < game.missionIndex ? 'done' : i === game.missionIndex ? 'current' : 'locked'}
            open={open === i}
            onPress={() => setOpen(open === i ? null : i)}
          />
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

function MailItem({ mission, status, open, onPress }: {
  mission: Mission;
  status: MailStatus;
  open: boolean;
  onPress: () => void;
}) {
  if (status === 'locked') {
    return <Row marker="#" title="[encrypted message]" subtitle="finish your current job to decrypt" color={Colors.textDim} />;
  }
  const current = status === 'current';
  const color = current ? Colors.text : Colors.textDim;
  return (
    <Pressable onPress={onPress}>
      <Row
        marker={current ? '>' : '✓'}
        title={mission.subject}
        subtitle={`${mission.sender} · ${mission.title}`}
        color={color}
        bold={current}
      />
      {open && <TerminalText style={[styles.body, { color }]}>{mission.body.join('\n')}</TerminalText>}
    </Pressable>
  );
}

function Row({ marker, title, subtitle, color, bold = false }: {
  marker: string;
  title: string;
  subtitle: string;
  color: string;
  bold?: boolean;
}) {
  return (
    <View style={styles.row}>
      <TerminalText style={[styles.marker, { color }]}>{marker}</TerminalText>
      <View style={styles.rowText}>
        <TerminalText style={{ color, fontWeight: bold ? 'bold' : 'normal' }}>{title}</TerminalText>
        <TerminalText dim style={styles.subtitle}>{subtitle}</TerminalText>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  count: {
    fontSize: 12,
    marginRight: 8,
  },
  list: {
    padding: 12,
  },
  row: {
    flexDirection: 'row',
    paddingVertical: 10,
  },
  marker: {
    width: 24,
  },
  rowText: {
    flex: 1,
  },
  subtitle: {
    fontSize: 12,
  },
  body: {
    paddingLeft: 24,
    paddingBottom: 16,
    fontSize: 13,
    lineHeight: 19,
  },
});
