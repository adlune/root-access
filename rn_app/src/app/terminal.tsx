import { Screen } from '@/components/screen';
import { TerminalText } from '@/components/terminal-text';

// Main game screen. TODO (Day 9): output log, command input, trace bar.
export default function TerminalScreen() {
  return (
    <Screen>
      <TerminalText>root@localhost:~$ _</TerminalText>
      <TerminalText dim>terminal not implemented yet</TerminalText>
    </Screen>
  );
}
