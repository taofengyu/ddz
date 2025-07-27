import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card.dart';
import '../models/card_combination.dart';

enum GameState {
  waiting, // 等待开始
  dealing, // 发牌中
  bidding, // 叫地主
  playing, // 游戏中
  finished, // 游戏结束
}

enum PlayerType {
  player, // 玩家
  leftAI, // 左家AI
  rightAI, // 右家AI
}

class GameProvider extends ChangeNotifier {
  // 游戏状态
  GameState _gameState = GameState.waiting;
  GameState get gameState => _gameState;

  // 玩家手牌
  List<PlayingCard> _playerCards = [];
  List<PlayingCard> _leftAICards = [];
  List<PlayingCard> _rightAICards = [];
  List<PlayingCard> _landlordCards = []; // 地主牌

  List<PlayingCard> get playerCards => _playerCards;
  List<PlayingCard> get leftAICards => _leftAICards;
  List<PlayingCard> get rightAICards => _rightAICards;
  List<PlayingCard> get landlordCards => _landlordCards;

  // 当前出牌
  List<PlayingCard> _currentPlay = [];
  List<PlayingCard> get currentPlay => _currentPlay;

  // 最后出牌的人和牌（用于显示）
  List<PlayingCard> _lastPlay = [];
  PlayerType? _lastPlayer;
  List<PlayingCard> get lastPlay => _lastPlay;
  PlayerType? get lastPlayer => _lastPlayer;

  List<PlayingCard> get leftLastPlay =>
      _lastPlayer == PlayerType.leftAI ? _lastPlay : [];
  List<PlayingCard> get playerLastPlay =>
      _lastPlayer == PlayerType.player ? _lastPlay : [];
  List<PlayingCard> get rightLastPlay =>
      _lastPlayer == PlayerType.rightAI ? _lastPlay : [];

  // 当前玩家
  PlayerType _currentPlayer = PlayerType.player;
  PlayerType get currentPlayer => _currentPlayer;

  // 地主
  PlayerType? _landlord;
  PlayerType? get landlord => _landlord;

  // 选中的牌
  List<PlayingCard> _selectedCards = [];
  List<PlayingCard> get selectedCards => _selectedCards;

  // 游戏结果
  PlayerType? _winner;
  PlayerType? get winner => _winner;

  // 分数
  int _playerScore = 0;
  int _leftAIScore = 0;
  int _rightAIScore = 0;

  int get playerScore => _playerScore;
  int get leftAIScore => _leftAIScore;
  int get rightAIScore => _rightAIScore;

  // 叫分相关
  int _currentBid = 0;
  int _maxBid = 0;
  PlayerType? _maxBidder;
  int _passCount = 0; // 连续过牌次数

  int get currentBid => _currentBid;
  int get maxBid => _maxBid;
  PlayerType? get maxBidder => _maxBidder;

  // 底分和倍数相关
  int _baseScore = 2; // 底分，默认为2
  int _multiplier = 1; // 倍数，默认为1
  int _bombCount = 0; // 炸弹数量
  bool _isSpring = false; // 是否春天
  bool _isAntiSpring = false; // 是否反春天

  int get baseScore => _baseScore;
  int get multiplier => _multiplier;
  int get bombCount => _bombCount;
  bool get isSpring => _isSpring;
  bool get isAntiSpring => _isAntiSpring;

  // 初始化游戏
  void initGame() {
    _gameState = GameState.dealing;
    _playerCards = [];
    _leftAICards = [];
    _rightAICards = [];
    _landlordCards = [];
    _currentPlay = [];
    _lastPlay = [];
    _lastPlayer = null;
    _currentPlayer = PlayerType.player;
    _landlord = null;
    _selectedCards = [];
    _winner = null;
    _currentBid = 0;
    _maxBid = 0;
    _maxBidder = null;
    _passCount = 0;

    // 重置底分和倍数
    _baseScore = 2;
    _multiplier = 1;
    _bombCount = 0;
    _isSpring = false;
    _isAntiSpring = false;

    notifyListeners();

    _dealCards();
  }

