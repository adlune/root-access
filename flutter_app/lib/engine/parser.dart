/// A typed command split into its name and arguments.
/// `connect 10.0.0.5` -> name: 'connect', args: ['10.0.0.5'].
class ParsedCommand {
  const ParsedCommand(this.name, this.args);

  final String name;
  final List<String> args;
}

/// Returns null for blank input. Command names are case-insensitive;
/// arguments keep their case (passwords are case-sensitive).
ParsedCommand? parseCommand(String input) {
  final parts = input.trim().split(RegExp(r'\s+'));
  if (parts.first.isEmpty) return null;
  return ParsedCommand(parts.first.toLowerCase(), parts.sublist(1));
}
