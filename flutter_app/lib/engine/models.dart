// Shape of assets/missions.json (copied from shared/missions.json).
// Draft schema: finalize on Day 2, and keep in sync with rn_app/src/engine/types.ts.

class VirtualFile {
  const VirtualFile({required this.path, required this.content});

  factory VirtualFile.fromJson(Map<String, dynamic> json) =>
      VirtualFile(path: json['path'] as String, content: json['content'] as String);

  final String path;
  final String content;
}

class NetworkNode {
  const NetworkNode({
    required this.ip,
    required this.hostname,
    required this.ports,
    required this.files,
  });

  factory NetworkNode.fromJson(Map<String, dynamic> json) => NetworkNode(
        ip: json['ip'] as String,
        hostname: json['hostname'] as String,
        ports: (json['ports'] as List).cast<int>(),
        files: [
          for (final f in json['files'] as List) VirtualFile.fromJson(f as Map<String, dynamic>),
        ],
      );

  final String ip;
  final String hostname;
  final List<int> ports;
  final List<VirtualFile> files;
}

class Objective {
  const Objective({required this.type, required this.ip, required this.path});

  factory Objective.fromJson(Map<String, dynamic> json) => Objective(
        type: json['type'] as String,
        ip: json['ip'] as String,
        path: json['path'] as String,
      );

  final String type; // 'download' for now
  final String ip;
  final String path;
}

class Mission {
  const Mission({
    required this.id,
    required this.title,
    required this.sender,
    required this.brief,
    required this.nodes,
    required this.objective,
  });

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
        id: json['id'] as String,
        title: json['title'] as String,
        sender: json['sender'] as String,
        brief: json['brief'] as String,
        nodes: [
          for (final n in json['nodes'] as List) NetworkNode.fromJson(n as Map<String, dynamic>),
        ],
        objective: Objective.fromJson(json['objective'] as Map<String, dynamic>),
      );

  final String id;
  final String title;
  final String sender;
  final String brief;
  final List<NetworkNode> nodes;
  final Objective objective;
}

class MissionData {
  const MissionData({required this.version, required this.missions});

  factory MissionData.fromJson(Map<String, dynamic> json) => MissionData(
        version: json['version'] as int,
        missions: [
          for (final m in json['missions'] as List) Mission.fromJson(m as Map<String, dynamic>),
        ],
      );

  final int version;
  final List<Mission> missions;
}
