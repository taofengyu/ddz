import 'card.dart';

enum CombinationType {
  single, // 单牌
  pair, // 对子
  threeOfAKind, // 三张
  threeWithOne, // 三带一
  threeWithPair, // 三带二
  straight, // 顺子
  pairStraight, // 连对
  threeStraight, // 三顺
  airplaneWithWings, // 飞机带翅膀
  fourWithTwo, // 四带二
  bomb, // 炸弹
  rocket, // 王炸
  invalid, // 无效牌型
}

class CardCombination {
  final List<PlayingCard> cards;
  final CombinationType type;
  final int weight;

  CardCombination({
    required this.cards,
    required this.type,
    required this.weight,
  });

  static CardCombination analyze(List<PlayingCard> cards) {
    if (cards.isEmpty)
      return CardCombination(
          cards: [], type: CombinationType.invalid, weight: 0);

    // 按值排序
    List<PlayingCard> sortedCards = List.from(cards);
    sortedCards.sort((a, b) => a.value.compareTo(b.value));

    // 检查王炸
    if (_isRocket(sortedCards)) {
      return CardCombination(
          cards: sortedCards, type: CombinationType.rocket, weight: 1000);
    }

    // 检查炸弹
    if (_isBomb(sortedCards)) {
      return CardCombination(
          cards: sortedCards,
          type: CombinationType.bomb,
          weight: sortedCards[0].value + 1000);
    }

    // 检查其他牌型
    if (_isSingle(sortedCards)) {
      return CardCombination(
          cards: sortedCards,
          type: CombinationType.single,
          weight: sortedCards[0].value);
    }

    if (_isPair(sortedCards)) {
      return CardCombination(
          cards: sortedCards,
          type: CombinationType.pair,
          weight: sortedCards[0].value);
    }

    if (_isThreeOfAKind(sortedCards)) {
      return CardCombination(
          cards: sortedCards,
          type: CombinationType.threeOfAKind,
          weight: sortedCards[0].value);
    }

    if (_isThreeWithOne(sortedCards)) {
      return CardCombination(
          cards: sortedCards,
          type: CombinationType.threeWithOne,
          weight: _getThreeValue(sortedCards));
    }

    if (_isThreeWithPair(sortedCards)) {
      return CardCombination(
          cards: sortedCards,
          type: CombinationType.threeWithPair,
          weight: _getThreeValue(sortedCards));
    }

    if (_isStraight(sortedCards)) {
      return CardCombination(
          cards: sortedCards,
          type: CombinationType.straight,
          weight: sortedCards.last.value);
    }

    if (_isPairStraight(sortedCards)) {
      return CardCombination(
          cards: sortedCards,
          type: CombinationType.pairStraight,
          weight: sortedCards.last.value);
    }

    if (_isThreeStraight(sortedCards)) {
      return CardCombination(
          cards: sortedCards,
          type: CombinationType.threeStraight,
          weight: _getThreeStraightWeight(sortedCards));
    }

    if (_isAirplaneWithWings(sortedCards)) {
      return CardCombination(
          cards: sortedCards,
          type: CombinationType.airplaneWithWings,
          weight: _getAirplaneWeight(sortedCards));
    }

    if (_isFourWithTwo(sortedCards)) {
      return CardCombination(
          cards: sortedCards,
          type: CombinationType.fourWithTwo,
          weight: _getFourValue(sortedCards));
    }

    return CardCombination(
        cards: sortedCards, type: CombinationType.invalid, weight: 0);
  }

  static bool _isRocket(List<PlayingCard> cards) {
    return cards.length == 2 &&
        cards.any((card) => card.rank == Rank.smallJoker) &&
        cards.any((card) => card.rank == Rank.bigJoker);
  }

  static bool _isBomb(List<PlayingCard> cards) {
    return cards.length == 4 &&
        cards.every((card) => card.value == cards[0].value);
  }

  static bool _isSingle(List<PlayingCard> cards) {
    return cards.length == 1;
  }

  static bool _isPair(List<PlayingCard> cards) {
    return cards.length == 2 && cards[0].value == cards[1].value;
  }

  static bool _isThreeOfAKind(List<PlayingCard> cards) {
    return cards.length == 3 &&
        cards.every((card) => card.value == cards[0].value);
  }

  static bool _isThreeWithOne(List<PlayingCard> cards) {
    if (cards.length != 4) return false;

    Map<int, int> valueCount = {};
    for (var card in cards) {
      valueCount[card.value] = (valueCount[card.value] ?? 0) + 1;
    }

    return valueCount.length == 2 && valueCount.values.contains(3);
  }

  static bool _isThreeWithPair(List<PlayingCard> cards) {
    if (cards.length != 5) return false;

    Map<int, int> valueCount = {};
    for (var card in cards) {
      valueCount[card.value] = (valueCount[card.value] ?? 0) + 1;
    }

    return valueCount.length == 2 &&
        valueCount.values.contains(3) &&
        valueCount.values.contains(2);
  }

  static bool _isStraight(List<PlayingCard> cards) {
    if (cards.length < 5) return false;

    // 不能包含2和王
    if (cards.any((card) => card.value >= 15)) return false;

    for (int i = 1; i < cards.length; i++) {
      if (cards[i].value != cards[i - 1].value + 1) return false;
    }

    return true;
  }

