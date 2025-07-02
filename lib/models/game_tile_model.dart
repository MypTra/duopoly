// lib/models/game_tile_model.dart

import 'package:flutter/material.dart';

enum TileType {
  property,
  chance,
  communityChest,
  tax,
  jail,
  goToJail,
  freeParking,
  start,
  station,
  utility
}

class GameTileModel {
  final String name;
  final TileType type;
  final Color? color;
  final int? price;
  final List<int>? rentLevels;
  final int? housePrice;
  final String? emoji;

  int? ownerPlayerIndex;
  int houseCount;
  bool isMortgaged; // --- YENİ ALAN ---

  GameTileModel({
    required this.name,
    required this.type,
    this.color,
    this.price,
    this.rentLevels,
    this.housePrice,
    this.emoji,
    this.ownerPlayerIndex,
    this.houseCount = 0,
    this.isMortgaged = false, // --- YENİ PARAMETRE ---
  });
}