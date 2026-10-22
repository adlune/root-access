// Shape of assets/missions.json (copied from shared/missions.json).
// Keep in sync with flutter_app/lib/engine/models.dart.

export type VirtualFile = {
  path: string; // absolute, e.g. "/home/readme.txt"
  lines: string[];
};

export type Port = {
  number: number;
  service: string;
};

/** A machine you can't read until you crack `port` or log in with `user`/`password`. */
export type Lock = {
  port: number;
  crackable: boolean;
  user: string | null;
  password: string | null;
};

export type NetworkNode = {
  ip: string;
  hostname: string;
  ports: Port[];
  lock: Lock | null;
  traceSeconds: number; // 0 = no trace
  files: VirtualFile[];
};

export type Objective =
  | { type: 'download'; ip: string; path: string }
  | { type: 'report'; answer: string };

export type Mission = {
  id: string;
  title: string;
  sender: string;
  subject: string;
  body: string[];
  hint: string;
  nodes: NetworkNode[];
  objective: Objective;
};

export type CommandInfo = {
  name: string;
  usage: string;
  description: string;
};

export type GameData = {
  version: number;
  player: { user: string; hostname: string };
  commands: CommandInfo[];
  topics: Record<string, string[]>;
  missions: Mission[];
};
