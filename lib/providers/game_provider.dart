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

  // 记录每个玩家最后一次出牌（包括过牌）
  bool _shouldContinuePlay = false; // 标记是否应该继续出牌
  bool get shouldContinuePlay => _shouldContinuePlay;

  // 记录每个玩家的最后动作类型
  Map<PlayerType, String> _lastAction = {}; // 'play' 或 'pass'

  // 标记是否应该显示过牌状态（一轮未结束时显示）
  bool _shouldShowPassState = false;
  bool get shouldShowPassState => _shouldShowPassState;

  // 标记是否应该显示玩家过牌状态
  bool _shouldShowPlayerPassState = false;
  bool get shouldShowPlayerPassState => _shouldShowPlayerPassState;

  // 标记是否应该显示左家过牌状态
  bool _shouldShowLeftPassState = false;
  bool get shouldShowLeftPassState => _shouldShowLeftPassState;

  // 标记是否应该显示右家过牌状态
  bool _shouldShowRightPassState = false;
  bool get shouldShowRightPassState => _shouldShowRightPassState;

  // 标记是否应该保持显示玩家的出牌状态
  bool _shouldKeepPlayerPlayState = false;
  bool get shouldKeepPlayerPlayState => _shouldKeepPlayerPlayState;

  // 记录玩家最后一次出牌的内容
  List<PlayingCard> _playerLastPlay = [];
  List<PlayingCard> get playerLastPlayContent => _playerLastPlay;

  // 记录左家最后一次出牌的内容
  List<PlayingCard> _leftAILastPlay = [];
  List<PlayingCard> get leftAILastPlayContent => _leftAILastPlay;

  // 记录右家最后一次出牌的内容
  List<PlayingCard> _rightAILastPlay = [];
  List<PlayingCard> get rightAILastPlayContent => _rightAILastPlay;

  List<PlayingCard> get leftLastPlay =>
      _lastPlayer == PlayerType.leftAI ? _lastPlay : [];
  List<PlayingCard> get playerLastPlay =>
      _lastPlayer == PlayerType.player ? _lastPlay : [];
  List<PlayingCard> get rightLastPlay =>
      _lastPlayer == PlayerType.rightAI ? _lastPlay : [];

  // 判断是否应该显示"要不起"
  bool get shouldShowLeftPass {
    bool result =
        _lastPlay.isNotEmpty && _lastAction[PlayerType.leftAI] == 'pass';
    print('shouldShowLeftPass: $result');
    print('  _lastPlayer: $_lastPlayer');
    print('  _lastPlay.isNotEmpty: ${_lastPlay.isNotEmpty}');
    print(
        '  _lastAction[PlayerType.leftAI]: ${_lastAction[PlayerType.leftAI]}');
    print('  leftLastPlay.isEmpty: ${leftLastPlay.isEmpty}');
    return result;
  }

  bool get shouldShowPlayerPass {
    bool result =
        _lastPlay.isNotEmpty && _lastAction[PlayerType.player] == 'pass';
    print('shouldShowPlayerPass: $result');
    print('  _lastPlayer: $_lastPlayer');
    print('  _lastPlay.isNotEmpty: ${_lastPlay.isNotEmpty}');
    print(
        '  _lastAction[PlayerType.player]: ${_lastAction[PlayerType.player]}');
    return result;
  }

  bool get shouldShowRightPass {
    bool result =
        _lastPlay.isNotEmpty && _lastAction[PlayerType.rightAI] == 'pass';
    print('shouldShowRightPass: $result');
    print('  _lastPlayer: $_lastPlayer');
    print('  _lastPlay.isNotEmpty: ${_lastPlay.isNotEmpty}');
    print(
        '  _lastAction[PlayerType.rightAI]: ${_lastAction[PlayerType.rightAI]}');
    return result;
  }

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
    _shouldContinuePlay = false;
    _currentPlayer = PlayerType.player;
    _landlord = null;
    _selectedCards = [];
    _winner = null;
    _currentBid = 0;
    _maxBid = 0;
    _maxBidder = null;
    _passCount = 0;
    _lastAction.clear(); // 清空最后动作记录

    // 清空出牌区相关状态
    _shouldShowPassState = false;
    _shouldShowPlayerPassState = false;
    _shouldShowLeftPassState = false;
    _shouldShowRightPassState = false;
    _shouldKeepPlayerPlayState = false;
    _playerLastPlay.clear();
    _leftAILastPlay.clear();
    _rightAILastPlay.clear();

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
    if (_currentPlay.isEmpty && !_shouldContinuePlay) return; // 第一手不能过

    // 清空选中的牌
    _selectedCards.clear();
    for (int i = 0; i < _playerCards.length; i++) {
      if (_playerCards[i].isSelected) {
        _playerCards[i] = _playerCards[i].copyWith(isSelected: false);
      }
    }

    // 清空出牌区状态
    print('玩家过牌，清空出牌区状态');
    _shouldShowPassState = false; // 重置过牌状态显示标记
    _shouldShowPlayerPassState = false; // 重置玩家过牌状态标记
    _shouldShowLeftPassState = false; // 重置左家过牌状态标记
    _shouldShowRightPassState = false; // 重置右家过牌状态标记
    _shouldKeepPlayerPlayState = false; // 重置玩家出牌状态保持标记
    _playerLastPlay.clear(); // 清空玩家出牌内容
    _leftAILastPlay.clear(); // 清空左家出牌内容
    _rightAILastPlay.clear(); // 清空右家出牌内容

    // 如果开始新一轮，重置新一轮标记
    if (_shouldContinuePlay) {
      print('玩家过牌时开始新一轮，重置新一轮标记');
      _shouldContinuePlay = false; // 重置新一轮标记
    }

    // 记录过牌状态
    _lastAction[PlayerType.player] = 'pass'; // 记录玩家过牌
    _shouldShowPlayerPassState = true; // 标记应该显示玩家过牌状态

    // 立即通知UI更新，显示"要不起"
    notifyListeners();

    print('玩家过牌后状态:');
    print(
        '  _currentPlay: ${_currentPlay.map((c) => '${c.rank}(${c.value})').toList()}');
    print(
        '  _lastPlay: ${_lastPlay.map((c) => '${c.rank}(${c.value})').toList()}');
    print('  _lastPlayer: $_lastPlayer');
    print('  _lastAction: $_lastAction');
    print('  shouldShowPlayerPass: ${shouldShowPlayerPass}');
    print('  过牌前 _passCount: $_passCount');

    _passCount++;
    print('  过牌后 _passCount: $_passCount');
    _nextPlayer();
  }

  // 出选中的牌
  void _playSelectedCards() {
    print(
        '玩家出牌: ${_selectedCards.map((c) => '${c.rank}(${c.value})').toList()}');

    // 清空出牌区状态
    print('玩家出牌，清空出牌区状态');
    _shouldShowPassState = false; // 重置过牌状态显示标记
    _shouldShowPlayerPassState = false; // 重置玩家过牌状态标记
    _shouldShowLeftPassState = false; // 重置左家过牌状态标记
    _shouldShowRightPassState = false; // 重置右家过牌状态标记
    _shouldKeepPlayerPlayState = false; // 重置玩家出牌状态保持标记
    _playerLastPlay.clear(); // 清空玩家出牌内容
    _leftAILastPlay.clear(); // 清空左家出牌内容
    _rightAILastPlay.clear(); // 清空右家出牌内容

    // 如果开始新一轮，重置游戏状态
    if (_shouldContinuePlay) {
      print('玩家开始新一轮，重置游戏状态');
      _currentPlay = [];
      _lastPlay = [];
      _lastPlayer = null;
      _lastAction.clear();
      _shouldContinuePlay = false;
    }

    // 记录新的出牌
    _currentPlay = List.from(_selectedCards);
    _lastPlay = List.from(_selectedCards); // 记录最后出牌
    _lastPlayer = PlayerType.player; // 记录最后出牌的人
    _lastAction[PlayerType.player] = 'play'; // 记录玩家出牌
    _passCount = 0; // 重置过牌计数
    _shouldKeepPlayerPlayState = true; // 标记应该保持显示玩家的出牌状态
    _playerLastPlay = List.from(_selectedCards); // 记录玩家出牌内容
    print('玩家出牌后状态:');
    print('  _shouldKeepPlayerPlayState: $_shouldKeepPlayerPlayState');
    print(
        '  _playerLastPlay: ${_playerLastPlay.map((c) => '${c.rank}(${c.value})').toList()}');
    print(
        '  _currentPlay: ${_currentPlay.map((c) => '${c.rank}(${c.value})').toList()}');
    print(
        '  _lastPlay: ${_lastPlay.map((c) => '${c.rank}(${c.value})').toList()}');
    print('  _lastPlayer: $_lastPlayer');
    print('  _lastAction: $_lastAction');

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
      print('连续两人过牌，开始新一轮');
      print(
          '  _currentPlay: ${_currentPlay.map((c) => '${c.rank}(${c.value})').toList()}');
      print(
          '  _lastPlay: ${_lastPlay.map((c) => '${c.rank}(${c.value})').toList()}');
      print('  _lastPlayer: $_lastPlayer');
      print('  _lastAction: $_lastAction');
      print('  _passCount: $_passCount');

      // 标记开始新一轮，但不立即清空出牌区状态
      // 出牌区状态将在玩家下次操作时清空
      _currentPlay = [];
      _lastPlay = [];
      _lastPlayer = null;
      _lastAction.clear();
      _passCount = 0;
      _shouldContinuePlay = true; // 标记应该继续出牌
      // 不清空过牌状态显示标记，保持出牌区显示
      // 不清空玩家出牌状态保持标记，保持出牌区显示
      // 不清空AI出牌内容，保持出牌区显示

      print('新一轮标记后的状态:');
      print(
          '  _currentPlay: ${_currentPlay.map((c) => '${c.rank}(${c.value})').toList()}');
      print(
          '  _lastPlay: ${_lastPlay.map((c) => '${c.rank}(${c.value})').toList()}');
      print('  _lastPlayer: $_lastPlayer');
      print('  _lastAction: $_lastAction');
      print('  _passCount: $_passCount');
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
      print(
          'AI决策结果: ${playCards.map((c) => '${c.rank}(${c.value})').toList()}');

      if (playCards.isNotEmpty) {
        print(
            'AI出牌: ${playCards.map((c) => '${c.rank}(${c.value})').toList()}');

        // 记录新的出牌
        _currentPlay = playCards;
        _lastPlay = List.from(playCards); // 记录最后出牌
        _lastPlayer = _currentPlayer; // 记录最后出牌的人
        _lastAction[_currentPlayer] = 'play'; // 记录AI出牌
        _passCount = 0; // 重置过牌计数
        _shouldContinuePlay = false; // 重置新一轮标记
        // 不清空过牌状态显示标记，保持出牌区显示
        // 不清空玩家出牌状态保持标记，保持出牌区显示
        // 不清空玩家出牌内容，保持出牌区显示

        // 记录AI的出牌内容
        if (_currentPlayer == PlayerType.leftAI) {
          _leftAILastPlay = List.from(playCards);
        } else if (_currentPlayer == PlayerType.rightAI) {
          _rightAILastPlay = List.from(playCards);
        }
        print('AI出牌后状态:');
        print(
            '  _currentPlay: ${_currentPlay.map((c) => '${c.rank}(${c.value})').toList()}');
        print(
            '  _lastPlay: ${_lastPlay.map((c) => '${c.rank}(${c.value})').toList()}');
        print('  _lastPlayer: $_lastPlayer');
        print('  _lastAction: $_lastAction');

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
        print('AI实际过牌，_passCount: $_passCount');

        // 记录过牌状态 - 保持上一次出牌的内容，不清空
        // _lastPlayer 保持为出牌的玩家，不改变
        // _lastPlay 保持为需要压过的牌，不改变
        _lastAction[_currentPlayer] = 'pass'; // 记录AI过牌

        // 设置对应AI的过牌状态标记
        if (_currentPlayer == PlayerType.leftAI) {
          _shouldShowLeftPassState = true;
        } else if (_currentPlayer == PlayerType.rightAI) {
          _shouldShowRightPassState = true;
        }

        // 立即通知UI更新，显示"要不起"
        notifyListeners();

        print('AI过牌后状态:');
        print(
            '  _currentPlay: ${_currentPlay.map((c) => '${c.rank}(${c.value})').toList()}');
        print(
            '  _lastPlay: ${_lastPlay.map((c) => '${c.rank}(${c.value})').toList()}');
        print('  _lastPlayer: $_lastPlayer');
        print('  _lastAction: $_lastAction');
        print('  shouldShowLeftPass: ${shouldShowLeftPass}');
        print('  shouldShowRightPass: ${shouldShowRightPass}');
        print('  AI过牌前 _passCount: $_passCount');
      }

      _nextPlayer();
    });
  }

  // 改进的AI出牌逻辑
  List<PlayingCard> _getAIPlay(List<PlayingCard> aiCards) {
    // 如果开始新一轮，出最小的牌
    if (_shouldContinuePlay) {
      print('AI开始新一轮，出最小的牌');
      return _getBestFirstPlay(aiCards);
    }

    // 如果没有需要压过的牌，出最小的牌
    if (_currentPlay.isEmpty) {
      print('AI没有需要压过的牌，出最小的牌');
      return _getBestFirstPlay(aiCards);
    }

    // 尝试找到能压过上家的牌
    CardCombination currentCombination = CardCombination.analyze(_currentPlay);
    print('当前出牌: ${_currentPlay.map((c) => '${c.rank}(${c.value})').toList()}');
    print('当前组合类型: ${currentCombination.type}');
    print('当前组合权重: ${currentCombination.weight}');
    print('AI手牌: ${aiCards.map((c) => '${c.rank}(${c.value})').toList()}');
    print('_shouldContinuePlay: $_shouldContinuePlay');
    print('_currentPlay.isEmpty: ${_currentPlay.isEmpty}');

    // 尝试相同牌型
    List<PlayingCard> sameTypePlay =
        _findSameTypePlay(aiCards, currentCombination);
    if (sameTypePlay.isNotEmpty) {
      print(
          'AI找到相同牌型: ${sameTypePlay.map((c) => '${c.rank}(${c.value})').toList()}');
      return sameTypePlay;
    }

    // 尝试炸弹
    List<PlayingCard> bombPlay = _findBombPlay(aiCards);
    if (bombPlay.isNotEmpty) {
      print('AI找到炸弹: ${bombPlay.map((c) => '${c.rank}(${c.value})').toList()}');
      return bombPlay;
    }
    print('AI没有找到炸弹');

    // 尝试王炸
    List<PlayingCard> rocketPlay = _findRocketPlay(aiCards);
    if (rocketPlay.isNotEmpty) {
      print(
          'AI找到王炸: ${rocketPlay.map((c) => '${c.rank}(${c.value})').toList()}');
      return rocketPlay;
    }
    print('AI没有找到王炸');

    // 找不到能压过的牌，选择过
    print('AI选择过牌');
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
    print('AI寻找更大的单牌，目标权重: $targetWeight');
    print('AI手牌: ${aiCards.map((c) => '${c.rank}(${c.value})').toList()}');
    print('AI手牌数量: ${aiCards.length}');

    for (int i = aiCards.length - 1; i >= 0; i--) {
      print(
          '检查卡片: ${aiCards[i].rank}(${aiCards[i].value}) vs 目标: $targetWeight');
      if (aiCards[i].value > targetWeight) {
        print('找到更大的牌: ${aiCards[i].rank}(${aiCards[i].value})');
        return [aiCards[i]];
      } else {
        print('卡片 ${aiCards[i].rank}(${aiCards[i].value}) 不大于目标 $targetWeight');
      }
    }
    print('没有找到更大的牌');
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
    print('AI寻找更大的顺子，目标权重: $targetWeight，长度: $length');
    print('AI手牌: ${aiCards.map((c) => '${c.rank}(${c.value})').toList()}');

    // 过滤掉2和王，因为顺子不能包含这些牌
    List<PlayingCard> validCards =
        aiCards.where((card) => card.value < 15).toList();

    if (validCards.length < length) {
      print('AI手牌不足以组成顺子');
      return [];
    }

    // 寻找所有可能的顺子
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

        // 检查是否连续
        if (i > 0) {
          PlayingCard prevCard = potentialStraight[i - 1];
          if (currentCard.value != prevCard.value + 1) {
            isValidStraight = false;
            break;
          }
        }
      }

      if (isValidStraight && potentialStraight.length == length) {
        // 检查是否比目标顺子大
        int straightWeight = potentialStraight.last.value;
        if (straightWeight > targetWeight) {
          print(
              'AI找到更大的顺子: ${potentialStraight.map((c) => '${c.rank}(${c.value})').toList()}');
          return potentialStraight;
        }
      }
    }

    print('AI没有找到更大的顺子');
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

    // 清空所有游戏状态
    _playerCards = [];
    _leftAICards = [];
    _rightAICards = [];
    _landlordCards = [];
    _currentPlay = [];
    _lastPlay = [];
    _lastPlayer = null;
    _shouldContinuePlay = false;
    _currentPlayer = PlayerType.player;
    _landlord = null;
    _selectedCards = [];
    _winner = null;
    _currentBid = 0;
    _maxBid = 0;
    _maxBidder = null;
    _passCount = 0;
    _lastAction.clear();

    // 清空出牌区相关状态
    _shouldShowPassState = false;
    _shouldShowPlayerPassState = false;
    _shouldShowLeftPassState = false;
    _shouldShowRightPassState = false;
    _shouldKeepPlayerPlayState = false;
    _playerLastPlay.clear();
    _leftAILastPlay.clear();
    _rightAILastPlay.clear();

    // 重置底分和倍数
    _baseScore = 2;
    _multiplier = 1;
    _bombCount = 0;
    _isSpring = false;
    _isAntiSpring = false;

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

  @override
  void dispose() {
    // 清理所有监听器
    super.dispose();
  }
}
