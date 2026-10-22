// Checks shared/missions.json, then copies it into both apps' assets folders.
// Run from the repo root after editing missions: node scripts/sync-missions.mjs

import { copyFileSync, mkdirSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const source = join(root, 'shared', 'missions.json');
const targets = [
  join(root, 'flutter_app', 'assets', 'missions.json'),
  join(root, 'rn_app', 'assets', 'missions.json'),
];

// Fail early on invalid JSON or broken content so a typo never reaches the apps.
const data = JSON.parse(readFileSync(source, 'utf8'));
const errors = [];
const ids = new Set();

for (const mission of data.missions) {
  const where = `mission "${mission.id}"`;
  if (ids.has(mission.id)) errors.push(`${where}: duplicate id`);
  ids.add(mission.id);

  for (const node of mission.nodes) {
    const lock = node.lock;
    if (lock && !node.ports.some((p) => p.number === lock.port)) {
      errors.push(`${where}: ${node.hostname} is locked on port ${lock.port}, which it doesn't have`);
    }
    if (lock && !lock.crackable && !(lock.user && lock.password)) {
      errors.push(`${where}: ${node.hostname} can't be cracked and has no credentials, so it's unbeatable`);
    }
  }

  const goal = mission.objective;
  if (goal.type === 'download') {
    const node = mission.nodes.find((n) => n.ip === goal.ip);
    if (!node) errors.push(`${where}: objective ip ${goal.ip} isn't one of its nodes`);
    else if (!node.files.some((f) => f.path === goal.path)) {
      errors.push(`${where}: objective file ${goal.path} doesn't exist on ${node.hostname}`);
    }
  } else if (goal.type !== 'report') {
    errors.push(`${where}: unknown objective type "${goal.type}"`);
  }
}

if (errors.length > 0) {
  console.error(`missions.json has problems:\n- ${errors.join('\n- ')}`);
  process.exit(1);
}

for (const target of targets) {
  mkdirSync(dirname(target), { recursive: true });
  copyFileSync(source, target);
  console.log(`synced -> ${target}`);
}
