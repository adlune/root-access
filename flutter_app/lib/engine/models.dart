// Shape of assets/missions.json (copied from shared/missions.json).
// Keep in sync with rn_app/src/engine/types.ts.

typedef Json = Map<String, dynamic>;

List<String> _strings(Object? list) => (list as List).cast<String>();

class VirtualFile {
  const VirtualFile({required this.path, required this.lines});

  factory VirtualFile.fromJson(Json json) =>
      VirtualFile(path: json['path'] as String, lines: _strings(json['lines']));

  final String path; // absolute, e.g. "/home/readme.txt"
  final List<String> lines;
}

class Port {
  const Port({required this.number, required this.service});

  factory Port.fromJson(Json json) =>
      Port(number: json['number'] as int, service: json['service'] as String);

  final int number;
  final String service;
}

/// A machine you can't read until you crack [port] or log in with [user]/[password].
class Lock {
  const Lock({required this.port, required this.crackable, this.user, this.password});

  factory Lock.fromJson(Json json) => Lock(
        port: json['port'] as int,
        crackable: json['crackable'] as bool,
        user: json['user'] as String?,
        password: json['password'] as String?,
      );

  final int port;
  final bool crackable;
  final String? user;
  final String? password;
}

class NetworkNode {
  const NetworkNode({
    required this.ip,
    required this.hostname,
    required this.ports,
    required this.lock,
    required this.traceSeconds,
    required this.files,
  });

  factory NetworkNode.fromJson(Json json) => NetworkNode(
        ip: json['ip'] as String,
        hostname: json['hostname'] as String,
        ports: [for (final p in json['ports'] as List) Port.fromJson(p as Json)],
        lock: json['lock'] == null ? null : Lock.fromJson(json['lock'] as Json),
        traceSeconds: json['traceSeconds'] as int,
        files: [for (final f in json['files'] as List) VirtualFile.fromJson(f as Json)],
      );

  final String ip;
  final String hostname;
  final List<Port> ports;
  final Lock? lock;
  final int traceSeconds; // 0 = no trace
  final List<VirtualFile> files;
}

/// What finishes a mission: downloading a file, or reporting an answer.
sealed class Objective {
  const Objective();

  factory Objective.fromJson(Json json) => switch (json['type']) {
        'download' => DownloadObjective(ip: json['ip'] as String, path: json['path'] as String),
        'report' => ReportObjective(answer: json['answer'] as String),
        final type => throw FormatException('Unknown objective type: $type'),
      };
}

class DownloadObjective extends Objective {
  const DownloadObjective({required this.ip, required this.path});

  final String ip;
  final String path;
}

class ReportObjective extends Objective {
  const ReportObjective({required this.answer});

  final String answer;
}

class Mission {
  const Mission({
    required this.id,
    required this.title,
    required this.sender,
    required this.subject,
    required this.body,
    required this.hint,
    required this.nodes,
    required this.objective,
  });

  factory Mission.fromJson(Json json) => Mission(
        id: json['id'] as String,
        title: json['title'] as String,
        sender: json['sender'] as String,
        subject: json['subject'] as String,
        body: _strings(json['body']),
        hint: json['hint'] as String,
        nodes: [for (final n in json['nodes'] as List) NetworkNode.fromJson(n as Json)],
        objective: Objective.fromJson(json['objective'] as Json),
      );

  final String id;
  final String title;
  final String sender;
  final String subject;
  final List<String> body;
  final String hint;
  final List<NetworkNode> nodes;
  final Objective objective;
}

class CommandInfo {
  const CommandInfo({required this.name, required this.usage, required this.description});

  factory CommandInfo.fromJson(Json json) => CommandInfo(
        name: json['name'] as String,
        usage: json['usage'] as String,
        description: json['description'] as String,
      );

  final String name;
  final String usage;
  final String description;
}

class GameData {
  const GameData({
    required this.version,
    required this.playerUser,
    required this.playerHostname,
    required this.commands,
    required this.topics,
    required this.missions,
  });

  factory GameData.fromJson(Json json) {
    final player = json['player'] as Json;
    final topics = json['topics'] as Json;
    return GameData(
      version: json['version'] as int,
      playerUser: player['user'] as String,
      playerHostname: player['hostname'] as String,
      commands: [for (final c in json['commands'] as List) CommandInfo.fromJson(c as Json)],
      topics: {for (final e in topics.entries) e.key: _strings(e.value)},
      missions: [for (final m in json['missions'] as List) Mission.fromJson(m as Json)],
    );
  }

  final int version;
  final String playerUser;
  final String playerHostname;
  final List<CommandInfo> commands;
  final Map<String, List<String>> topics;
  final List<Mission> missions;
}