  // 发牌
  void _dealCards() {
    List<PlayingCard> allCards = _generateDeck();
    allCards.shuffle(Random());

    // 发牌给三个玩家
    for (int i = 0; i < 51; i++) {
      if (i % 3 == 0) {
        _playerCards.add(allCards[i]);
      } else if (i % 3 == 1) {
        _leftAICards.add(allCards[i]);
      } else {
        _rightAICards.add(allCards[i]);
      }
    }

    // 剩余3张为地主牌
    _landlordCards = allCards.sublist(51);

    // 排序手牌
    _sortCards(_playerCards);
    _sortCards(_leftAICards);
    _sortCards(_rightAICards);

    _gameState = GameState.bidding;
    notifyListeners();
  }

  // 生成一副牌
  List<PlayingCard> _generateDeck() {
    List<PlayingCard> deck = [];

    // 生成普通牌
    for (Suit suit in [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs]) {
      for (Rank rank in [
        Rank.three,
        Rank.four,
        Rank.five,
        Rank.six,
        Rank.seven,
        Rank.eight,
        Rank.nine,
        Rank.ten,
        Rank.jack,
        Rank.queen,
        Rank.king,
        Rank.ace,
        Rank.two
      ]) {
        deck.add(PlayingCard(suit: suit, rank: rank));
      }
    }

    // 添加大小王
    deck.add(PlayingCard(suit: Suit.joker, rank: Rank.smallJoker));
    deck.add(PlayingCard(suit: Suit.joker, rank: Rank.bigJoker));

    return deck;
  }

  // 排序手牌
  void _sortCards(List<PlayingCard> cards) {
    cards.sort((a, b) => b.value.compareTo(a.value));
  }

  // 叫分
  void bid(int bidScore) {
    if (_gameState != GameState.bidding) return;
    if (bidScore <= _maxBid) return; // 叫分必须高于前面的玩家

    _maxBid = bidScore;
    _maxBidder = _currentPlayer;

    if (bidScore == 3) {
      // 叫3分直接成为地主
      _setLandlord(_currentPlayer);
    } else {
      // 继续叫分
      _nextBidder();
    }
  }

  // 不叫分
  void passBid() {
    if (_gameState != GameState.bidding) return;

    _passCount++;
    if (_passCount >= 3) {
      // 三家都不叫分，重新洗牌
      if (_maxBidder == null) {
        initGame();
        return;
      }
      // 最高叫分者成为地主
      _setLandlord(_maxBidder!);
    } else {
      _nextBidder();
    }
  }

  // 下一个叫分者
  void _nextBidder() {
    switch (_currentPlayer) {
      case PlayerType.player:
        _currentPlayer = PlayerType.leftAI;
        _aiBid();
        break;
      case PlayerType.leftAI:
        _currentPlayer = PlayerType.rightAI;
        _aiBid();
        break;
      case PlayerType.rightAI:
        _currentPlayer = PlayerType.player;
        break;
    }
    notifyListeners();
  }

  // AI叫分
  void _aiBid() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (_gameState != GameState.bidding) return;

