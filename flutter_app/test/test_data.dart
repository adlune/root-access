import 'dart:convert';
import 'dart:io';

import 'package:root_access/engine/models.dart';

/// The real game content. Tests run from the package root, so the path is relative to it.
GameData loadGameData() =>
    GameData.fromJson(jsonDecode(File('assets/missions.json').readAsStringSync()) as Json);
