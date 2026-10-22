// Port of flutter_app/test/engine_test.dart (+ models_test.dart): the same cases,
// so both engines are held to the same behavior.

import { describe, expect, test } from '@jest/globals';

import { completeCrack, execute, prompt, tick } from '../commands';
import { gameData } from '../data';
import { type CommandResult, type Effect, type GameState, type OutputLine, hasAccess, isFinished, startGame } from '../gameState';
import { parseCommand } from '../parser';
import { resolvePath } from '../paths';

/** Plays commands against the engine and remembers what was printed. */
class Session {
  state: GameState;
  lastLines: OutputLine[] = [];
  lastEffect: Effect = 'none';

  constructor(mission = 0) {
    this.state = startGame(gameData, mission);
  }

  get output(): string {
    return this.lastLines.map((l) => l.text).join('\n');
  }

  run(input: string) { return this.apply(execute(this.state, input)); }
  tickOnce() { return this.apply(tick(this.state)); }
  finishCrack(success: boolean) { return this.apply(completeCrack(this.state, success)); }

  private apply(r: CommandResult): this {
    this.state = r.state;
    this.lastLines = r.lines;
    this.lastEffect = r.effect;
    return this;
  }
}

describe('game data', () => {
  test('loads all missions in order', () => {
    expect(gameData.missions.map((m) => m.id)).toEqual(['m1_hello_world', 'm2_credential_reuse', 'm3_log_detective']);
  });

  test('parses locks and objectives', () => {
    const kestrel = gameData.missions[1].nodes.find((n) => n.hostname === 'kestrel-ssh')!;
    expect(kestrel.lock?.crackable).toBe(false);
    expect(kestrel.traceSeconds).toBeGreaterThan(0);
    expect(gameData.missions[1].objective.type).toBe('download');
    expect(gameData.missions[2].objective.type).toBe('report');
  });
});

describe('parser', () => {
  test('splits name and args, lowercases the name only', () => {
    expect(parseCommand('  LOGIN jmorgan Kestrel#2024 ')).toEqual({ name: 'login', args: ['jmorgan', 'Kestrel#2024'] });
  });

  test('blank input is ignored', () => {
    expect(parseCommand('   ')).toBeNull();
    expect(new Session().run('').lastLines).toEqual([]);
  });
});

describe('paths', () => {
  test('resolves relative, absolute and .. segments', () => {
    expect(resolvePath('/home', 'readme.txt')).toBe('/home/readme.txt');
    expect(resolvePath('/home', '../var/log')).toBe('/var/log');
    expect(resolvePath('/home', '/root/flag.txt')).toBe('/root/flag.txt');
    expect(resolvePath('/', '..')).toBe('/');
  });
});

describe('basics', () => {
  test('unknown command suggests help', () => {
    const s = new Session().run('hack');
    expect(s.output).toContain('command not found: hack');
    expect(s.lastLines.at(-1)!.style).toBe('error');
  });

  test('echoes the prompt and input first', () => {
    const s = new Session().run('scan');
    expect(s.lastLines[0]).toEqual({ text: 'rookie@localhost:~$ scan', style: 'input' });
  });

  test('help lists every command', () => {
    const s = new Session().run('help');
    for (const c of gameData.commands) expect(s.output).toContain(c.usage);
  });

  test('clear asks the UI to clear the screen', () => {
    const s = new Session().run('clear');
    expect(s.lastEffect).toBe('clearScreen');
    expect(s.lastLines).toEqual([]);
  });

  test('missing arguments print usage', () => {
    expect(new Session().run('connect').output).toContain('usage: connect <ip>');
  });

  test('learn lists topics and explains one', () => {
    expect(new Session().run('learn').output).toContain('ports');
    expect(new Session().run('learn ports').output).toContain('22 SSH');
    expect(new Session().run('learn magic').output).toContain("no topic 'magic'");
  });
});

describe('mission 1: Hello, World', () => {
  test('full walkthrough completes the job and sends new mail', () => {
    const s = new Session();
    expect(s.run('mail').output).toContain('Welcome to Entropy');
    expect(s.run('scan').output).toContain('10.0.0.5');
    expect(s.run('connect 10.0.0.9').output).toContain('no route to host');

    s.run('connect 10.0.0.5');
    expect(prompt(s.state)).toBe('rookie@practice-srv:/$');
    expect(s.run('ls').output).toContain('home/');

    s.run('cd home');
    expect(prompt(s.state)).toBe('rookie@practice-srv:/home$');
    expect(s.run('cat readme.txt').output).toContain("you're in");

    s.run('download welcome.txt');
    expect(s.output).toContain('JOB COMPLETE: Hello, World');
    expect(s.output).toContain('New mail from bit@entropy.net');
    expect(s.state.missionIndex).toBe(1);
    expect(s.state.completed).toContain('m1_hello_world');
    expect(s.state.connectedIp).toBeNull();
  });

  test('cd .. and bad folders', () => {
    const s = new Session().run('connect 10.0.0.5').run('cd home');
    expect(s.run('cd nope').output).toContain('no such folder');
    s.run('cd ..');
    expect(s.state.cwd).toBe('/');
  });

  test('downloads report the file, even the one that ends the job', () => {
    const s = startGame(gameData);
    const connected = execute(execute(s, 'connect 10.0.0.5').state, 'cd home').state;
    expect(execute(connected, 'ls').downloaded).toBeUndefined();

    const readme = execute(connected, 'download readme.txt').downloaded!;
    expect(readme.host).toBe('practice-srv');
    expect(readme.file.path).toBe('/home/readme.txt');

    const last = execute(connected, 'download welcome.txt');
    expect(last.state.missionIndex).toBe(1); // job complete, session wiped...
    expect(last.downloaded!.file.lines[0]).toContain('Tutorial complete'); // ...but the file is reported
  });

  test('downloads show up locally after disconnecting', () => {
    const s = new Session().run('connect 10.0.0.5').run('download /home/readme.txt').run('disconnect');
    expect(s.run('ls').output).toContain('readme.txt');
    expect(s.run('cat readme.txt').output).toContain("you're in");
  });
});

