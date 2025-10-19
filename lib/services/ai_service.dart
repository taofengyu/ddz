import '../models/card.dart';
import '../models/card_combination.dart';
import '../providers/game_provider.dart';

/// 高级AI服务类，实现记牌和策略性出牌
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // 记牌系统 - 记录已出的牌
  final Map<int, int> _playedCards = {}; // 记录每张牌已出的数量
  final List<PlayingCard> _allPlayedCards = []; // 记录所有已出的牌
  final Map<PlayerType, List<List<PlayingCard>>> _playerPlayHistory =
      {}; // 记录每个玩家的出牌历史

  // 策略相关
  int _gamePhase = 0; // 游戏阶段：0-开局，1-中局，2-残局
  bool _isLandlord = false; // 是否为地主
  List<PlayingCard> _myCards = []; // 当前AI的手牌

  /// 重置AI状态
  void reset() {
    _playedCards.clear();
    _allPlayedCards.clear();
    _playerPlayHistory.clear();
    _gamePhase = 0;
    _isLandlord = false;
    _myCards.clear();
  }

  /// 记录已出的牌
  void recordPlayedCards(List<PlayingCard> cards, PlayerType player) {
    for (var card in cards) {
      _playedCards[card.value] = (_playedCards[card.value] ?? 0) + 1;
      _allPlayedCards.add(card);
    }

    // 记录玩家出牌历史
    if (!_playerPlayHistory.containsKey(player)) {
      _playerPlayHistory[player] = [];
    }
    _playerPlayHistory[player]!.add(List.from(cards));
  }

  /// 设置AI基本信息
  void setAIInfo(List<PlayingCard> myCards, bool isLandlord) {
    _myCards = List.from(myCards);
    _isLandlord = isLandlord;
    _updateGamePhase();
  }

  /// 更新游戏阶段
  void _updateGamePhase() {
    int playedCards = _allPlayedCards.length;

    if (playedCards < 20) {
      _gamePhase = 0; // 开局
    } else if (playedCards < 40) {
      _gamePhase = 1; // 中局
    } else {
      _gamePhase = 2; // 残局
    }
  }

  /// 获取高级AI出牌决策
  List<PlayingCard> getAdvancedAIPlay(
      List<PlayingCard> aiCards, List<PlayingCard> currentPlay) {
    _myCards = List.from(aiCards);
    _updateGamePhase();

    // 如果没有需要压过的牌，选择最佳首出
    if (currentPlay.isEmpty) {
      return _getBestFirstPlay(aiCards);
    }

    // 分析当前需要压过的牌型
    CardCombination targetCombination = CardCombination.analyze(currentPlay);

    // 获取所有可能的出牌选择
    List<List<PlayingCard>> possiblePlays =
        _getAllPossiblePlays(aiCards, targetCombination);

    if (possiblePlays.isEmpty) {
      return []; // 过牌
    }

    // 使用策略评估每个选择
    List<PlayingCard> bestPlay =
        _evaluateAndSelectBestPlay(possiblePlays, targetCombination);

    return bestPlay;
  }

  /// 获取最佳首出牌
  List<PlayingCard> _getBestFirstPlay(List<PlayingCard> aiCards) {
    // 分析手牌结构
    Map<int, int> valueCount = _getValueCount(aiCards);

    // 根据游戏阶段和身份选择策略
    if (_gamePhase == 0) {
      // 开局：优先出小牌，保留大牌
      return _getEarlyGamePlay(aiCards, valueCount);
    } else if (_gamePhase == 1) {
      // 中局：平衡出牌
      return _getMidGamePlay(aiCards, valueCount);
    } else {
      // 残局：激进出牌
      return _getLateGamePlay(aiCards, valueCount);
    }
  }

  /// 开局策略
  List<PlayingCard> _getEarlyGamePlay(
      List<PlayingCard> aiCards, Map<int, int> valueCount) {
    // 优先出单张3-7的小牌
    for (int value = 3; value <= 7; value++) {
      if (valueCount.containsKey(value) && valueCount[value] == 1) {
        return [aiCards.firstWhere((card) => card.value == value)];
      }
    }

    // 出最小的对子
    for (int value = 3; value <= 10; value++) {
      if (valueCount.containsKey(value) && valueCount[value] == 2) {
        return aiCards.where((card) => card.value == value).take(2).toList();
      }
    }

    // 出最小的三张
    for (int value = 3; value <= 10; value++) {
      if (valueCount.containsKey(value) && valueCount[value] == 3) {
        return aiCards.where((card) => card.value == value).take(3).toList();
      }
    }

    // 最后选择最小单牌
    return [aiCards.last];
  }

  /// 中局策略
  List<PlayingCard> _getMidGamePlay(
      List<PlayingCard> aiCards, Map<int, int> valueCount) {
    // 分析对手可能的牌型
    List<int> opponentLikelyValues = _getOpponentLikelyValues();

    // 优先出对手可能没有的牌
    for (int value = 3; value <= 15; value++) {
      if (valueCount.containsKey(value) &&
          valueCount[value] == 1 &&
          !opponentLikelyValues.contains(value)) {
        return [aiCards.firstWhere((card) => card.value == value)];
      }
    }

    // 默认策略
    return _getEarlyGamePlay(aiCards, valueCount);
  }

  /// 残局策略
  List<PlayingCard> _getLateGamePlay(
      List<PlayingCard> aiCards, Map<int, int> valueCount) {
    // 残局优先出大牌，快速结束
    if (aiCards.length <= 5) {
      // 手牌很少，优先出大牌
      return [aiCards.first];
    }

    // 尝试出顺子或其他大牌型
    List<PlayingCard> straight = _findBestStraight(aiCards);
    if (straight.isNotEmpty) {
      return straight;
    }

    // 出最大的单牌
    return [aiCards.first];
  }

  /// 获取所有可能的出牌选择
  List<List<PlayingCard>> _getAllPossiblePlays(
      List<PlayingCard> aiCards, CardCombination target) {
    List<List<PlayingCard>> possiblePlays = [];

    // 尝试相同牌型
    List<PlayingCard> sameType = _findSameTypePlay(aiCards, target);
    if (sameType.isNotEmpty) {
      possiblePlays.add(sameType);
    }

    // 尝试炸弹
    List<PlayingCard> bomb = _findBombPlay(aiCards);
    if (bomb.isNotEmpty) {
      possiblePlays.add(bomb);
    }

    // 尝试王炸
    List<PlayingCard> rocket = _findRocketPlay(aiCards);
    if (rocket.isNotEmpty) {
      possiblePlays.add(rocket);
    }

    return possiblePlays;
  }

  /// 评估并选择最佳出牌
  List<PlayingCard> _evaluateAndSelectBestPlay(
      List<List<PlayingCard>> possiblePlays, CardCombination target) {
    if (possiblePlays.isEmpty) return [];

    double bestScore = double.negativeInfinity;
    List<PlayingCard> bestPlay = possiblePlays.first;

    for (var play in possiblePlays) {
      double score = _evaluatePlay(play, target);
      if (score > bestScore) {
        bestScore = score;
        bestPlay = play;
      }
    }

    return bestPlay;
  }

  /// 评估出牌的价值
  double _evaluatePlay(List<PlayingCard> play, CardCombination target) {
    double score = 0.0;
    CardCombination combination = CardCombination.analyze(play);

    // 基础分数：能压过目标牌
    if (combination.canBeat(target)) {
      score += 100;
    }

    // 牌型价值
    switch (combination.type) {
      case CombinationType.single:
        score += _evaluateSingle(play);
        break;
      case CombinationType.pair:
        score += _evaluatePair(play);
        break;
      case CombinationType.threeOfAKind:
        score += _evaluateThree(play);
        break;
      case CombinationType.bomb:
        score += _evaluateBomb(play);
        break;
      case CombinationType.rocket:
        score += _evaluateRocket(play);
        break;
      case CombinationType.straight:
        score += _evaluateStraight(play);
        break;
      default:
        score += 50; // 其他牌型基础分数
    }

    // 策略考虑
    score += _evaluateStrategicValue(play);

    // 风险考虑
    score -= _evaluateRisk(play);

    return score;
  }

  /// 评估单牌价值
  double _evaluateSingle(List<PlayingCard> play) {
    if (play.isEmpty) return 0;

    int value = play.first.value;
    double score = 0;

    // 小牌价值更高（更容易被压过，但消耗对手资源）
    if (value <= 7)
      score += 20;
    else if (value <= 10)
      score += 10;
    else if (value <= 13)
      score += 5;
    else if (value <= 15)
      score -= 5; // 2的价值较低
    else
      score += 15; // 王的价值高

    return score;
  }

  /// 评估对子价值
  double _evaluatePair(List<PlayingCard> play) {
    if (play.length != 2) return 0;

    int value = play.first.value;
    double score = 10; // 对子基础分数

    // 小对子价值更高
    if (value <= 7)
      score += 15;
    else if (value <= 10)
      score += 10;
    else if (value <= 13) score += 5;

    return score;
  }

  /// 评估三张价值
  double _evaluateThree(List<PlayingCard> play) {
    if (play.length != 3) return 0;

    int value = play.first.value;
    double score = 20; // 三张基础分数

    // 小三张价值更高
    if (value <= 7)
      score += 20;
    else if (value <= 10)
      score += 15;
    else if (value <= 13) score += 10;

    return score;
  }

  /// 评估炸弹价值
  double _evaluateBomb(List<PlayingCard> play) {
    if (play.length != 4) return 0;

    int value = play.first.value;
    double score = 50; // 炸弹基础分数

    // 小炸弹价值更高
    if (value <= 7)
      score += 30;
    else if (value <= 10)
      score += 20;
    else if (value <= 13) score += 10;

    return score;
  }

  /// 评估王炸价值
  double _evaluateRocket(List<PlayingCard> play) {
    return 100; // 王炸固定高分
  }

  /// 评估顺子价值
  double _evaluateStraight(List<PlayingCard> play) {
    if (play.length < 5) return 0;

    double score = 30; // 顺子基础分数

    // 长顺子价值更高
    score += (play.length - 5) * 5;

    // 小顺子价值更高
    if (play.first.value <= 7)
      score += 15;
    else if (play.first.value <= 10) score += 10;

    return score;
  }

  /// 评估策略价值
  double _evaluateStrategicValue(List<PlayingCard> play) {
    double score = 0;

    // 根据游戏阶段调整
    if (_gamePhase == 0) {
      // 开局：优先出小牌
      score += _getSmallCardBonus(play);
    } else if (_gamePhase == 2) {
      // 残局：优先出大牌
      score += _getBigCardBonus(play);
    }

    // 根据身份调整
    if (_isLandlord) {
      // 地主：更激进
      score += 10;
    } else {
      // 农民：更保守
      score -= 5;
    }

    return score;
  }

  /// 小牌奖励
  double _getSmallCardBonus(List<PlayingCard> play) {
    double bonus = 0;
    for (var card in play) {
      if (card.value <= 7)
        bonus += 5;
      else if (card.value <= 10) bonus += 2;
    }
    return bonus;
  }

  /// 大牌奖励
  double _getBigCardBonus(List<PlayingCard> play) {
    double bonus = 0;
    for (var card in play) {
      if (card.value >= 14)
        bonus += 10;
      else if (card.value >= 11) bonus += 5;
    }
    return bonus;
  }

  /// 评估风险
  double _evaluateRisk(List<PlayingCard> play) {
    double risk = 0;

    // 出大牌的风险
    for (var card in play) {
      if (card.value >= 14)
        risk += 10;
      else if (card.value >= 11) risk += 5;
    }

    // 炸弹的风险（可能被更大的炸弹压过）
    CardCombination combination = CardCombination.analyze(play);
    if (combination.type == CombinationType.bomb) {
      risk += _getBombRisk(play);
    }

    return risk;
  }

  /// 获取炸弹风险
  double _getBombRisk(List<PlayingCard> play) {
    if (play.isEmpty) return 0;

    int bombValue = play.first.value;
    double risk = 0;

    // 检查是否可能有更大的炸弹
    for (int value = bombValue + 1; value <= 15; value++) {
      int playedCount = _playedCards[value] ?? 0;
      if (playedCount < 4) {
        risk += 20; // 可能有更大的炸弹
      }
    }

    // 检查王炸
    int smallJokerPlayed = _playedCards[16] ?? 0;
    int bigJokerPlayed = _playedCards[17] ?? 0;
    if (smallJokerPlayed == 0 && bigJokerPlayed == 0) {
      risk += 50; // 王炸风险
    }

    return risk;
  }

  /// 获取对手可能有的牌
  List<int> _getOpponentLikelyValues() {
    List<int> likelyValues = [];

    // 分析出牌历史，推断对手可能的牌
    for (int value = 3; value <= 17; value++) {
      int playedCount = _playedCards[value] ?? 0;

      if (value <= 15) {
        // 普通牌，如果出得少，对手可能有
        if (playedCount < 2) {
          likelyValues.add(value);
        }
      } else {
        // 王，如果没出过，对手可能有
        if (playedCount == 0) {
          likelyValues.add(value);
        }
      }
    }

    return likelyValues;
  }

  /// 寻找相同牌型的出牌（复用原有逻辑）
  List<PlayingCard> _findSameTypePlay(
      List<PlayingCard> aiCards, CardCombination target) {
    switch (target.type) {
      case CombinationType.single:
        return _findLargerSingle(aiCards, target.weight);
      case CombinationType.pair:
        return _findLargerPair(aiCards, target.weight);
      case CombinationType.threeOfAKind:
        return _findLargerThree(aiCards, target.weight);
      case CombinationType.threeWithOne:
        return _findLargerThreeWithOne(aiCards, target.weight);
      case CombinationType.threeWithPair:
        return _findLargerThreeWithPair(aiCards, target.weight);
      case CombinationType.straight:
        return _findLargerStraight(aiCards, target.weight, target.cards.length);
      case CombinationType.pairStraight:
        return _findLargerPairStraight(
            aiCards, target.weight, target.cards.length);
      case CombinationType.threeStraight:
        return _findLargerThreeStraight(
            aiCards, target.weight, target.cards.length);
      case CombinationType.airplaneWithWings:
        return _findLargerAirplaneWithWings(aiCards, target.weight);
      case CombinationType.fourWithTwo:
        return _findLargerFourWithTwo(aiCards, target.weight);
      default:
        return [];
    }
  }

  /// 寻找更大的单牌
  List<PlayingCard> _findLargerSingle(
      List<PlayingCard> aiCards, int targetWeight) {
    for (int i = aiCards.length - 1; i >= 0; i--) {
      if (aiCards[i].value > targetWeight) {
        return [aiCards[i]];
      }
    }
    return [];
  }

  /// 寻找更大的对子
  List<PlayingCard> _findLargerPair(
      List<PlayingCard> aiCards, int targetWeight) {
    for (int i = 0; i < aiCards.length - 1; i++) {
      if (aiCards[i].value == aiCards[i + 1].value &&
          aiCards[i].value > targetWeight) {
        return [aiCards[i], aiCards[i + 1]];
      }
    }
    return [];
  }

  /// 寻找更大的三张
  List<PlayingCard> _findLargerThree(
      List<PlayingCard> aiCards, int targetWeight) {
    for (int i = 0; i < aiCards.length - 2; i++) {
      if (aiCards[i].value == aiCards[i + 1].value &&
          aiCards[i + 1].value == aiCards[i + 2].value &&
          aiCards[i].value > targetWeight) {
        return [aiCards[i], aiCards[i + 1], aiCards[i + 2]];
      }
    }
    return [];
  }

  /// 寻找更大的三带一
  List<PlayingCard> _findLargerThreeWithOne(
      List<PlayingCard> aiCards, int targetWeight) {
    List<PlayingCard> three = _findLargerThree(aiCards, targetWeight);
    if (three.isNotEmpty && aiCards.length > 3) {
      for (var card in aiCards) {
        if (!three.contains(card)) {
          three.add(card);
          return three;
        }
      }
    }
    return [];
  }

  /// 寻找更大的三带二
  List<PlayingCard> _findLargerThreeWithPair(
      List<PlayingCard> aiCards, int targetWeight) {
    List<PlayingCard> three = _findLargerThree(aiCards, targetWeight);
    if (three.isNotEmpty) {
      List<PlayingCard> pair = _findAnyPair(aiCards, three);
      if (pair.isNotEmpty) {
        three.addAll(pair);
        return three;
      }
    }
    return [];
  }

  /// 寻找任意对子
  List<PlayingCard> _findAnyPair(
      List<PlayingCard> aiCards, List<PlayingCard> exclude) {
    for (int i = 0; i < aiCards.length - 1; i++) {
      if (aiCards[i].value == aiCards[i + 1].value &&
          !exclude.contains(aiCards[i]) &&
          !exclude.contains(aiCards[i + 1])) {
        return [aiCards[i], aiCards[i + 1]];
      }
    }
    return [];
  }

  /// 寻找更大的顺子
  List<PlayingCard> _findLargerStraight(
      List<PlayingCard> aiCards, int targetWeight, int length) {
    List<PlayingCard> validCards =
        aiCards.where((card) => card.value < 15).toList();

    if (validCards.length < length) return [];

    for (int start = 0; start <= validCards.length - length; start++) {
      List<PlayingCard> potentialStraight = [];
      bool isValidStraight = true;

      for (int i = 0; i < length; i++) {
        if (start + i >= validCards.length) {
          isValidStraight = false;
          break;
        }

        PlayingCard currentCard = validCards[start + i];
        potentialStraight.add(currentCard);

        if (i > 0) {
          PlayingCard prevCard = potentialStraight[i - 1];
          if (currentCard.value != prevCard.value + 1) {
            isValidStraight = false;
            break;
          }
        }
      }

      if (isValidStraight && potentialStraight.length == length) {
        int straightWeight = potentialStraight.last.value;
        if (straightWeight > targetWeight) {
          return potentialStraight;
        }
      }
    }

    return [];
  }

  /// 寻找更大的连对
  List<PlayingCard> _findLargerPairStraight(
      List<PlayingCard> aiCards, int targetWeight, int length) {
    // 简化实现
    return [];
  }

  /// 寻找更大的三顺
  List<PlayingCard> _findLargerThreeStraight(
      List<PlayingCard> aiCards, int targetWeight, int length) {
    // 简化实现
    return [];
  }

  /// 寻找更大的飞机带翅膀
  List<PlayingCard> _findLargerAirplaneWithWings(
      List<PlayingCard> aiCards, int targetWeight) {
    // 简化实现
    return [];
  }

  /// 寻找更大的四带二
  List<PlayingCard> _findLargerFourWithTwo(
      List<PlayingCard> aiCards, int targetWeight) {
    // 简化实现
    return [];
  }

  /// 寻找炸弹
  List<PlayingCard> _findBombPlay(List<PlayingCard> aiCards) {
    for (int i = 0; i < aiCards.length - 3; i++) {
      if (aiCards[i].value == aiCards[i + 1].value &&
          aiCards[i + 1].value == aiCards[i + 2].value &&
          aiCards[i + 2].value == aiCards[i + 3].value) {
        return [aiCards[i], aiCards[i + 1], aiCards[i + 2], aiCards[i + 3]];
      }
    }
    return [];
  }

  /// 寻找王炸
  List<PlayingCard> _findRocketPlay(List<PlayingCard> aiCards) {
    PlayingCard? smallJoker;
    PlayingCard? bigJoker;

    for (var card in aiCards) {
      if (card.rank == Rank.smallJoker) smallJoker = card;
      if (card.rank == Rank.bigJoker) bigJoker = card;
    }

    if (smallJoker != null && bigJoker != null) {
      return [smallJoker, bigJoker];
    }
    return [];
  }

  /// 寻找最佳顺子
  List<PlayingCard> _findBestStraight(List<PlayingCard> aiCards) {
    List<PlayingCard> validCards =
        aiCards.where((card) => card.value < 15).toList();

    if (validCards.length < 5) return [];

    // 寻找最长的顺子
    for (int length = validCards.length; length >= 5; length--) {
      for (int start = 0; start <= validCards.length - length; start++) {
        List<PlayingCard> potentialStraight = [];
        bool isValidStraight = true;

        for (int i = 0; i < length; i++) {
          if (start + i >= validCards.length) {
            isValidStraight = false;
            break;
          }

          PlayingCard currentCard = validCards[start + i];
          potentialStraight.add(currentCard);

          if (i > 0) {
            PlayingCard prevCard = potentialStraight[i - 1];
            if (currentCard.value != prevCard.value + 1) {
              isValidStraight = false;
              break;
            }
          }
        }

        if (isValidStraight && potentialStraight.length == length) {
          return potentialStraight;
        }
      }
    }

    return [];
  }

  /// 获取牌值统计
  Map<int, int> _getValueCount(List<PlayingCard> cards) {
    Map<int, int> valueCount = {};
    for (var card in cards) {
      valueCount[card.value] = (valueCount[card.value] ?? 0) + 1;
    }
    return valueCount;
  }

  /// 获取记牌信息（用于调试）
  Map<String, dynamic> getMemoryInfo() {
    return {
      'playedCards': _playedCards,
      'allPlayedCardsCount': _allPlayedCards.length,
      'gamePhase': _gamePhase,
      'isLandlord': _isLandlord,
      'myCardsCount': _myCards.length,
      'playerPlayHistory': _playerPlayHistory.map((key, value) => MapEntry(
          key.toString(),
          value
              .map((play) => play.map((card) => card.displayName).toList())
              .toList())),
    };
  }
}
