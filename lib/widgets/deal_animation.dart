import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'dart:math' as math;
import '../models/card.dart';
import '../widgets/card_widget.dart';

class DealAnimation extends StatefulWidget {
  final List<PlayingCard> cards;
  final VoidCallback onComplete;
  final Duration duration;
  final GlobalKey? playerHandKey; // 玩家手牌区域的GlobalKey
  final GlobalKey? playerStackKey; // 玩家手牌Stack的GlobalKey
  final GlobalKey? leftAIHandKey; // 左家AI手牌区域的GlobalKey
  final GlobalKey? rightAIHandKey; // 右家AI手牌区域的GlobalKey
  final GlobalKey? landlordCardsKey; // 地主牌区域的GlobalKey

  const DealAnimation({
    super.key,
    required this.cards,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 2000),
    this.playerHandKey,
    this.leftAIHandKey,
    this.rightAIHandKey,
    this.landlordCardsKey,
    this.playerStackKey,
  });

  @override
  State<DealAnimation> createState() => _DealAnimationState();
}

class _DealAnimationState extends State<DealAnimation> {
  // 不再需要 AnimationController

  List<PlayingCard> _dealtCards = [];
  int _currentCardIndex = 0;
  Set<int> _flippedPlayerCards = {}; // 记录已翻牌的玩家牌索引

  // 手牌区域位置
  late Offset _playerHandPosition;
  late Offset _leftAIHandPosition;
  late Offset _rightAIHandPosition;

  @override
  void initState() {
    super.initState();
    _startDealing();
  }

  void _startDealing() {
    const int perCard = 30; // 每张牌的固定间隔（毫秒）- 加快发牌速度
    for (int i = 0; i < widget.cards.length; i++) {
      Future.delayed(Duration(milliseconds: perCard * i), () {
        if (!mounted) return;
        setState(() {
          _dealtCards.add(widget.cards[i]);
          _currentCardIndex = i;
        });

        // 如果是玩家牌且到达目标位置，延迟翻牌
        final bool isPlayerCard = (i % 3) == 0;
        if (isPlayerCard) {
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) {
              setState(() {
                _flippedPlayerCards.add(i); // 标记这张玩家牌已翻牌
              });
            }
          });
        }

        // 最后一张牌落定后回调完成
        if (i == widget.cards.length - 1) {
          Future.delayed(const Duration(milliseconds: 300), widget.onComplete);
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // 计算手牌区域位置
    _playerHandPosition =
        Offset(screenSize.width * 0.5, screenSize.height * 0.85);
    // 调整AI手牌区域位置，完全避开头像区域，放在屏幕底部边缘
    _leftAIHandPosition =
        Offset(screenSize.width * 0.1, screenSize.height * 0.9);
    _rightAIHandPosition =
        Offset(screenSize.width * 0.9, screenSize.height * 0.9);

    return Stack(
      children: [
        // 发牌动画
        ..._buildDealingCards(),
      ],
    );
  }

  List<Widget> _buildDealingCards() {
    List<Widget> cards = [];

    for (int i = 0; i < _dealtCards.length; i++) {
      final card = _dealtCards[i];
      final targetPosition = _getTargetPosition(i);
      final isFlying = i == _currentCardIndex;
      final bool isPlayerCard = (i % 3) == 0;
      final double cardWidth = isPlayerCard ? 60.0 : 50.0;
      final double cardHeight = isPlayerCard ? 80.0 : 70.0;

      final cardWidget = AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        left: isFlying ? _getCardPosition(i).dx : targetPosition.dx,
        top: isFlying ? _getCardPosition(i).dy : targetPosition.dy,
        child: Transform.rotate(
          angle: isFlying ? _getCardRotation(i) : 0.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
            child: CardWidget(
              card: card,
              isFaceDown: isPlayerCard
                  ? !_flippedPlayerCards.contains(i)
                  : true, // 玩家牌到达目标位置后才翻牌，AI牌始终保持背面
              onTap: () {},
              width: cardWidth,
              height: cardHeight,
            ),
          ),
        ),
      );

      cards.add(cardWidget);
    }

