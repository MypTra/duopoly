// lib/screens/game_board_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:math';

import '../models/player.dart';
import '../models/game_tile_model.dart';
import '../providers/game_state.dart';
import '../widgets/player_hub.dart';
import '../widgets/board_path_painter.dart';

class GameBoardScreen extends StatefulWidget {
  const GameBoardScreen({super.key});

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> {
  bool _isDialogShowing = false;
  
  late final Path _path;
  late final List<Offset> _tilePositions;
  late final List<double> _tileAngles;
  final int _tileCount = 40;
  final Size _boardSize = const Size(1200, 1200);
  final double _tileWidth = 80.0;
  final double _tileHeight = 110.0;

  @override
  void initState() {
    super.initState();
    _path = _createGamePath(_boardSize);
    _calculateTilePositionsAndAngles();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gameState = Provider.of<GameState>(context);
    if (!_isDialogShowing) {
      if (gameState.status == GameStatus.canBuyProperty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showBuyPropertyDialog());
      } else if (gameState.status == GameStatus.showingCard) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showCardDialog());
      } else if (gameState.status == GameStatus.gameOver) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showGameOverDialog());
      } else if (gameState.status == GameStatus.showingRentPaid) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showRentPaidDialog());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    if (gameState.status == GameStatus.notStarted || _tilePositions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Colors.blueGrey.shade900,
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: InteractiveViewer(
            minScale: 0.2,
            maxScale: 3.0,
            boundaryMargin: const EdgeInsets.all(20.0),
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _boardSize.width,
                height: _boardSize.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: Size.infinite,
                      painter: BoardPathPainter(gamePath: _path, pathWidth: _tileHeight),
                    ),
                    Center(
                      child: Text(
                        'DUOPOLY',
                        style: TextStyle(
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.1),
                          letterSpacing: 10,
                        ),
                      ),
                    ),
                    ..._buildPathTiles(context),
                    ..._buildPawns(context),
                    if (gameState.players!.isNotEmpty)
                      Positioned(top: 150, left: 150, child: PlayerHub(player: gameState.players![0])),
                    if (gameState.players!.length > 1)
                      Positioned(top: 150, right: 150, child: PlayerHub(player: gameState.players![1])),
                    if (gameState.players!.length > 2)
                      Positioned(bottom: 150, left: 150, child: PlayerHub(player: gameState.players![2])),
                    if (gameState.players!.length > 3)
                      Positioned(bottom: 150, right: 150, child: PlayerHub(player: gameState.players![3])),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  List<Widget> _buildPathTiles(BuildContext context) {
    final List<Widget> regularTiles = [];
    final List<Widget> cornerTiles = [];
    final Set<int> cornerIndices = {0, 10, 20, 30};

    for (int i = 0; i < _tileCount; i++) {
      final position = _tilePositions[i];
      final angle = _tileAngles[i];
      final tileWidget = Positioned(
        left: position.dx - (_tileWidth / 2),
        top: position.dy - (_tileHeight / 2),
        child: Transform.rotate(
          angle: angle,
          child: SizedBox(
            width: _tileWidth,
            height: _tileHeight,
            child: _buildTile(context, i),
          ),
        ),
      );
      if (cornerIndices.contains(i)) {
        cornerTiles.add(tileWidget);
      } else {
        regularTiles.add(tileWidget);
      }
    }
    return [...regularTiles, ...cornerTiles];
  }

  void _calculateTilePositionsAndAngles() {
    _tilePositions = [];
    _tileAngles = [];
    final ui.PathMetrics metrics = _path.computeMetrics();
    final ui.PathMetric metric = metrics.first;
    final double pathLength = metric.length;
    final Offset boardCenter = Offset(_boardSize.width / 2, _boardSize.height / 2);
    final Set<int> cornerIndices = {0, 10, 20, 30};
    const double cornerTilt = pi / 16;

    for (int i = 0; i < _tileCount; i++) {
      final distance = (pathLength / _tileCount) * i;
      final ui.Tangent? tangent = metric.getTangentForOffset(distance);
      if (tangent != null) {
        _tilePositions.add(tangent.position);
        double angle = 0.0;

        if (cornerIndices.contains(i)) {
          if (i == 0) { angle = -cornerTilt; } 
          else if (i == 10) { angle = -pi / 2 - cornerTilt; } 
          else if (i == 20) { angle = pi - cornerTilt; } 
          else { angle = pi / 2 - cornerTilt; }
        } else {
          final position = tangent.position;
          final Offset vectorFromCenter = position - boardCenter;
          final double angleFromCenter = atan2(vectorFromCenter.dy, vectorFromCenter.dx);
          if (angleFromCenter > pi / 4 && angleFromCenter < 3 * pi / 4) {
            angle = 0;
          } else if (angleFromCenter >= 3 * pi / 4 || angleFromCenter < -3 * pi / 4) {
            angle = -pi / 2;
          } else if (angleFromCenter >= -3 * pi / 4 && angleFromCenter < -pi / 4) {
            angle = pi;
          } else {
            angle = pi / 2;
          }
        }
        _tileAngles.add(angle);
      } else {
        _tilePositions.add(Offset.zero);
        _tileAngles.add(0.0);
      }
    }
  }

  Path _createGamePath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    const double padding = 20.0; 
    const double cornerRadius = 25.0;
    const Offset topLeft = Offset(padding, padding);
    final Offset topRight = Offset(w - padding, padding);
    final Offset bottomRight = Offset(w - padding, h - padding);
    final Offset bottomLeft = Offset(padding, h - padding);
    path.moveTo(bottomRight.dx - cornerRadius, bottomRight.dy);
    path.arcToPoint(Offset(bottomRight.dx, bottomRight.dy - cornerRadius), radius: const Radius.circular(cornerRadius), clockwise: false);
    path.lineTo(topRight.dx, topRight.dy + cornerRadius);
    path.arcToPoint(Offset(topRight.dx - cornerRadius, topRight.dy), radius: const Radius.circular(cornerRadius), clockwise: false);
    path.lineTo(topLeft.dx + cornerRadius, topLeft.dy);
    path.arcToPoint(Offset(topLeft.dx, topLeft.dy + cornerRadius), radius: const Radius.circular(cornerRadius), clockwise: false);
    path.lineTo(bottomLeft.dx, bottomLeft.dy - cornerRadius);
    path.arcToPoint(Offset(bottomLeft.dx + cornerRadius, bottomLeft.dy), radius: const Radius.circular(cornerRadius), clockwise: false);
    path.close();
    return path;
  }

  Color _getSpecialTileColor(TileType type) {
    switch (type) {
      case TileType.chance: return Colors.lightBlue.shade300;
      case TileType.communityChest: return Colors.orange.shade300;
      case TileType.tax: return Colors.grey.shade600;
      case TileType.jail: case TileType.goToJail: case TileType.freeParking: case TileType.start:
        return Colors.grey.shade400;
      default: return const Color(0xFFf0f8f0); 
    }
  }

  Widget _buildTile(BuildContext context, int tileIndex) {
    final gameState = context.watch<GameState>();
    final tile = gameState.gameTiles![tileIndex];
    final bool isProperty = tile.type == TileType.property || tile.type == TileType.station || tile.type == TileType.utility;
    Widget tileContent;
    Color cardBackgroundColor;
    if (isProperty) {
      Player? owner;
      if (tile.ownerPlayerIndex != null) { owner = gameState.players![tile.ownerPlayerIndex!]; }
      tileContent = _buildPropertyTile(tile, owner);
      cardBackgroundColor = const Color(0xFFf0f8f0);
    } else {
      tileContent = _buildSpecialTile(tile);
      cardBackgroundColor = _getSpecialTileColor(tile.type);
    }
    return Card(color: cardBackgroundColor, margin: const EdgeInsets.all(3), elevation: 4, child: tileContent);
  }

  Widget _buildSpecialTile(GameTileModel tile) {
    return Padding(padding: const EdgeInsets.all(4.0),
      child: Column(mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(tile.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          if (tile.emoji != null) Text(tile.emoji!, style: const TextStyle(fontSize: 35)),
        ],
      ),
    );
  }

  Widget _buildPropertyTile(GameTileModel tile, Player? owner) {
    return Opacity(
      opacity: tile.isMortgaged ? 0.6 : 1.0,
      child: Column(
        children: [
          Container(height: 25, width: double.infinity, color: tile.color ?? Colors.grey,
            child: owner != null ? Icon(owner.icon, color: Colors.white, size: 18) : _buildHouseIcons(tile.houseCount)),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(tile.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                if (tile.price != null) Text('${tile.price} TL', style: const TextStyle(fontSize: 11, color: Colors.black87)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<Widget> _buildPawns(BuildContext context) {
    final gameState = context.watch<GameState>();
    return gameState.players!.asMap().entries.map((entry) {
      final int playerIndex = entry.key; final Player player = entry.value;
      if (player.money < 0) return const SizedBox.shrink();
      final tilePosition = _tilePositions[player.position];
      final pawnOffset = Offset((playerIndex % 2 == 0 ? -12.0 : 12.0), (playerIndex < 2 ? -12.0 : 12.0));
      const pawnSize = 30.0;
      return AnimatedPositioned(duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic,
        top: tilePosition.dy - (pawnSize / 2) + pawnOffset.dy, left: tilePosition.dx - (pawnSize / 2) + pawnOffset.dx,
        child: Container(width: pawnSize, height: pawnSize,
          decoration: BoxDecoration(color: player.color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 6, spreadRadius: 1)],
          ),
          child: Icon(player.icon, color: Colors.white, size: 20),
        ),
      );
    }).toList();
  }

  void _showRentPaidDialog() {
    if (!mounted) return;
    setState(() { _isDialogShowing = true; });
    final gameActions = context.read<GameState>();
    showDialog(context: context, barrierDismissible: false, builder: (BuildContext dContext) {
      return AlertDialog(title: const Text('Kira Ödendi'), content: Text('${gameActions.rentPayerName}, ${gameActions.rentOwnerName}\'e ${gameActions.rentAmount} TL kira ödedi.'),
        actions: <Widget>[TextButton(child: const Text('Tamam'), onPressed: () { Navigator.of(dContext).pop(); gameActions.acknowledgeRentPayment(); },), ], );
    }).whenComplete(() { if (mounted) { setState(() { _isDialogShowing = false; }); } });
  }
  
  void _showGameOverDialog() {
    if (!mounted) return;
    setState(() { _isDialogShowing = true; });
    final gameActions = context.read<GameState>();
    showDialog(context: context, barrierDismissible: false, builder: (BuildContext dContext) {
      return AlertDialog(title: const Text('Oyun Bitti!'), content: Text('Kazanan: ${gameActions.winner!.name}'),
        actions: <Widget>[ElevatedButton(child: const Text('Ana Menüye Dön'), onPressed: () { Navigator.of(dContext).pop(); Navigator.of(context).pop(); },), ],);
    }).whenComplete(() { if(mounted) { setState(() { _isDialogShowing = false; }); } });
  }

  void _showCardDialog() {
    if (!mounted) return;
    setState(() { _isDialogShowing = true; });
    final gameActions = context.read<GameState>();
    showDialog(context: context, barrierDismissible: false, builder: (BuildContext dContext) {
      return AlertDialog(title: const Text('Bir Kart Çektin!'), content: Text(gameActions.lastCardDescription),
        actions: <Widget>[TextButton(child: const Text('Tamam'), onPressed: () { gameActions.acknowledgeCard(); Navigator.of(dContext).pop(); },), ],);
    }).whenComplete(() { if(mounted) { setState(() { _isDialogShowing = false; }); } });
  }

  void _showBuyPropertyDialog() {
    if (!mounted) return;
    setState(() { _isDialogShowing = true; });
    final gameActions = context.read<GameState>();
    final tile = gameActions.currentTile;
    showDialog(context: context, barrierDismissible: false, builder: (BuildContext dContext) {
      return AlertDialog(title: Text(tile.name), content: Text('${tile.price} TL karşılığında bu mülkü satın almak ister misin?'),
        actions: <Widget>[TextButton(child: const Text('Hayır (Pas Geç)'), onPressed: () { gameActions.ignoreProperty(); Navigator.of(dContext).pop(); },),
          ElevatedButton(child: const Text('Evet (Satın Al)'), onPressed: () { gameActions.buyProperty(); Navigator.of(dContext).pop(); },), ],);
    }).whenComplete(() { if(mounted) { setState(() { _isDialogShowing = false; }); } });
  }

  Widget _buildHouseIcons(int houseCount) {
    if (houseCount == 0) return const SizedBox.shrink();
    if (houseCount == 5) { return const Icon(Icons.hotel, color: Colors.white, size: 18); }
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(houseCount, (_) => const Icon(Icons.home, color: Colors.white, size: 12)),);
  }
}