      // 简单的AI叫分逻辑
      int aiBid = _getAIBid();
      if (aiBid > _maxBid) {
        bid(aiBid);
      } else {
        passBid();
      }
    });
  }

  // AI叫分逻辑
  int _getAIBid() {
    List<PlayingCard> aiCards =
        _currentPlayer == PlayerType.leftAI ? _leftAICards : _rightAICards;

    // 计算手牌质量
    int quality = _calculateHandQuality(aiCards);

    if (quality >= 80) return 3;
    if (quality >= 60) return 2;
    if (quality >= 40) return 1;
    return 0;
  }

  // 计算手牌质量
  int _calculateHandQuality(List<PlayingCard> cards) {
    int quality = 0;

    // 计算炸弹数量
    Map<int, int> valueCount = {};
    for (var card in cards) {
      valueCount[card.value] = (valueCount[card.value] ?? 0) + 1;
    }

    // 炸弹加分
    for (var count in valueCount.values) {
      if (count == 4) quality += 30;
      if (count == 3) quality += 15;
      if (count == 2) quality += 5;
    }

    // 大小王加分
    for (var card in cards) {
      if (card.rank == Rank.bigJoker) quality += 20;
      if (card.rank == Rank.smallJoker) quality += 15;
      if (card.rank == Rank.two) quality += 10;
    }

    return quality;
  }

  // 设置地主
  void _setLandlord(PlayerType player) {
    _landlord = player;
    _currentPlayer = player;

    // 更新底分为叫分
    _baseScore = _maxBid;

    // 将地主牌加入地主手牌
    if (player == PlayerType.player) {
      _playerCards.addAll(_landlordCards);
      _sortCards(_playerCards);
    } else if (player == PlayerType.leftAI) {
      _leftAICards.addAll(_landlordCards);
      _sortCards(_leftAICards);
    } else {
      _rightAICards.addAll(_landlordCards);
      _sortCards(_rightAICards);
    }

    _gameState = GameState.playing;
    notifyListeners();

    // 如果地主是AI，触发AI的第一手出牌
    if (player != PlayerType.player) {
      _aiPlay();
    }
  }

  // 选择牌
  void selectCard(PlayingCard card) {
    if (_gameState != GameState.playing || _currentPlayer != PlayerType.player)
      return;

    int index = _playerCards.indexOf(card);
    if (index != -1) {
      if (_selectedCards.contains(card)) {
        _selectedCards.remove(card);
        _playerCards[index] = _playerCards[index].copyWith(isSelected: false);
      } else {
        _selectedCards.add(card);
        _playerCards[index] = _playerCards[index].copyWith(isSelected: true);
      }
      notifyListeners();
    }
  }

  // 出牌
  void playCards() {
    if (_gameState != GameState.playing || _currentPlayer != PlayerType.player)
      return;
    if (_selectedCards.isEmpty) return;

    CardCombination combination = CardCombination.analyze(_selectedCards);
    if (combination.type == CombinationType.invalid) return;

    // 检查是否能压过上家的牌
    if (_currentPlay.isNotEmpty) {
      CardCombination currentCombination =
          CardCombination.analyze(_currentPlay);
      if (!combination.canBeat(currentCombination)) return;
    }

    _playSelectedCards();
  }

  // 不出
  void pass() {
    if (_gameState != GameState.playing || _currentPlayer != PlayerType.player)
      return;
    if (_currentPlay.isEmpty) return; // 第一手不能过

    // 清空选中的牌
    _selectedCards.clear();
    for (int i = 0; i < _playerCards.length; i++) {
      if (_playerCards[i].isSelected) {
        _playerCards[i] = _playerCards[i].copyWith(isSelected: false);
      }
    }

    _passCount++;
    _nextPlayer();
  }

  // 出选中的牌
  void _playSelectedCards() {
    _currentPlay = List.from(_selectedCards);
    _lastPlay = List.from(_selectedCards); // 记录最后出牌
    _lastPlayer = PlayerType.player; // 记录最后出牌的人
    _passCount = 0; // 重置过牌计数

    // 检查是否为炸弹
    CardCombination combination = CardCombination.analyze(_selectedCards);
    if (combination.type == CombinationType.bomb ||
        combination.type == CombinationType.rocket) {
      _bombCount++;
      _updateMultiplier();
    }

    // 从手牌中移除
    for (var card in _selectedCards) {
      _playerCards.remove(card);
    }

    _selectedCards.clear();

    // 检查是否获胜
    if (_playerCards.isEmpty) {
      _checkSpring();
      _winner = PlayerType.player;
      _gameState = GameState.finished;
      _updateScore();
      notifyListeners();
      return;
    }

    _nextPlayer();
  }

  // 下一个玩家
  void _nextPlayer() {
    // 检查是否连续两人过牌
    if (_passCount >= 2) {
      _currentPlay = []; // 清空当前出牌
      _passCount = 0;
    }

    switch (_currentPlayer) {
      case PlayerType.player:
        _currentPlayer = PlayerType.leftAI;
        _aiPlay();
        break;
      case PlayerType.leftAI:
        _currentPlayer = PlayerType.rightAI;
        _aiPlay();
        break;
      case PlayerType.rightAI:
        _currentPlayer = PlayerType.player;
        break;
    }
    notifyListeners();
  }

  // AI出牌
  void _aiPlay() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (_gameState != GameState.playing) return;

      List<PlayingCard> aiCards =
          _currentPlayer == PlayerType.leftAI ? _leftAICards : _rightAICards;

      // 改进的AI逻辑
      List<PlayingCard> playCards = _getAIPlay(aiCards);

      if (playCards.isNotEmpty) {
        _currentPlay = playCards;
        _lastPlay = List.from(playCards); // 记录最后出牌
        _lastPlayer = _currentPlayer; // 记录最后出牌的人
        _passCount = 0; // 重置过牌计数

        // 检查是否为炸弹
        CardCombination combination = CardCombination.analyze(playCards);
        if (combination.type == CombinationType.bomb ||
            combination.type == CombinationType.rocket) {
          _bombCount++;
          _updateMultiplier();
        }

        // 从手牌中移除
        if (_currentPlayer == PlayerType.leftAI) {
          for (var card in playCards) {
            _leftAICards.remove(card);
          }
        } else {
          for (var card in playCards) {
            _rightAICards.remove(card);
          }
        }

        // 检查是否获胜
        if (_currentPlayer == PlayerType.leftAI && _leftAICards.isEmpty) {
          _checkSpring();
          _winner = _currentPlayer;
          _gameState = GameState.finished;
          _updateScore();
          notifyListeners();
          return;
        } else if (_currentPlayer == PlayerType.rightAI &&
            _rightAICards.isEmpty) {
          _checkSpring();
          _winner = _currentPlayer;
          _gameState = GameState.finished;
          _updateScore();
          notifyListeners();
          return;
        }
      } else {
        // AI选择过，增加过牌计数
        _passCount++;
      }

      _nextPlayer();
    });
  }

  // 改进的AI出牌逻辑
  List<PlayingCard> _getAIPlay(List<PlayingCard> aiCards) {
    if (_currentPlay.isEmpty) {
      // 第一手，出最小的牌
      return _getBestFirstPlay(aiCards);
    }

    // 尝试找到能压过上家的牌
    CardCombination currentCombination = CardCombination.analyze(_currentPlay);

    // 尝试相同牌型
    List<PlayingCard> sameTypePlay =
        _findSameTypePlay(aiCards, currentCombination);
    if (sameTypePlay.isNotEmpty) {
      return sameTypePlay;
    }

    // 尝试炸弹
    List<PlayingCard> bombPlay = _findBombPlay(aiCards);
    if (bombPlay.isNotEmpty) {
      return bombPlay;
    }

    // 尝试王炸
    List<PlayingCard> rocketPlay = _findRocketPlay(aiCards);
    if (rocketPlay.isNotEmpty) {
      return rocketPlay;
    }

    // 找不到能压过的牌，选择过
    return [];
  }

  // 获取最佳首出牌
  List<PlayingCard> _getBestFirstPlay(List<PlayingCard> aiCards) {
    if (aiCards.isEmpty) return [];

    // 优先出最小的单牌
    return [aiCards.last];
  }

  // 寻找相同牌型的出牌
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

  // 寻找更大的单牌
  List<PlayingCard> _findLargerSingle(
      List<PlayingCard> aiCards, int targetWeight) {
    for (int i = aiCards.length - 1; i >= 0; i--) {
      if (aiCards[i].value > targetWeight) {
        return [aiCards[i]];
      }
    }
    return [];
  }

  // 寻找更大的对子
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

  // 寻找更大的三张
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

  // 寻找更大的三带一
  List<PlayingCard> _findLargerThreeWithOne(
      List<PlayingCard> aiCards, int targetWeight) {
    // 简化实现：寻找三张
    List<PlayingCard> three = _findLargerThree(aiCards, targetWeight);
    if (three.isNotEmpty && aiCards.length > 3) {
      // 添加一张单牌
      for (var card in aiCards) {
        if (!three.contains(card)) {
          three.add(card);
          return three;
        }
      }
    }
    return [];
  }

  // 寻找更大的三带二
  List<PlayingCard> _findLargerThreeWithPair(
      List<PlayingCard> aiCards, int targetWeight) {
    // 简化实现：寻找三张
    List<PlayingCard> three = _findLargerThree(aiCards, targetWeight);
    if (three.isNotEmpty) {
      // 寻找对子
      List<PlayingCard> pair = _findAnyPair(aiCards, three);
      if (pair.isNotEmpty) {
        three.addAll(pair);
        return three;
      }
    }
    return [];
  }

  // 寻找任意对子
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

  // 寻找更大的顺子
  List<PlayingCard> _findLargerStraight(
      List<PlayingCard> aiCards, int targetWeight, int length) {
    // 简化实现：暂时返回空
    return [];
  }

  // 寻找更大的连对
  List<PlayingCard> _findLargerPairStraight(
      List<PlayingCard> aiCards, int targetWeight, int length) {
    // 简化实现：暂时返回空
    return [];
  }

  // 寻找更大的三顺
  List<PlayingCard> _findLargerThreeStraight(
      List<PlayingCard> aiCards, int targetWeight, int length) {
    // 简化实现：暂时返回空
    return [];
  }

  // 寻找更大的飞机带翅膀
  List<PlayingCard> _findLargerAirplaneWithWings(
      List<PlayingCard> aiCards, int targetWeight) {
    // 简化实现：暂时返回空
    return [];
  }

  // 寻找更大的四带二
  List<PlayingCard> _findLargerFourWithTwo(
      List<PlayingCard> aiCards, int targetWeight) {
    // 简化实现：暂时返回空
    return [];
  }

  // 寻找炸弹
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

  // 寻找王炸
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

  // 更新分数
  void _updateScore() {
    if (_winner == null) return;

    int finalScore = _baseScore * _multiplier; // 使用动态底分和倍数
    if (_landlord == _winner) {
      // 地主获胜
      if (_winner == PlayerType.player) {
        _playerScore += finalScore * 2;
      } else if (_winner == PlayerType.leftAI) {
        _leftAIScore += finalScore * 2;
      } else {
        _rightAIScore += finalScore * 2;
      }
    } else {
      // 农民获胜
      if (_winner == PlayerType.player) {
        _playerScore += finalScore;
      } else if (_winner == PlayerType.leftAI) {
        _leftAIScore += finalScore;
      } else {
        _rightAIScore += finalScore;
      }
    }
  }

  // 更新倍数
  void _updateMultiplier() {
    _multiplier = 1; // 基础倍数
    if (_bombCount >= 2) {
      _multiplier = 4; // 2个炸弹，4倍
    } else if (_bombCount >= 1) {
      _multiplier = 2; // 1个炸弹，2倍
    }
  }

  // 检查春天
  void _checkSpring() {
    // 检查地主是否春天（地主一次性出完所有牌）
    if (_landlord == _winner) {
      // 检查农民是否还有牌
      bool farmersHaveCards = false;
      if (_landlord != PlayerType.player && _playerCards.isNotEmpty) {
        farmersHaveCards = true;
      }
      if (_landlord != PlayerType.leftAI && _leftAICards.isNotEmpty) {
        farmersHaveCards = true;
      }
      if (_landlord != PlayerType.rightAI && _rightAICards.isNotEmpty) {
        farmersHaveCards = true;
      }

      if (!farmersHaveCards) {
        _isSpring = true;
        _multiplier *= 2; // 春天翻倍
      }
    } else {
      // 农民获胜，检查是否反春天
      if (_landlord == PlayerType.player && _playerCards.isEmpty) {
        _isAntiSpring = true;
        _multiplier *= 2; // 反春天翻倍
      } else if (_landlord == PlayerType.leftAI && _leftAICards.isEmpty) {
        _isAntiSpring = true;
        _multiplier *= 2; // 反春天翻倍
      } else if (_landlord == PlayerType.rightAI && _rightAICards.isEmpty) {
        _isAntiSpring = true;
        _multiplier *= 2; // 反春天翻倍
      }
    }
  }

  // 重新开始游戏
  void restartGame() {
    _gameState = GameState.waiting;
    notifyListeners();
  }

  // 获取当前玩家手牌数量
  int getCurrentPlayerCardCount() {
    switch (_currentPlayer) {
      case PlayerType.player:
        return _playerCards.length;
      case PlayerType.leftAI:
        return _leftAICards.length;
      case PlayerType.rightAI:
        return _rightAICards.length;
    }
  }

  // 获取玩家名称
  String getPlayerName(PlayerType player) {
    switch (player) {
      case PlayerType.player:
        return '玩家';
      case PlayerType.leftAI:
        return '左家';
      case PlayerType.rightAI:
        return '右家';
    }
  }
}
