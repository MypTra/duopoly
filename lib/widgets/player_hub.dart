// lib/widgets/player_hub.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../providers/game_state.dart';
import '../widgets/property_management_sheet.dart';

class PlayerHub extends StatelessWidget {
  final Player player;
  
  const PlayerHub({
    super.key,
    required this.player,
  });

  void _showPropertyManagementSheet(BuildContext context) {
    final gameActions = context.read<GameState>();
    gameActions.openPropertyManagement();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: gameActions,
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            builder: (BuildContext context, ScrollController scrollController) {
              return PropertyManagementSheet(controller: scrollController);
            },
          ),
        );
      },
    ).whenComplete(() {
      gameActions.closePropertyManagement();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final isCurrentPlayer = gameState.currentPlayer == player;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: player.color.withAlpha(230),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(
          color: isCurrentPlayer ? Colors.yellow.shade600 : Colors.white.withOpacity(0.7),
          width: isCurrentPlayer ? 3.0 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: player.money < 0
          ? const Center(child: Text("İFLAS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${player.money} TL',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                if (isCurrentPlayer) ...[
                  const Divider(color: Colors.white54, height: 12, thickness: 1),
                  if (player.isInJail)
                    _buildJailActions(context)
                  else
                    _buildNormalActions(context),
                ]
              ],
            ),
    );
  }

  Widget _buildNormalActions(BuildContext context) {
    final gameState = context.watch<GameState>();
    final gameActions = context.read<GameState>();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image.asset('assets/dice/dice-${gameState.isDiceAnimating ? gameState.animatingDice1 : gameState.dice1}.png', width: 28, height: 28),
            Image.asset('assets/dice/dice-${gameState.isDiceAnimating ? gameState.animatingDice2 : gameState.dice2}.png', width: 28, height: 28),
          ],
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: gameState.status == GameStatus.waitingForRoll && !gameState.isDiceAnimating
                ? () => gameActions.animateAndRollDice()
                : null,
            child: const Text('Zar At'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: gameState.hasRolled && !gameState.isDiceAnimating
                ? () => _showPropertyManagementSheet(context)
                : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Mülkler'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (gameState.status == GameStatus.waitingForEndTurn || gameState.status == GameStatus.managingProperties) && !gameState.isDiceAnimating
                ? () => gameActions.endTurn()
                : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Sırayı Bitir'),
          ),
        ),
      ],
    );
  }

  Widget _buildJailActions(BuildContext context) {
    final gameState = context.watch<GameState>();
    final gameActions = context.read<GameState>();

    return Column(
      children: [
        Text("${player.turnsInJail}. Tur Hapiste", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: !gameState.isDiceAnimating ? () => gameActions.animateAndRollDice() : null,
            child: const Text('Çift Dene'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: !gameState.isDiceAnimating && player.money >= 50 ? () => gameActions.payToGetOutOfJail() : null,
            child: const Text('50 TL Öde'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: player.getOutOfJailCards > 0 && !gameState.isDiceAnimating ? () => gameActions.useGetOutOfJailCard() : null,
            child: Text('Kart Kullan (${player.getOutOfJailCards})'),
          ),
        ),
      ],
    );
  }
}