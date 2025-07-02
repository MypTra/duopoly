// lib/models/card_model.dart

enum CardActionType {
  gainMoney,
  loseMoney,
  moveTo,
  getOutOfJailFree,
}

class CardModel {
  final String description;
  final CardActionType actionType;
  final int value;

  CardModel({
    required this.description,
    required this.actionType,
    required this.value,
  });
}