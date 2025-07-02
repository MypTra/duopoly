// lib/models/player.dart

import 'package:flutter/material.dart';

class Player {
  final String name;
  final Color color;
  final IconData icon;
  final bool isBot; // YENİ: Oyuncunun bot olup olmadığını belirtir
  int money;
  int position;
  List<int> ownedProperties;
  bool isInJail;
  int turnsInJail;
  int getOutOfJailCards;

  Player({
    required this.name,
    required this.color,
    required this.icon,
    this.isBot = false, // Varsayılan olarak bot değil
    this.money = 1500,
    this.position = 0,
    this.isInJail = false,
    this.turnsInJail = 0,
    this.getOutOfJailCards = 0,
  }) : ownedProperties = [];
}
