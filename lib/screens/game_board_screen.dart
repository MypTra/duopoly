// lib/screens/game_board_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../models/player.dart';
import '../models/game_tile_model.dart';
import '../providers/game_state.dart';
import '../widgets/player_hub.dart';
import '../widgets/property_management_sheet.dart';

class GameBoardScreen extends StatefulWidget {
  const GameBoardScreen({super.key});

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> {
  bool _isDialogShowing = false;
  final TransformationController _transformationController = TransformationController();

  final double _cornerSize = 140.0;
  final double _tileWidth = 85.0; 
  final double _tileHeight = 140.0; 
  late final Size _boardSize;

  late final List<Map<String, dynamic>> _tileData;

  @override
  void initState() {
    super.initState();
    final sideLength = _cornerSize * 2 + (9 * _tileWidth);
    _boardSize = Size(sideLength, sideLength);
    _tileData = _calculateAllTileData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gameState = Provider.of<GameState>(context);
    if (!_isDialogShowing) {
      if (gameState.status == GameStatus.canBuyProperty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showBuyPropertyDialog(context));
      } else if (gameState.status == GameStatus.showingCard) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showCardDialog(context));
      } else if (gameState.status == GameStatus.gameOver) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showGameOverDialog(context));
      } else if (gameState.status == GameStatus.showingRentPaid) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showRentPaidDialog(context));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    if (gameState.status == GameStatus.notStarted || gameState.gameTiles == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_transformationController.value == Matrix4.identity()) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final scale = min(screenWidth / _boardSize.width, screenHeight / _boardSize.height) * 0.95; 
            final xOffset = (screenWidth - _boardSize.width * scale) / 2;
            final yOffset = (screenHeight - _boardSize.height * scale) / 2;
            _transformationController.value = Matrix4.identity()
              ..translate(xOffset, yOffset)
              ..scale(scale);
          }
          
          return InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.1,
            maxScale: 2.0,
            boundaryMargin: const EdgeInsets.all(50.0),
            child: Container(
              width: _boardSize.width,
              height: _boardSize.height,
              color: const Color(0xFFCDE2D0),
              child: Stack(
                children: [
                  ..._buildBoardLayout(context),
                  ..._buildPawns(context),
                  if (gameState.players!.isNotEmpty)
                    Positioned(top: _tileHeight + 20, left: _tileHeight + 20, child: PlayerHub(player: gameState.players![0])),
                  if (gameState.players!.length > 1)
                    Positioned(top: _tileHeight + 20, right: _tileHeight + 20, child: PlayerHub(player: gameState.players![1])),
                  if (gameState.players!.length > 2)
                    Positioned(bottom: _tileHeight + 20, left: _tileHeight + 20, child: PlayerHub(player: gameState.players![2])),
                  if (gameState.players!.length > 3)
                    Positioned(bottom: _tileHeight + 20, right: _tileHeight + 20, child: PlayerHub(player: gameState.players![3])),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
  
  List<Map<String, dynamic>> _calculateAllTileData() {
    final List<Map<String, dynamic>> data = [];
    for (int i = 0; i < 40; i++) {
        Rect rect;
        int quarterTurns = 0;

        if (i == 0) { // Başlangıç (Sağ-Alt)
            rect = Rect.fromLTWH(_boardSize.width - _cornerSize, _boardSize.height - _cornerSize, _cornerSize, _cornerSize);
        } else if (i == 10) { // Hapis (Sol-Alt)
            rect = Rect.fromLTWH(0, _boardSize.height - _cornerSize, _cornerSize, _cornerSize);
        } else if (i == 20) { // Otopark (Sol-Üst)
            rect = Rect.fromLTWH(0, 0, _cornerSize, _cornerSize);
        } else if (i == 30) { // Hapise Gir (Sağ-Üst)
            rect = Rect.fromLTWH(_boardSize.width - _cornerSize, 0, _cornerSize, _cornerSize);
        } 
        else if (i > 0 && i < 10) { // Alt Sıra
            rect = Rect.fromLTWH(_boardSize.width - _cornerSize - (i * _tileWidth), _boardSize.height - _tileHeight, _tileWidth, _tileHeight);
        } else if (i > 10 && i < 20) { // Sol Sıra
            rect = Rect.fromLTWH(0, _boardSize.height - _cornerSize - ((i - 10) * _tileWidth), _tileHeight, _tileWidth);
            quarterTurns = 1;
        } else if (i > 20 && i < 30) { // Üst Sıra
            rect = Rect.fromLTWH(_cornerSize + ((i - 21) * _tileWidth), 0, _tileWidth, _tileHeight);
            quarterTurns = 2;
        } else { // Sağ Sıra
            rect = Rect.fromLTWH(_boardSize.width - _tileHeight, _cornerSize + ((i - 31) * _tileWidth), _tileHeight, _tileWidth);
            quarterTurns = -1;
        }
        data.add({'rect': rect, 'turns': quarterTurns});
    }
    return data;
  }

  List<Widget> _buildBoardLayout(BuildContext context) {
    return List.generate(40, (i) {
      final data = _tileData[i];
      final rect = data['rect'] as Rect;
      final quarterTurns = data['turns'] as int;
      return Positioned.fromRect(
        rect: rect,
        child: RotatedBox(
          quarterTurns: quarterTurns,
          child: _buildTile(context, i),
        ),
      );
    });
  }

  List<Widget> _buildPawns(BuildContext context) {
    final gameState = context.watch<GameState>();
    return gameState.players!.asMap().entries.map((entry) {
      final playerIndex = entry.key; final player = entry.value;
      if (player.money < 0) return const SizedBox.shrink();
      
      final rect = _tileData[player.position]['rect'] as Rect;
      final position = rect.center;

      final pawnOffset = Offset((playerIndex % 2 == 0 ? -15.0 : 15.0), (playerIndex < 2 ? -15.0 : 15.0));
      const pawnSize = 30.0;
      
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic,
        left: position.dx - (pawnSize / 2) + pawnOffset.dx,
        top: position.dy - (pawnSize / 2) + pawnOffset.dy,
        child: Container(
          width: pawnSize, height: pawnSize,
          decoration: BoxDecoration(
              color: player.color, shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 6)]),
          child: Icon(player.icon, color: Colors.white, size: 20),
        ),
      );
    }).toList();
  }

  Widget _buildTile(BuildContext context, int tileIndex) {
    final gameState = context.watch<GameState>();
    final tile = gameState.gameTiles![tileIndex];
    final isProperty = tile.type == TileType.property || tile.type == TileType.station || tile.type == TileType.utility;
    Widget tileContent;
    final tileColor = isProperty ? const Color(0xFFCDE2D0) : _getSpecialTileColor(tile.type);
    if (isProperty) {
      Player? owner;
      if (tile.ownerPlayerIndex != null) { owner = gameState.players![tile.ownerPlayerIndex!]; }
      tileContent = _buildPropertyTile(tile, owner);
    } else {
      tileContent = _buildSpecialTile(tile);
    }
    return Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: tileColor,
        border: Border.all(color: Colors.black54, width: 1)
      ),
      child: tileContent
    );
  }

  Widget _buildPropertyTile(GameTileModel tile, Player? owner) {
    return Column(children: [
      Container(height: 35, width: double.infinity, color: tile.color ?? Colors.grey,
        child: owner != null ? Icon(owner.icon, color: Colors.white, size: 22) : _buildHouseIcons(tile.houseCount)),
      Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(tile.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
          if (tile.price != null) ...[ const SizedBox(height: 4), Text('${tile.price} TL', style: const TextStyle(fontSize: 13, color: Colors.black87))]
        ]))),
    ]);
  }

  Widget _buildSpecialTile(GameTileModel tile) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(tile.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
        if (tile.emoji != null) ...[const SizedBox(height: 10), Text(tile.emoji!, style: const TextStyle(fontSize: 40))]
      ]),
    );
  }

  Color _getSpecialTileColor(TileType type) {
    switch (type) {
      case TileType.chance: return const Color(0xFF81D4FA);
      case TileType.communityChest: return const Color(0xFFFFCC80);
      case TileType.tax: return Colors.grey.shade400;
      default: return Colors.grey.shade200;
    }
  }

  Widget _buildHouseIcons(int houseCount) {
    if (houseCount == 0) return const SizedBox.shrink();
    if (houseCount == 5) { return const Icon(Icons.hotel, color: Colors.white, size: 24); }
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(houseCount, (_) => const Icon(Icons.home, color: Colors.white, size: 16)),);
  }

  void _showRentPaidDialog(BuildContext context) {
    if (!mounted) return;
    setState(() { _isDialogShowing = true; });
    final gameActions = context.read<GameState>();
    showDialog(context: context, barrierDismissible: false, builder: (BuildContext dContext) {
      return AlertDialog(title: const Text('Kira Ödendi'), content: Text('${gameActions.rentPayerName}, ${gameActions.rentOwnerName}\'e ${gameActions.rentAmount} TL kira ödedi.'),
        actions: <Widget>[TextButton(child: const Text('Tamam'), onPressed: () { Navigator.of(dContext).pop(); gameActions.acknowledgeRentPayment(); },), ], );
    }).whenComplete(() { if (mounted) { setState(() { _isDialogShowing = false; }); } });
  }
  
  void _showGameOverDialog(BuildContext context) {
    if (!mounted) return;
    setState(() { _isDialogShowing = true; });
    final gameActions = context.read<GameState>();
    showDialog(context: context, barrierDismissible: false, builder: (BuildContext dContext) {
      return AlertDialog(title: const Text('Oyun Bitti!'), content: Text('Kazanan: ${gameActions.winner!.name}'),
        actions: <Widget>[ElevatedButton(child: const Text('Ana Menüye Dön'), onPressed: () { Navigator.of(dContext).pop(); Navigator.of(context).pop(); },), ],);
    }).whenComplete(() { if(mounted) { setState(() { _isDialogShowing = false; }); } });
  }

  void _showCardDialog(BuildContext context) {
    if (!mounted) return;
    setState(() { _isDialogShowing = true; });
    final gameActions = context.read<GameState>();
    showDialog(context: context, barrierDismissible: false, builder: (BuildContext dContext) {
      return AlertDialog(title: const Text('Bir Kart Çektin!'), content: Text(gameActions.lastCardDescription),
        actions: <Widget>[TextButton(child: const Text('Tamam'), onPressed: () { gameActions.acknowledgeCard(); Navigator.of(dContext).pop(); },), ],);
    }).whenComplete(() { if(mounted) { setState(() { _isDialogShowing = false; }); } });
  }

  void _showBuyPropertyDialog(BuildContext context) {
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
}