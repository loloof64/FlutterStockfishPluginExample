import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:stockfish_chess_engine_example/app_desktop.dart';
import 'package:stockfish_chess_engine_example/app_mobile.dart';
import 'package:window_manager/window_manager.dart';

bool isMobile() {
  return Platform.isAndroid || Platform.isIOS;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!isMobile()) windowManager.ensureInitialized();

  runApp(MaterialApp(
    home: isMobile() ? const AppMobile() : const AppDesktop(),
  ));
}
