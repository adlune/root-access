import 'package:flutter_test/flutter_test.dart';
import 'package:root_access/engine/commands.dart';
import 'package:root_access/engine/game_state.dart';
import 'package:root_access/engine/parser.dart';
import 'package:root_access/engine/paths.dart';

import 'test_data.dart';

/// Plays commands against the engine and remembers what was printed.
class Session {
  Session({int mission = 0}) : state = GameState.start(loadGameData(), missionIndex: mission);

  GameState state;
  List<OutputLine> lastLines = const [];
  Effect lastEffect = Effect.none;

  String get output => lastLines.map((l) => l.text).join('\n');

  Session run(String input) => _apply(execute(state, input));
  Session tickOnce() => _apply(tick(state));
  Session finishCrack({required bool success}) => _apply(completeCrack(state, success: success));

  Session _apply(CommandResult r) {
    state = r.state;
    lastLines = r.lines;
    lastEffect = r.effect;
    return this;
  }
}

void main() {
  group('parser', () {
    test('splits name and args, lowercases the name only', () {
      final cmd = parseCommand('  LOGIN jmorgan Kestrel#2024 ')!;
      expect(cmd.name, 'login');
      expect(cmd.args, ['jmorgan', 'Kestrel#2024']);
    });

    test('blank input is ignored', () {
      expect(parseCommand('   '), isNull);
      expect(Session().run('').lastLines, isEmpty);
    });
  });

  group('paths', () {
    test('resolves relative, absolute and .. segments', () {
      expect(resolvePath('/home', 'readme.txt'), '/home/readme.txt');
      expect(resolvePath('/home', '../var/log'), '/var/log');
      expect(resolvePath('/home', '/root/flag.txt'), '/root/flag.txt');
      expect(resolvePath('/', '..'), '/');
    });
  });

  group('basics', () {
    test('unknown command suggests help', () {
      final s = Session().run('hack');
      expect(s.output, contains('command not found: hack'));
      expect(s.lastLines.last.style, LineStyle.error);
    });

    test('echoes the prompt and input first', () {
      final s = Session().run('scan');
      expect(s.lastLines.first.text, r'rookie@localhost:~$ scan');
      expect(s.lastLines.first.style, LineStyle.input);
    });

    test('help lists every command', () {
      final s = Session().run('help');
      for (final c in s.state.data.commands) {
        expect(s.output, contains(c.usage));
      }
    });

    test('clear asks the UI to clear the screen', () {
      final s = Session().run('clear');
      expect(s.lastEffect, Effect.clearScreen);
      expect(s.lastLines, isEmpty);
    });

    test('missing arguments print usage', () {
      expect(Session().run('connect').output, contains('usage: connect <ip>'));
    });

    test('learn lists topics and explains one', () {
      expect(Session().run('learn').output, contains('ports'));
      expect(Session().run('learn ports').output, contains('22 SSH'));
      expect(Session().run('learn magic').output, contains("no topic 'magic'"));
    });
  });

  group('mission 1: Hello, World', () {
    test('full walkthrough completes the job and sends new mail', () {
      final s = Session();
      expect(s.run('mail').output, contains('Welcome to Entropy'));
      expect(s.run('scan').output, contains('10.0.0.5'));
      expect(s.run('connect 10.0.0.9').output, contains('no route to host'));

      s.run('connect 10.0.0.5');
      expect(prompt(s.state), r'rookie@practice-srv:/$');
      expect(s.run('ls').output, contains('home/'));

      s.run('cd home');
      expect(prompt(s.state), r'rookie@practice-srv:/home$');
      expect(s.run('cat readme.txt').output, contains("you're in"));

      s.run('download welcome.txt');
      expect(s.output, contains('JOB COMPLETE: Hello, World'));
      expect(s.output, contains('New mail from bit@entropy.net'));
      expect(s.state.missionIndex, 1);
      expect(s.state.completed, contains('m1_hello_world'));
      expect(s.state.connectedIp, isNull);
    });

    test('cd .. and bad folders', () {
      final s = Session().run('connect 10.0.0.5').run('cd home');
      expect(s.run('cd nope').output, contains('no such folder'));
      s.run('cd ..');
      expect(s.state.cwd, '/');
    });

    test('downloads report the file, even the one that ends the job', () {
      final s = GameState.start(loadGameData());
      final connected = execute(execute(s, 'connect 10.0.0.5').state, 'cd home').state;
      expect(execute(connected, 'ls').downloaded, isNull);

      final readme = execute(connected, 'download readme.txt').downloaded!;
      expect(readme.host, 'practice-srv');
      expect(readme.file.path, '/home/readme.txt');

      final last = execute(connected, 'download welcome.txt');
      expect(last.state.missionIndex, 1); // job complete, session wiped...
      expect(last.downloaded!.file.lines.first, contains('Tutorial complete')); // ...but the file is reported
    });

    test('downloads show up locally after disconnecting', () {
      final s = Session().run('connect 10.0.0.5').run('download /home/readme.txt').run('disconnect');
      expect(s.run('ls').output, contains('readme.txt'));
      expect(s.run('cat readme.txt').output, contains("you're in"));
    });
  });

  group('mission 2: Credential Reuse', () {
    test('locked machine hides its files until cracked', () {
      final s = Session(mission: 1).run('connect 10.0.2.44');
      expect(s.output, contains('Access is restricted'));
      expect(s.run('ls').output, contains('Permission denied'));
      expect(s.run('probe').output, contains('LOCKED'));
    });

    test('crack opens the minigame; winning unlocks, losing does not', () {
      final s = Session(mission: 1).run('connect 10.0.2.44');
      expect(s.run('crack 80').output, contains("isn't the lock"));

      s.run('crack 21');
      expect(s.lastEffect, Effect.startCrack);
      expect(s.state.crackPort, 21);

      s.finishCrack(success: false);
      expect(s.output, contains('Crack failed'));
      expect(s.state.hasAccess, isFalse);

      s.run('crack 21').finishCrack(success: true);
      expect(s.output, contains('Access granted'));
      expect(s.state.hasAccess, isTrue);
      expect(s.state.crackPort, isNull);
    });

    test('hardened SSH refuses cracking and wrong passwords', () {
      final s = Session(mission: 1).run('connect 10.0.2.10');
      expect(s.output, contains('Trace detected'));
      expect(s.run('crack 22').output, contains('hardened'));
      expect(s.state.crackPort, isNull);
      expect(s.run('login jmorgan Summer2019!').output, contains('Access denied'));
      expect(s.run('login jmorgan').output, contains('usage: login'));
    });

    test('full walkthrough: crack backup, reuse the password, grab the flag', () {
      final s = Session(mission: 1)
          .run('connect 10.0.2.44')
          .run('crack 21')
          .finishCrack(success: true)
          .run('cd /backup');
      expect(s.run('cat passwords.bak').output, contains('Kestrel#2024'));

      s.run('connect 10.0.2.10').run('login jmorgan Kestrel#2024');
      expect(s.output, contains('Logged in as jmorgan'));
      s.run('download /root/flag.txt');
      expect(s.output, contains('JOB COMPLETE: Credential Reuse'));
      expect(s.state.missionIndex, 2);
    });

    test('trace counts down, warns, then kicks you out and resets the job', () {
      final s = Session(mission: 1)
          .run('connect 10.0.2.44')
          .run('crack 21')
          .finishCrack(success: true)
          .run('connect 10.0.2.10');
      final seconds = s.state.traceRemaining!;

      for (var i = 0; i < seconds - 1; i++) {
        s.tickOnce();
        if (s.state.traceRemaining == 10) expect(s.output, contains('10 seconds'));
      }
      expect(s.state.connectedIp, '10.0.2.10');

      s.tickOnce();
      expect(s.output, contains('TRACE COMPLETE'));
      expect(s.state.connectedIp, isNull);
      expect(s.state.traceRemaining, isNull);
      expect(s.state.unlocked, isEmpty); // the cracked backup server is locked again
      expect(s.state.missionIndex, 1); // same job, try again
    });

    test('disconnecting stops the trace', () {
      final s = Session(mission: 1).run('connect 10.0.2.10').tickOnce().run('disconnect');
      expect(s.state.traceRemaining, isNull);
      expect(s.tickOnce().lastLines, isEmpty);
    });
  });

  group('mission 3: Log Detective', () {
    test('grep finds the failed logins and counts them', () {
      final s = Session(mission: 2).run('connect 172.16.4.20').run('grep failed /var/log/auth.log');
      expect(s.output, contains('203.0.113.77'));
      expect(s.output, contains('-- 13 matching lines')); // 10 from the attacker, 3 decoys
      expect(RegExp('203.0.113.77').allMatches(s.output).length, 10);
      expect(s.output, isNot(contains('Accepted')));
    });

    test('wrong report is rejected, right one finishes the game', () {
      final s = Session(mission: 2);
      expect(s.run('report 198.51.100.23').output, contains('Report rejected'));
      s.run('report 203.0.113.77');
      expect(s.output, contains('JOB COMPLETE: Log Detective'));
      expect(s.output, contains('You beat ROOT_ACCESS'));
      expect(s.state.finished, isTrue);
      expect(s.run('mail').output, contains('No new mail'));
    });

    test('report only works on jobs that ask for one', () {
      expect(Session().run('report 1.2.3.4').output, contains('nothing to report'));
    });
  });
}
