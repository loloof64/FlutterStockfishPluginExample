import 'dart:async';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:chess/chess.dart' as chess_lib;

import 'package:flutter_stockfish_plugin/stockfish.dart';
import 'package:flutter_stockfish_plugin/stockfish_state.dart';
import 'package:window_manager/window_manager.dart';

class AppDesktop extends StatefulWidget {
  const AppDesktop({Key? key}) : super(key: key);

  @override
  AppDesktopState createState() => AppDesktopState();
}

class AppDesktopState extends State<AppDesktop> with WindowListener {
  late Stockfish _stockfish;
  final _fenController = TextEditingController(
      text: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
  late StreamSubscription _stockfishOutputSubsciption;
  var _timeMs = 1000.0;
  var _nextMove = '';
  var _stockfishOutputText = '';

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _doStartStockfish();
    _init();
  }

  @override
  void dispose() {
    _stopStockfish();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    _stopStockfish();
    await windowManager.destroy();
  }

  void _init() async {
    await windowManager.setPreventClose(true);
    setState(() {});
  }

  void _readStockfishOutput(String output) {
    // At least now, stockfish is ready : update UI.
    setState(() {
      _stockfishOutputText += "$output\n";
    });
    if (output.startsWith('bestmove')) {
      final parts = output.split(' ');
      setState(() {
        _nextMove = parts[1];
      });
    }
  }

  void _pasteFen() {
    FlutterClipboard.paste().then((value) {
      setState(() {
        _fenController.text = value;
      });
    });
  }

  void _updateThinkingTime(double newValue) {
    setState(() {
      _timeMs = newValue;
    });
  }

  bool _validPosition() {
    final chess = chess_lib.Chess();
    return chess.load(_fenController.text.trim());
  }

  void _computeNextMove() {
    if (!_validPosition()) {
      final message = "Illegal position: '${_fenController.text.trim()}' !\n";
      setState(() {
        _stockfishOutputText = message;
      });
      return;
    }
    setState(() {
      _stockfishOutputText = '';
    });
    _stockfish.stdin = 'position fen ${_fenController.text.trim()}';
    _stockfish.stdin = 'go movetime ${_timeMs.toInt()}';
  }

  void _stopStockfish() async {
    if (_stockfish.state.value == StockfishState.disposed ||
        _stockfish.state.value == StockfishState.error) {
      return;
    }
    _stockfishOutputSubsciption.cancel();
    _stockfish.stdin = 'quitok';
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {});
  }

  void _doStartStockfish() async {
    _stockfish = Stockfish();
    _stockfishOutputSubsciption =
        _stockfish.stdout.listen(_readStockfishOutput);
    setState(() {
      _stockfishOutputText = '';
    });
    await Future.delayed(const Duration(milliseconds: 1100));
    _stockfish.stdin = 'uci';
    await Future.delayed(const Duration(milliseconds: 3000));
    _stockfish.stdin = 'isready';
  }

  void _startStockfishIfNecessary() {
    setState(() {
      if (_stockfish.state.value == StockfishState.ready ||
          _stockfish.state.value == StockfishState.starting) {
        return;
      }
      _doStartStockfish();
    });
  }

  Icon _getStockfishStatusIcon() {
    Color color;
    switch (_stockfish.state.value) {
      case StockfishState.ready:
        color = Colors.green;
        break;
      case StockfishState.disposed:
      case StockfishState.error:
        color = Colors.red;
        break;
      case StockfishState.starting:
        color = Colors.orange;
    }
    return Icon(MdiIcons.circle, color: color);
  }

  void _handleClose(bool didPop) {
    if (didPop) return;
    _stopStockfish();
    _stockfish.dispose();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: _handleClose,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Stockfish Chess Engine example"),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(
                  controller: _fenController,
                  decoration: const InputDecoration(
                    hintText: 'Position FEN value',
                    border: OutlineInputBorder(),
                  ),
                ),
                ElevatedButton(
                  onPressed: _pasteFen,
                  child: const Text('Coller FEN'),
                ),
                Slider(
                  value: _timeMs,
                  onChanged: _updateThinkingTime,
                  min: 500,
                  max: 3000,
                ),
                Text('Thinking time : ${_timeMs.toInt()} millis'),
                ElevatedButton(
                  onPressed: _computeNextMove,
                  child: const Text('Search next move'),
                ),
                Text('Best move: $_nextMove'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _getStockfishStatusIcon(),
                    ElevatedButton(
                      onPressed: _startStockfishIfNecessary,
                      child: const Text('Start Stockfish'),
                    ),
                    ElevatedButton(
                      onPressed: _stopStockfish,
                      child: const Text('Stop Stockfish'),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 850.0,
                    height: 300.0,
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 2.0,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _stockfishOutputText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}