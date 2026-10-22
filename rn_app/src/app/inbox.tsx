import { Screen } from '@/components/screen';
import { TerminalText } from '@/components/terminal-text';

// Mission emails. TODO (Day 9): list missions from assets/missions.json.
export default function InboxScreen() {
  return (
    <Screen>
      <TerminalText>INBOX</TerminalText>
      <TerminalText dim>no messages yet</TerminalText>
    </Screen>
  );
}