  static bool _isPairStraight(List<PlayingCard> cards) {
    if (cards.length < 6 || cards.length % 2 != 0) return false;

    // 不能包含2和王
    if (cards.any((card) => card.value >= 15)) return false;

    for (int i = 0; i < cards.length; i += 2) {
      if (cards[i].value != cards[i + 1].value) return false;
      if (i > 0 && cards[i].value != cards[i - 2].value + 1) return false;
    }

    return true;
  }

  static bool _isThreeStraight(List<PlayingCard> cards) {
    if (cards.length < 6 || cards.length % 3 != 0) return false;

    // 不能包含2和王
    if (cards.any((card) => card.value >= 15)) return false;

    for (int i = 0; i < cards.length; i += 3) {
      if (cards[i].value != cards[i + 1].value ||
          cards[i + 1].value != cards[i + 2].value) return false;
      if (i > 0 && cards[i].value != cards[i - 3].value + 1) return false;
    }

    return true;
  }

  static bool _isAirplaneWithWings(List<PlayingCard> cards) {
    if (cards.length < 8) return false;

    Map<int, int> valueCount = {};
    for (var card in cards) {
      valueCount[card.value] = (valueCount[card.value] ?? 0) + 1;
    }

    List<int> threeValues = valueCount.entries
        .where((entry) => entry.value >= 3)
        .map((entry) => entry.key)
        .toList();

    if (threeValues.length < 2) return false;

    threeValues.sort();
    for (int i = 1; i < threeValues.length; i++) {
      if (threeValues[i] != threeValues[i - 1] + 1) return false;
    }

    // 检查剩余牌是否为单牌或对子
    int remainingCards = cards.length - (threeValues.length * 3);
    if (remainingCards == threeValues.length) {
      // 飞机带单牌
      return true;
    } else if (remainingCards == threeValues.length * 2) {
      // 飞机带对子
      List<int> remainingValues = valueCount.entries
          .where((entry) => entry.value == 2)
          .map((entry) => entry.key)
          .toList();
      return remainingValues.length == threeValues.length;
    }

    return false;
  }

  static bool _isFourWithTwo(List<PlayingCard> cards) {
    if (cards.length != 6) return false;

    Map<int, int> valueCount = {};
    for (var card in cards) {
      valueCount[card.value] = (valueCount[card.value] ?? 0) + 1;
    }

    return valueCount.values.contains(4);
  }

  static int _getThreeValue(List<PlayingCard> cards) {
    Map<int, int> valueCount = {};
    for (var card in cards) {
      valueCount[card.value] = (valueCount[card.value] ?? 0) + 1;
    }

    return valueCount.entries.firstWhere((entry) => entry.value == 3).key;
  }

  static int _getFourValue(List<PlayingCard> cards) {
    Map<int, int> valueCount = {};
    for (var card in cards) {
      valueCount[card.value] = (valueCount[card.value] ?? 0) + 1;
    }

    return valueCount.entries.firstWhere((entry) => entry.value == 4).key;
  }

  static int _getThreeStraightWeight(List<PlayingCard> cards) {
    Map<int, int> valueCount = {};
    for (var card in cards) {
      valueCount[card.value] = (valueCount[card.value] ?? 0) + 1;
    }

    List<int> threeValues = valueCount.entries
        .where((entry) => entry.value >= 3)
        .map((entry) => entry.key)
        .toList();

    threeValues.sort();
    return threeValues.last;
  }

  static int _getAirplaneWeight(List<PlayingCard> cards) {
    Map<int, int> valueCount = {};
    for (var card in cards) {
      valueCount[card.value] = (valueCount[card.value] ?? 0) + 1;
    }

    List<int> threeValues = valueCount.entries
        .where((entry) => entry.value >= 3)
        .map((entry) => entry.key)
        .toList();

    threeValues.sort();
    return threeValues.last;
  }

  bool canBeat(CardCombination other) {
    // 王炸可以压任何牌
    if (type == CombinationType.rocket) return true;
    if (other.type == CombinationType.rocket) return false;

    // 炸弹可以压非炸弹
    if (type == CombinationType.bomb && other.type != CombinationType.bomb)
      return true;
    if (type == CombinationType.bomb && other.type == CombinationType.bomb)
      return weight > other.weight;

    // 不同牌型不能比较（除了炸弹和王炸）
    if (type != other.type) return false;

    // 相同牌型比较权重
    return weight > other.weight;
  }

  @override
  String toString() {
    String typeStr;
    switch (type) {
      case CombinationType.single:
        typeStr = '单牌';
        break;
      case CombinationType.pair:
        typeStr = '对子';
        break;
      case CombinationType.threeOfAKind:
        typeStr = '三张';
        break;
      case CombinationType.threeWithOne:
        typeStr = '三带一';
        break;
      case CombinationType.threeWithPair:
        typeStr = '三带二';
        break;
      case CombinationType.straight:
        typeStr = '顺子';
        break;
      case CombinationType.pairStraight:
        typeStr = '连对';
        break;
      case CombinationType.threeStraight:
        typeStr = '三顺';
        break;
      case CombinationType.airplaneWithWings:
        typeStr = '飞机带翅膀';
        break;
      case CombinationType.fourWithTwo:
        typeStr = '四带二';
        break;
      case CombinationType.bomb:
        typeStr = '炸弹';
        break;
      case CombinationType.rocket:
        typeStr = '王炸';
        break;
      case CombinationType.invalid:
        typeStr = '无效';
        break;
    }
    return '$typeStr: ${cards.map((c) => c.displayName).join(' ')}';
  }
}
