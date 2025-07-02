// lib/providers/game_state.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/player.dart';
import '../models/game_tile_model.dart';
import '../models/card_model.dart';
import '../services/sound_service.dart';

enum GameStatus {
  notStarted,
  waitingForRoll,
  botPlaying,
  inJail,
  canBuyProperty,
  showingCard,
  showingRentPaid,
  managingProperties,
  waitingForEndTurn,
  gameOver,
}

class GameState extends ChangeNotifier {
  List<Player>? players;
  List<GameTileModel>? gameTiles;
  int _currentPlayerIndex = 0;

  int dice1 = 1;
  int dice2 = 1;
  bool hasRolled = false;
  GameStatus status = GameStatus.notStarted;

  bool isDiceAnimating = false;
  int animatingDice1 = 1;
  int animatingDice2 = 1;
  Timer? _diceAnimationTimer;

  late List<CardModel> _chanceCards;
  late List<CardModel> _communityChestCards;
  String lastCardDescription = '';
  
  Player? winner;

  String? rentPayerName;
  String? rentOwnerName;
  int? rentAmount;

  Player get currentPlayer => players![_currentPlayerIndex];
  GameTileModel get currentTile => gameTiles![currentPlayer.position];

  GameState();

  @override
  void dispose() {
    _diceAnimationTimer?.cancel();
    super.dispose();
  }
  
  void startGame({required List<String> playerNames, bool hasBot = false}) {
    final colors = [
      Colors.red.shade700,
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.yellow.shade800
    ];
    
    final icons = [
      Icons.directions_car,
      Icons.pets,
      Icons.rocket_launch,
      Icons.anchor,
    ];

    players = List.generate(
      playerNames.length,
      (index) {
        bool isPlayerBot = hasBot && index == playerNames.length - 1;
        return Player(
            name: playerNames[index].isEmpty ? 'Oyuncu ${index + 1}' : playerNames[index],
            color: colors[index],
            icon: icons[index],
            isBot: isPlayerBot,
        );
      }
    );

    _setupBoard();
    _setupCards();

    _currentPlayerIndex = 0;
    dice1 = 1;
    dice2 = 1;
    hasRolled = false;
    winner = null;
    status = GameStatus.waitingForRoll;

    notifyListeners();
  }
  
  void animateAndRollDice() {
    if (isDiceAnimating) return;
    // DÜZELTME: Bot oynarken bu fonksiyonun tetiklenmemesini sağlıyoruz
    if (status != GameStatus.waitingForRoll && status != GameStatus.inJail) return;

    isDiceAnimating = true;
    notifyListeners();

    const animationSteps = 10;
    const stepInterval = Duration(milliseconds: 100);
    final random = Random();
    int ticks = 0;

    _diceAnimationTimer?.cancel();
    _diceAnimationTimer = Timer.periodic(stepInterval, (timer) {
      ticks++;
      if (ticks >= animationSteps) {
        timer.cancel();
        isDiceAnimating = false;
        rollDice();
      } else {
        animatingDice1 = random.nextInt(6) + 1;
        animatingDice2 = random.nextInt(6) + 1;
        notifyListeners();
      }
    });
  }

  void rollDice() {
    if (currentPlayer.isInJail) {
      _handleJailRoll();
      return;
    }
    
    final random = Random();
    dice1 = random.nextInt(6) + 1;
    dice2 = random.nextInt(6) + 1;
    hasRolled = true;
    SoundService.playSound('dice_roll.mp3');

    int totalRoll = dice1 + dice2;
    int oldPosition = currentPlayer.position;
    currentPlayer.position = (oldPosition + totalRoll) % 40;

    if (currentPlayer.position < oldPosition) {
      currentPlayer.money += 200;
    }

    _processTileAction();
    notifyListeners();
  }