    return cards;
  }

  Offset _getCardPosition(int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 起始位置（牌堆中心）
    final startX = screenWidth * 0.5 - 25; // 减去牌宽度的一半
    final startY = screenHeight * 0.4 - 35; // 减去牌高度的一半

    return Offset(startX, startY);
  }

  Offset _getTargetPosition(int index) {
    // 地主牌（最后三张）
    if (index >= 51) {
      RenderBox? landlordBox = widget.landlordCardsKey?.currentContext
          ?.findRenderObject() as RenderBox?;
      if (landlordBox != null) {
        Offset landlordOffset = landlordBox.localToGlobal(Offset.zero);
        return Offset(
          landlordOffset.dx + landlordBox.size.width / 2 - 25,
          landlordOffset.dy + landlordBox.size.height / 2 - 35,
        );
      }
      // fallback: center top area
      final screen = MediaQuery.of(context).size;
      return Offset(screen.width / 2 - 25, screen.height * 0.3);
    }

    // 根据牌的位置分配到不同玩家
    final playerIndex = index % 3;

    // 获取实际手牌区域的位置
    RenderBox? targetRenderBox;
    Offset targetOffset = Offset.zero;

    switch (playerIndex) {
      case 0: // 玩家
        targetRenderBox = widget.playerHandKey?.currentContext
            ?.findRenderObject() as RenderBox?;
        if (targetRenderBox != null) {
          targetOffset = targetRenderBox.localToGlobal(Offset.zero);
          // 计算玩家手牌区域的精确位置
          return _getPlayerCardPosition(
              index, targetOffset, targetRenderBox.size);
        }
        break;
      case 1: // 左家AI
        targetRenderBox = widget.leftAIHandKey?.currentContext
            ?.findRenderObject() as RenderBox?;
        if (targetRenderBox != null) {
          targetOffset = targetRenderBox.localToGlobal(Offset.zero);
          // 左家AI：将牌发到头像右侧，避免遮挡
          return Offset(
            targetOffset.dx + targetRenderBox.size.width + 5,
            targetOffset.dy + targetRenderBox.size.height / 2 - 35,
          );
        }
        break;
      case 2: // 右家AI
        targetRenderBox = widget.rightAIHandKey?.currentContext
            ?.findRenderObject() as RenderBox?;
        if (targetRenderBox != null) {
          targetOffset = targetRenderBox.localToGlobal(Offset.zero);
          // 右家AI：将牌发到头像左侧，避免遮挡
          return Offset(
            targetOffset.dx - 50 - 5, // 50 为牌宽度
            targetOffset.dy + targetRenderBox.size.height / 2 - 35,
          );
        }
        break;
    }

    // 如果无法获取实际位置，使用默认位置
    switch (playerIndex) {
      case 0: // 玩家
        return Offset(_playerHandPosition.dx - 30, _playerHandPosition.dy - 40);
      case 1: // 左家AI
        return Offset(_leftAIHandPosition.dx - 25, _leftAIHandPosition.dy - 35);
      case 2: // 右家AI
        return Offset(
            _rightAIHandPosition.dx - 25, _rightAIHandPosition.dy - 35);
      default:
        return Offset(_playerHandPosition.dx - 25, _playerHandPosition.dy - 35);
    }
  }

  double _getCardRotation(int index) {
    // 根据目标位置添加轻微旋转
    final playerIndex = index % 3;
    switch (playerIndex) {
      case 0: // 玩家
        return 0.0;
      case 1: // 左家AI
        return -0.2;
      case 2: // 右家AI
        return 0.2;
      default:
        return 0.0;
    }
  }

  // 计算玩家手牌区域中每张牌的位置
  Offset _getPlayerCardPosition(
      int index, Offset targetOffset, Size targetSize) {
    // 计算这是玩家的第几张牌
    int playerCardIndex = index ~/ 3;

    // 手牌排列参数（与游戏界面保持一致）
    double cardWidth = 60.0;
    double cardOverlap = 25.0;

    // 玩家总手牌数量（不包括地主牌）
    int totalCards = math.min(17, playerCardIndex + 1);
    // 计算总宽度和起始位置（使用最终总牌数，确保动画与最终排布一致）
    double totalWidth = (totalCards - 1) * cardOverlap + cardWidth;
    // Container 内部左右可能有 20px padding（Android）
    double horizontalPadding = Platform.isAndroid ? 20.0 : 0.0;
    double usableWidth = targetSize.width - horizontalPadding * 2;
    double startLeft = horizontalPadding + (usableWidth - totalWidth) / 2;

    // 如果提供了StackKey，直接用Stack的全局坐标
    if (widget.playerStackKey?.currentContext != null) {
      RenderBox stackBox = widget.playerStackKey!.currentContext!
          .findRenderObject() as RenderBox;
      Offset stackOffset = stackBox.localToGlobal(Offset.zero);
      Size stackSize = stackBox.size;

      // 计算与最终手牌一致的居中起点
      double totalWidth = (17 - 1) * cardOverlap + cardWidth;
      double centerStart = (stackSize.width - totalWidth) / 2;
      double cardLeft =
          stackOffset.dx + centerStart + playerCardIndex * cardOverlap;
      double cardTop = stackOffset.dy + stackSize.height - 80.0; // cardHeight

      return Offset(cardLeft, cardTop);
    }

    double cardLeft = startLeft + playerCardIndex * cardOverlap;
    const double cardHeight = 80.0;
    const double topContentHeight = 100.0;
    double cardTop =
        targetOffset.dy + targetSize.height - topContentHeight - cardHeight;

    return Offset(targetOffset.dx + cardLeft, cardTop);
  }
}
