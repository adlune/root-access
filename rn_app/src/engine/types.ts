// Shape of assets/missions.json (copied from shared/missions.json).
// Draft schema: finalize on Day 2, and keep in sync with flutter_app/lib/engine/models.dart.

export type VirtualFile = {
  path: string;
  content: string;
};

export type NetworkNode = {
  ip: string;
  hostname: string;
  ports: number[];
  files: VirtualFile[];
};

export type Objective = {
  type: 'download';
  ip: string;
  path: string;
};

export type Mission = {
  id: string;
  title: string;
  sender: string;
  brief: string;
  nodes: NetworkNode[];
  objective: Objective;
};

export type MissionData = {
  version: number;
  missions: Mission[];
};
