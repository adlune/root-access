import 'package:flutter_test/flutter_test.dart';
import 'package:root_access/engine/models.dart';

import 'test_data.dart';

void main() {
  final data = loadGameData();

  test('loads all missions in order', () {
    expect(data.missions.map((m) => m.id), [
      'm1_hello_world',
      'm2_credential_reuse',
      'm3_log_detective',
    ]);
  });

  test('parses locks and objectives', () {
    final kestrel = data.missions[1].nodes.firstWhere((n) => n.hostname == 'kestrel-ssh');
    expect(kestrel.lock?.crackable, isFalse);
    expect(kestrel.traceSeconds, greaterThan(0));
    expect(data.missions[1].objective, isA<DownloadObjective>());
    expect(data.missions[2].objective, isA<ReportObjective>());
  });

  test('every command has help text', () {
    expect(data.commands.map((c) => c.name), containsAll(['help', 'scan', 'connect', 'learn']));
    expect(data.topics, contains('ports'));
  });
}
