// Port of flutter_app/lib/engine/parser.dart

/** A typed command split into its name and arguments.
 *  `connect 10.0.0.5` -> name: 'connect', args: ['10.0.0.5']. */
export type ParsedCommand = {
  name: string;
  args: string[];
};

/** Returns null for blank input. Command names are case-insensitive;
 *  arguments keep their case (passwords are case-sensitive). */
export function parseCommand(input: string): ParsedCommand | null {
  const parts = input.trim().split(/\s+/);
  if (parts[0] === '') return null;
  return { name: parts[0].toLowerCase(), args: parts.slice(1) };
}
