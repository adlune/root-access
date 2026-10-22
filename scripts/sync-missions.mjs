// Copies shared/missions.json into both apps' assets folders.
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

// Fail early on invalid JSON so a typo never reaches the apps.
JSON.parse(readFileSync(source, 'utf8'));

for (const target of targets) {
  mkdirSync(dirname(target), { recursive: true });
  copyFileSync(source, target);
  console.log(`synced -> ${target}`);
}