describe('mission 2: Credential Reuse', () => {
  test('locked machine hides its files until cracked', () => {
    const s = new Session(1).run('connect 10.0.2.44');
    expect(s.output).toContain('Access is restricted');
    expect(s.run('ls').output).toContain('Permission denied');
    expect(s.run('probe').output).toContain('LOCKED');
  });

  test('crack opens the minigame; winning unlocks, losing does not', () => {
    const s = new Session(1).run('connect 10.0.2.44');
    expect(s.run('crack 80').output).toContain("isn't the lock");
    expect(s.run('crack 21abc').output).toContain('usage: crack');

    s.run('crack 21');
    expect(s.lastEffect).toBe('startCrack');
    expect(s.state.crackPort).toBe(21);

    s.finishCrack(false);
    expect(s.output).toContain('Crack failed');
    expect(hasAccess(s.state)).toBe(false);

    s.run('crack 21').finishCrack(true);
    expect(s.output).toContain('Access granted');
    expect(hasAccess(s.state)).toBe(true);
    expect(s.state.crackPort).toBeNull();
  });

  test('hardened SSH refuses cracking and wrong passwords', () => {
    const s = new Session(1).run('connect 10.0.2.10');
    expect(s.output).toContain('Trace detected');
    expect(s.run('crack 22').output).toContain('hardened');
    expect(s.state.crackPort).toBeNull();
    expect(s.run('login jmorgan Summer2019!').output).toContain('Access denied');
    expect(s.run('login jmorgan').output).toContain('usage: login');
  });

  test('full walkthrough: crack backup, reuse the password, grab the flag', () => {
    const s = new Session(1).run('connect 10.0.2.44').run('crack 21').finishCrack(true).run('cd /backup');
    expect(s.run('cat passwords.bak').output).toContain('Kestrel#2024');

    s.run('connect 10.0.2.10').run('login jmorgan Kestrel#2024');
    expect(s.output).toContain('Logged in as jmorgan');
    s.run('download /root/flag.txt');
    expect(s.output).toContain('JOB COMPLETE: Credential Reuse');
    expect(s.state.missionIndex).toBe(2);
  });

  test('trace counts down, warns, then kicks you out and resets the job', () => {
    const s = new Session(1).run('connect 10.0.2.44').run('crack 21').finishCrack(true).run('connect 10.0.2.10');
    const seconds = s.state.traceRemaining!;

    for (let i = 0; i < seconds - 1; i++) {
      s.tickOnce();
      if (s.state.traceRemaining === 10) expect(s.output).toContain('10 seconds');
    }
    expect(s.state.connectedIp).toBe('10.0.2.10');

    s.tickOnce();
    expect(s.output).toContain('TRACE COMPLETE');
    expect(s.state.connectedIp).toBeNull();
    expect(s.state.traceRemaining).toBeNull();
    expect(s.state.unlocked).toEqual([]); // the cracked backup server is locked again
    expect(s.state.missionIndex).toBe(1); // same job, try again
  });

  test('disconnecting stops the trace', () => {
    const s = new Session(1).run('connect 10.0.2.10').tickOnce().run('disconnect');
    expect(s.state.traceRemaining).toBeNull();
    expect(s.tickOnce().lastLines).toEqual([]);
  });
});

describe('mission 3: Log Detective', () => {
  test('grep finds the failed logins and counts them', () => {
    const s = new Session(2).run('connect 172.16.4.20').run('grep failed /var/log/auth.log');
    expect(s.output).toContain('-- 13 matching lines'); // 10 from the attacker, 3 decoys
    expect(s.output.match(/203\.0\.113\.77/g)).toHaveLength(10);
    expect(s.output).not.toContain('Accepted');
  });

  test('wrong report is rejected, right one finishes the game', () => {
    const s = new Session(2);
    expect(s.run('report 198.51.100.23').output).toContain('Report rejected');
    s.run('report 203.0.113.77');
    expect(s.output).toContain('JOB COMPLETE: Log Detective');
    expect(s.output).toContain('You beat ROOT_ACCESS');
    expect(isFinished(s.state)).toBe(true);
    expect(s.run('mail').output).toContain('No new mail');
  });

  test('report only works on jobs that ask for one', () => {
    expect(new Session().run('report 1.2.3.4').output).toContain('nothing to report');
  });
});

describe('immutability', () => {
  test('commands never change the state they were given', () => {
    const before = startGame(gameData, 1);
    const snapshot = JSON.stringify(before);
    execute(before, 'connect 10.0.2.44');
    execute(before, 'connect 10.0.2.10');
    tick(before);
    expect(JSON.stringify(before)).toBe(snapshot);
  });
});