  void _processTileAction() {
    final tile = currentTile;
    switch (tile.type) {
      case TileType.property:
      case TileType.station:
      case TileType.utility:
        if (tile.ownerPlayerIndex == null) {
          if (currentPlayer.isBot) {
            _handleBotPropertyDecision();
          } else {
            status = GameStatus.canBuyProperty;
          }
        } else if (tile.ownerPlayerIndex != _currentPlayerIndex && !tile.isMortgaged) {
          _handleRentPayment();
        } else {
          status = GameStatus.waitingForEndTurn;
        }
        break;
      
      case TileType.tax:
        SoundService.playSound('cash_register.mp3');
        currentPlayer.money -= tile.price!;
        status = GameStatus.waitingForEndTurn;
        break;

      case TileType.goToJail:
        SoundService.playSound('jail_door.mp3');
        _goToJail();
        status = GameStatus.waitingForEndTurn;
        break;

      case TileType.chance:
      case TileType.communityChest:
        SoundService.playSound('card_draw.mp3');
        if (tile.type == TileType.chance) {
          _drawChanceCard();
        } else {
          _drawCommunityChestCard();
        }
        if (currentPlayer.isBot) {
          acknowledgeCard();
        } else {
          status = GameStatus.showingCard;
        }
        break;

      default:
        status = GameStatus.waitingForEndTurn;
        break;
    }
  }

  void _handleRentPayment() {
    Player owner = players![currentTile.ownerPlayerIndex!];
    int rent = currentTile.rentLevels![currentTile.houseCount]; 

    if (currentPlayer.money < rent) {
      _declareBankruptcy(currentPlayer, owner);
    } else {
      SoundService.playSound('cash_register.mp3');
      currentPlayer.money -= rent;
      owner.money += rent;
      
      if (currentPlayer.isBot) {
        status = GameStatus.waitingForEndTurn;
      } else {
        rentPayerName = currentPlayer.name;
        rentOwnerName = owner.name;
        rentAmount = rent;
        status = GameStatus.showingRentPaid;
      }
    }
  }

  void endTurn() {
    if (status != GameStatus.waitingForEndTurn && status != GameStatus.managingProperties) return;

    _checkForWinner();
    if (status == GameStatus.gameOver) {
      notifyListeners();
      return;
    }

    do {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % players!.length;
    } while (players![_currentPlayerIndex].money < 0);

    hasRolled = false;
    if (currentPlayer.isInJail) {
      status = GameStatus.inJail;
    } else {
      status = GameStatus.waitingForRoll;
    }
    notifyListeners();

    if (currentPlayer.isBot && status != GameStatus.gameOver) {
      _playBotTurn();
    }
  }
  
