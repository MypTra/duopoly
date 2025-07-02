// lib/widgets/property_management_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../models/game_tile_model.dart';
import 'dart:collection';

class PropertyManagementSheet extends StatelessWidget {
  final ScrollController controller;

  const PropertyManagementSheet({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final player = gameState.currentPlayer;

    // Mülkleri renge göre gruplama... (mevcut kod)
    final Map<Color, List<GameTileModel>> groupedProperties = {};
    if (player.ownedProperties.isNotEmpty) {
      for (var tileIndex in player.ownedProperties) {
        final tile = gameState.gameTiles![tileIndex];
        if (tile.type == TileType.property) {
          final color = tile.color!;
          if (groupedProperties[color] == null) {
            groupedProperties[color] = [];
          }
          groupedProperties[color]!.add(tile);
        }
      }
    }
    final sortedGroups = SplayTreeMap<Color, List<GameTileModel>>.from(
        groupedProperties, (a, b) => a.value.compareTo(b.value));

    return Container(
      // ... (mevcut Container dekorasyonu aynı)
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ... (mevcut başlık ve divider aynı)
            Text("${player.name} Mülkleri", style: Theme.of(context).textTheme.headlineSmall),
            const Divider(),
            Expanded(
              child: ListView(
                controller: controller,
                children: sortedGroups.entries.map((entry) {
                  final color = entry.key;
                  final properties = entry.value;
                  final hasMonopoly = gameState.playerHasMonopoly(color);

                  return Card(
                    // ... (mevcut Card ve başlık kısmı aynı)
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          // ...
                          ...properties.map((tile) {
                            int tileIndex = gameState.gameTiles!.indexOf(tile);
                            
                            // --- GÜNCELLENDİ: ListTile'daki trailing (sondaki) widget ---
                            return ListTile(
                              title: Text(tile.name),
                              subtitle: Text(tile.isMortgaged ? "İpotekli" : "${tile.houseCount} Ev Var"),
                              trailing: Wrap( // Butonları yan yana sığdırmak için Wrap
                                spacing: 4,
                                children: [
                                  // Ev Yapma Butonu
                                  ElevatedButton(
                                    onPressed: hasMonopoly && !tile.isMortgaged && tile.houseCount < 5 && player.money >= tile.housePrice!
                                      ? () => context.read<GameState>().buildHouse(tileIndex)
                                      : null,
                                    child: const Icon(Icons.home),
                                  ),
                                  // İpotek Butonu
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: tile.isMortgaged ? Colors.green : Colors.red,
                                    ),
                                    onPressed: () {
                                      if (tile.isMortgaged) {
                                        context.read<GameState>().liftMortgage(tileIndex);
                                      } else {
                                        context.read<GameState>().mortgageProperty(tileIndex);
                                      }
                                    },
                                    child: Icon(tile.isMortgaged ? Icons.lock_open : Icons.lock),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}