  // DÜZELTME: Botun tüm sırasını yöneten, daha sağlam bir fonksiyon
  Future<void> _playBotTurn() async {
    status = GameStatus.botPlaying;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1000));

    if (currentPlayer.isInJail) {
      _handleBotJailDecision();
      await Future.delayed(const Duration(milliseconds: 1000));
    } else {
      // Bot için manuel zar animasyonu ve atışı
      isDiceAnimating = true;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 500));
      isDiceAnimating = false;
      rollDice();
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    
    // Botun aksiyonları bittikten sonra (eğer hala botun sırasıysa) turu bitir.
    if (currentPlayer.isBot && (status == GameStatus.waitingForEndTurn || status == GameStatus.managingProperties)) {
      endTurn();
    }
  }
  
  void _handleBotJailDecision() {
    if (currentPlayer.getOutOfJailCards > 0) {
      useGetOutOfJailCard();
    } else if (currentPlayer.money > 200) {
      payToGetOutOfJail();
    } else {
      rollDice(); // Animasyonsuz direkt zar atma
    }
  }

  void _handleBotPropertyDecision() {
    final tile = currentTile;
    if (currentPlayer.money > tile.price! * 3) {
      buyProperty();
    } else {
      ignoreProperty();
    }
  }

  void openPropertyManagement() {
    status = GameStatus.managingProperties;
    notifyListeners();
  }
  
  void closePropertyManagement() {
    if (currentPlayer.isInJail) {
      status = GameStatus.inJail;
    } else {
      status = GameStatus.waitingForEndTurn;
    }
    notifyListeners();
  }
  
  bool playerHasMonopoly(Color colorGroup) {
    final propertiesInGroup = gameTiles!.where((tile) => tile.color == colorGroup);
    if (propertiesInGroup.isEmpty) return false;
    return propertiesInGroup.every((tile) => tile.ownerPlayerIndex == _currentPlayerIndex);
  }

  void buildHouse(int tileIndex) {
    final tile = gameTiles![tileIndex];
    if (tile.ownerPlayerIndex != _currentPlayerIndex || tile.houseCount >= 5 || !playerHasMonopoly(tile.color!) || currentPlayer.money < tile.housePrice!) return;

    SoundService.playSound('build_house.mp3');
    currentPlayer.money -= tile.housePrice!;
    tile.houseCount++;
    notifyListeners();
  }

  void _handleJailRoll() {
    if (!currentPlayer.isInJail) return;
    final random = Random();
    dice1 = random.nextInt(6) + 1;
    dice2 = random.nextInt(6) + 1;
    hasRolled = true;
    if (dice1 == dice2) {
      currentPlayer.isInJail = false;
      currentPlayer.turnsInJail = 0;
      int totalRoll = dice1 + dice2;
      currentPlayer.position = (currentPlayer.position + totalRoll) % 40;
      _processTileAction();
    } else {
      currentPlayer.turnsInJail++;
      if (currentPlayer.turnsInJail >= 3) {
        payToGetOutOfJail();
      } else {
        status = GameStatus.waitingForEndTurn;
      }
    }
    notifyListeners();
  }

  void payToGetOutOfJail() {
    if (!currentPlayer.isInJail || currentPlayer.money < 50) return;
    SoundService.playSound('cash_register.mp3');
    currentPlayer.money -= 50;
    currentPlayer.isInJail = false;
    currentPlayer.turnsInJail = 0;
    status = GameStatus.waitingForRoll;
    notifyListeners();
  }

  void useGetOutOfJailCard() {
    if (!currentPlayer.isInJail || currentPlayer.getOutOfJailCards <= 0) return;
    currentPlayer.getOutOfJailCards--;
    currentPlayer.isInJail = false;
    currentPlayer.turnsInJail = 0;
    status = GameStatus.waitingForRoll;
    notifyListeners();
  }

  void buyProperty() {
    if (status != GameStatus.canBuyProperty && !currentPlayer.isBot) return;
    final tile = currentTile;
    if (tile.price != null && currentPlayer.money >= tile.price!) {
      SoundService.playSound('cash_register.mp3');
      currentPlayer.money -= tile.price!;
      tile.ownerPlayerIndex = _currentPlayerIndex;
      currentPlayer.ownedProperties.add(currentPlayer.position);
    }
    status = GameStatus.waitingForEndTurn;
    notifyListeners();
  }

  void ignoreProperty() {
    if (status != GameStatus.canBuyProperty && !currentPlayer.isBot) return;
    status = GameStatus.waitingForEndTurn;
    notifyListeners();
  }

  void acknowledgeCard() {
    if (status != GameStatus.showingCard && !currentPlayer.isBot) return;
    status = GameStatus.waitingForEndTurn;
    notifyListeners();
  }
  
  void acknowledgeRentPayment() {
    if (status != GameStatus.showingRentPaid) return;
    rentPayerName = null;
    rentOwnerName = null;
    rentAmount = null;
    status = GameStatus.waitingForEndTurn;
    notifyListeners();
  }

  void _goToJail() {
    currentPlayer.position = 10;
    currentPlayer.isInJail = true;
    currentPlayer.turnsInJail = 0;
  }
  
  void _declareBankruptcy(Player bankruptPlayer, Player creditor) {
    creditor.money += bankruptPlayer.money;
    bankruptPlayer.money = -1;
    // Transfer properties (can be added later)
    _checkForWinner();
    notifyListeners();
  }

  void _checkForWinner() {
    final activePlayers = players!.where((p) => p.money >= 0).toList();
    if (activePlayers.length == 1) {
      winner = activePlayers.first;
      status = GameStatus.gameOver;
    }
  }

  void _applyCardAction(CardModel card) {
    switch (card.actionType) {
      case CardActionType.gainMoney: currentPlayer.money += card.value; break;
      case CardActionType.loseMoney: currentPlayer.money -= card.value; break;
      case CardActionType.moveTo: currentPlayer.position = card.value; break;
      case CardActionType.getOutOfJailFree: currentPlayer.getOutOfJailCards++; break;
    }
  }

  void _drawChanceCard() {
    CardModel card = _chanceCards.removeAt(0);
    lastCardDescription = card.description;
    _applyCardAction(card);
    _chanceCards.add(card);
  }

  void _drawCommunityChestCard() {
    CardModel card = _communityChestCards.removeAt(0);
    lastCardDescription = card.description;
    _applyCardAction(card);
    _communityChestCards.add(card);
  }

  void mortgageProperty(int tileIndex) {
    final tile = gameTiles![tileIndex];
    if (tile.ownerPlayerIndex != _currentPlayerIndex || tile.houseCount > 0 || tile.isMortgaged) {
      return;
    }
    tile.isMortgaged = true;
    final mortgageValue = tile.price! ~/ 2;
    currentPlayer.money += mortgageValue;
    notifyListeners();
  }

  void liftMortgage(int tileIndex) {
    final tile = gameTiles![tileIndex];
    if (tile.ownerPlayerIndex != _currentPlayerIndex || !tile.isMortgaged) {
      return;
    }
    final liftingCost = (tile.price! ~/ 2 * 1.1).toInt();
    if (currentPlayer.money < liftingCost) {
      return;
    }
    currentPlayer.money -= liftingCost;
    tile.isMortgaged = false;
    notifyListeners();
  }

  void _setupCards() {
    _chanceCards = [
      CardModel(description: "Banka sana 50 TL ödüyor.", actionType: CardActionType.gainMoney, value: 50),
      CardModel(description: "Hapisten Ücretsiz Çık. Bu kartı sakla.", actionType: CardActionType.getOutOfJailFree, value: 0),
      CardModel(description: "Doğrudan Başlangıç noktasına git.", actionType: CardActionType.moveTo, value: 0),
      CardModel(description: "Trafik cezası: 15 TL öde.", actionType: CardActionType.loseMoney, value: 15),
    ];
    _communityChestCards = [
      CardModel(description: "Vergi iadesi: 20 TL kazan.", actionType: CardActionType.gainMoney, value: 20),
      CardModel(description: "Doktor masrafı: 50 TL öde.", actionType: CardActionType.loseMoney, value: 50),
      CardModel(description: "Miras kaldı: 100 TL kazan.", actionType: CardActionType.gainMoney, value: 100),
    ];
    _chanceCards.shuffle();
    _communityChestCards.shuffle();
  }

  void _setupBoard() {
    gameTiles = [
      GameTileModel(name: 'Başlangıç', type: TileType.start, emoji: '🚀'),
      GameTileModel(name: 'İstiklal Cad.', type: TileType.property, price: 60, color: Colors.brown, housePrice: 50, rentLevels: [2, 10, 30, 90, 160, 250]),
      GameTileModel(name: 'Kamu Fonu', type: TileType.communityChest, emoji: '📦'),
      GameTileModel(name: 'Taksim', type: TileType.property, price: 60, color: Colors.brown, housePrice: 50, rentLevels: [4, 20, 60, 180, 320, 450]),
      GameTileModel(name: 'Gelir Vergisi', type: TileType.tax, price: 200, emoji: '💸'),
      GameTileModel(name: 'Haydarpaşa Garı', type: TileType.station, price: 200, rentLevels: [25, 50, 100, 200], emoji: '🚂'),
      GameTileModel(name: 'Nişantaşı', type: TileType.property, price: 100, color: Colors.lightBlue, housePrice: 50, rentLevels: [6, 30, 90, 270, 400, 550]),
      GameTileModel(name: 'Şans', type: TileType.chance, emoji: '❓'),
      GameTileModel(name: 'Teşvikiye', type: TileType.property, price: 100, color: Colors.lightBlue, housePrice: 50, rentLevels: [6, 30, 90, 270, 400, 550]),
      GameTileModel(name: 'Maçka', type: TileType.property, price: 120, color: Colors.lightBlue, housePrice: 50, rentLevels: [8, 40, 100, 300, 450, 600]),
      GameTileModel(name: 'Hapis / Ziyaret', type: TileType.jail, emoji: '⛓️'),
      GameTileModel(name: 'Bağdat Cad.', type: TileType.property, price: 140, color: Colors.pink, housePrice: 100, rentLevels: [10, 50, 150, 450, 625, 750]),
      GameTileModel(name: 'Elektrik İdaresi', type: TileType.utility, price: 150, rentLevels: [4, 10], emoji: '💡'),
      GameTileModel(name: 'Erenköy', type: TileType.property, price: 140, color: Colors.pink, housePrice: 100, rentLevels: [10, 50, 150, 450, 625, 750]),
      GameTileModel(name: 'Suadiye', type: TileType.property, price: 160, color: Colors.pink, housePrice: 100, rentLevels: [12, 60, 180, 500, 700, 900]),
      GameTileModel(name: 'Marmara Üni.', type: TileType.station, price: 200, rentLevels: [25, 50, 100, 200], emoji: '🚂'),
      GameTileModel(name: 'Bostancı', type: TileType.property, price: 180, color: Colors.orange, housePrice: 100, rentLevels: [14, 70, 200, 550, 750, 950]),
      GameTileModel(name: 'Kamu Fonu', type: TileType.communityChest, emoji: '📦'),
      GameTileModel(name: 'Caddebostan', type: TileType.property, price: 180, color: Colors.orange, housePrice: 100, rentLevels: [14, 70, 200, 550, 750, 950]),
      GameTileModel(name: 'Göztepe', type: TileType.property, price: 200, color: Colors.orange, housePrice: 100, rentLevels: [16, 80, 220, 600, 800, 1000]),
      GameTileModel(name: 'Ücretsiz Otopark', type: TileType.freeParking, emoji: '🅿️'),
      GameTileModel(name: 'Bebek', type: TileType.property, price: 220, color: Colors.red, housePrice: 150, rentLevels: [18, 90, 250, 700, 875, 1050]),
      GameTileModel(name: 'Şans', type: TileType.chance, emoji: '❓'),
      GameTileModel(name: 'Etiler', type: TileType.property, price: 220, color: Colors.red, housePrice: 150, rentLevels: [18, 90, 250, 700, 875, 1050]),
      GameTileModel(name: 'Ulus', type: TileType.property, price: 240, color: Colors.red, housePrice: 150, rentLevels: [20, 100, 300, 750, 925, 1100]),
      GameTileModel(name: 'Boğaziçi Üni.', type: TileType.station, price: 200, rentLevels: [25, 50, 100, 200], emoji: '🚂'),
      GameTileModel(name: 'Levent', type: TileType.property, price: 260, color: Colors.yellow, housePrice: 150, rentLevels: [22, 110, 330, 800, 975, 1150]),
      GameTileModel(name: 'Maslak', type: TileType.property, price: 260, color: Colors.yellow, housePrice: 150, rentLevels: [22, 110, 330, 800, 975, 1150]),
      GameTileModel(name: 'Su İdaresi', type: TileType.utility, price: 150, rentLevels: [4, 10], emoji: '💧'),
      GameTileModel(name: 'İTÜ', type: TileType.property, price: 280, color: Colors.yellow, housePrice: 150, rentLevels: [24, 120, 360, 850, 1025, 1200]),
      GameTileModel(name: 'Hapise Gir', type: TileType.goToJail, emoji: '👮'),
      GameTileModel(name: 'Ankara Kalesi', type: TileType.property, price: 300, color: Colors.green, housePrice: 200, rentLevels: [26, 130, 390, 900, 1100, 1275]),
      GameTileModel(name: 'Kızılay', type: TileType.property, price: 300, color: Colors.green, housePrice: 200, rentLevels: [26, 130, 390, 900, 1100, 1275]),
      GameTileModel(name: 'Kamu Fonu', type: TileType.communityChest, emoji: '📦'),
      GameTileModel(name: 'Çankaya', type: TileType.property, price: 320, color: Colors.green, housePrice: 200, rentLevels: [28, 150, 450, 1000, 1200, 1400]),
      GameTileModel(name: 'Esenboğa Havalimanı', type: TileType.station, price: 200, rentLevels: [25, 50, 100, 200], emoji: '🚂'),
      GameTileModel(name: 'ODTÜ', type: TileType.property, price: 350, color: Colors.deepPurple, housePrice: 200, rentLevels: [35, 175, 500, 1100, 1300, 1500]),
      GameTileModel(name: 'Şans', type: TileType.chance, emoji: '❓'),
      GameTileModel(name: 'Gazi Üni.', type: TileType.property, price: 400, color: Colors.deepPurple, housePrice: 200, rentLevels: [50, 200, 600, 1400, 1700, 2000]),
      GameTileModel(name: 'Lüks Vergisi', type: TileType.tax, price: 100, emoji: '💎'),
    ];
  }
}
