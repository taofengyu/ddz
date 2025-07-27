import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card.dart';

class CardWidget extends StatelessWidget {
  final PlayingCard card;
  final bool isFaceDown;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool compactJoker; // 新增参数控制大小王是否使用紧凑显示

  const CardWidget({
    super.key,
    required this.card,
    this.isFaceDown = false,
    this.onTap,
    this.width = 60,
    this.height = 80,
    this.compactJoker = false, // 默认不使用紧凑显示
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: EdgeInsets.symmetric(horizontal: width < 30 ? 1 : 2),
        decoration: BoxDecoration(
          color: isFaceDown ? Colors.blue[800] : Colors.white,
          borderRadius: BorderRadius.circular(width < 30 ? 4 : 8),
          border: Border.all(
            color: card.isSelected ? Colors.yellow : Colors.grey[400]!,
            width: card.isSelected ? (width < 30 ? 2 : 3) : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: width < 30 ? 2 : 4,
              offset: Offset(0, width < 30 ? 1 : 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: isFaceDown ? _buildFaceDownCard() : _buildFaceUpCard(),
      ),
    );
  }

  Widget _buildFaceDownCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[700]!,
            Colors.blue[900]!,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.style,
          color: Colors.white,
          size: min(width * 0.5, height * 0.4),
        ),
      ),
    );
  }

  Widget _buildFaceUpCard() {
    // 对于小尺寸卡片，只显示左上角信息
    if (width < 30 || height < 40) {
      return ClipRect(
        child: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: EdgeInsets.all(width * 0.12), // 增加边距
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 数字显示在左上角
                if (card.rank == Rank.smallJoker || card.rank == Rank.bigJoker)
                  _buildJokerDisplay(width * 0.4, 12) // 增大最小字体大小
                else
                  Text(
                    _getRankDisplay(card.rank),
                    style: TextStyle(
                      color: card.color,
                      fontSize: max(width * 0.4, 8), // 增大字体
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                // 花色显示在数字下面
                if (card.suit != Suit.joker && height > 20)
                  Text(
                    _getSuitSymbol(card.suit),
                    style: TextStyle(
                      color: card.color,
                      fontSize: max(width * 0.35, 7), // 增大字体
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // 对于正常尺寸卡片，使用Stack精确定位
    return ClipRect(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            // 左上角 - 数字在上，花色在下
            Positioned(
              top: width * 0.08, // 增加与边框距离
              left: width * 0.08, // 增加与边框距离
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 数字显示在左上角
                  if (card.rank == Rank.smallJoker ||
                      card.rank == Rank.bigJoker)
                    _buildJokerDisplay(width * 0.25, 10) // 大小王特殊显示
                  else
                    Text(
                      _getRankDisplay(card.rank),
                      style: TextStyle(
                        color: card.color,
                        fontSize: max(width * 0.25, 10), // 增大字体
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  // 花色显示在数字下面
                  if (card.suit != Suit.joker)
                    Text(
                      _getSuitSymbol(card.suit),
                      style: TextStyle(
                        color: card.color,
                        fontSize: max(width * 0.18, 8), // 增大字体
                      ),
                    ),
                ],
              ),
            ),
            // 右下角 - 旋转180度显示
            Positioned(
              bottom: width * 0.08, // 增加与边框距离
              right: width * 0.08, // 增加与边框距离
              child: Transform.rotate(
                angle: 3.14159, // 180度
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 数字显示在左上角（旋转后变成右下角）
                    if (card.rank == Rank.smallJoker ||
                        card.rank == Rank.bigJoker)
                      _buildJokerDisplay(width * 0.25, 10) // 大小王特殊显示
                    else
                      Text(
                        _getRankDisplay(card.rank),
                        style: TextStyle(
                          color: card.color,
                          fontSize: max(width * 0.25, 10), // 增大字体
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    // 花色显示在数字下面
                    if (card.suit != Suit.joker)
                      Text(
                        _getSuitSymbol(card.suit),
                        style: TextStyle(
                          color: card.color,
                          fontSize: max(width * 0.18, 8), // 增大字体
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建大小王的竖排显示
  Widget _buildJokerDisplay(double fontSize, double minSize) {
    // 如果使用紧凑模式，显示更小的字体和更紧凑的间距
    if (compactJoker) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'J',
            style: TextStyle(
              color: card.color,
              fontSize: max(fontSize * 0.45, minSize * 0.45), // 调小字体
              fontWeight: FontWeight.w900,
              height: 0.85, // 减小行高
              shadows: [
                Shadow(
                  offset: const Offset(0.4, 0.4), // 减小阴影
                  blurRadius: 0.8,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          Text(
            'O',
            style: TextStyle(
              color: card.color,
              fontSize: max(fontSize * 0.45, minSize * 0.45), // 调小字体
              fontWeight: FontWeight.w900,
              height: 0.85, // 减小行高
              shadows: [
                Shadow(
                  offset: const Offset(0.4, 0.4), // 减小阴影
                  blurRadius: 0.8,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          Text(
            'K',
            style: TextStyle(
              color: card.color,
              fontSize: max(fontSize * 0.45, minSize * 0.45), // 调小字体
              fontWeight: FontWeight.w900,
              height: 0.85, // 减小行高
              shadows: [
                Shadow(
                  offset: const Offset(0.4, 0.4), // 减小阴影
                  blurRadius: 0.8,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          Text(
            'E',
            style: TextStyle(
              color: card.color,
              fontSize: max(fontSize * 0.45, minSize * 0.45), // 调小字体
              fontWeight: FontWeight.w900,
              height: 0.85, // 减小行高
              shadows: [
                Shadow(
                  offset: const Offset(0.4, 0.4), // 减小阴影
                  blurRadius: 0.8,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          Text(
            'R',
            style: TextStyle(
              color: card.color,
              fontSize: max(fontSize * 0.45, minSize * 0.45), // 调小字体
              fontWeight: FontWeight.w900,
              height: 0.85, // 减小行高
              shadows: [
                Shadow(
                  offset: const Offset(0.4, 0.4), // 减小阴影
                  blurRadius: 0.8,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 默认显示方式
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'J',
          style: TextStyle(
            color: card.color,
            fontSize: max(fontSize * 0.5, minSize * 0.5),
            fontWeight: FontWeight.w900, // 使用最粗的字体
            shadows: [
              Shadow(
                offset: const Offset(0.5, 0.5),
                blurRadius: 1,
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
        Text(
          'O',
          style: TextStyle(
            color: card.color,
            fontSize: max(fontSize * 0.5, minSize * 0.5),
            fontWeight: FontWeight.w900, // 使用最粗的字体
            shadows: [
              Shadow(
                offset: const Offset(0.5, 0.5),
                blurRadius: 1,
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
        Text(
          'K',
          style: TextStyle(
            color: card.color,
            fontSize: max(fontSize * 0.5, minSize * 0.5),
            fontWeight: FontWeight.w900, // 使用最粗的字体
            shadows: [
              Shadow(
                offset: const Offset(0.5, 0.5),
                blurRadius: 1,
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
        Text(
          'E',
          style: TextStyle(
            color: card.color,
            fontSize: max(fontSize * 0.5, minSize * 0.5),
            fontWeight: FontWeight.w900, // 使用最粗的字体
            shadows: [
              Shadow(
                offset: const Offset(0.5, 0.5),
                blurRadius: 1,
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
        Text(
          'R',
          style: TextStyle(
            color: card.color,
            fontSize: max(fontSize * 0.5, minSize * 0.5),
            fontWeight: FontWeight.w900, // 使用最粗的字体
            shadows: [
              Shadow(
                offset: const Offset(0.5, 0.5),
                blurRadius: 1,
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 获取数字显示文本
  String _getRankDisplay(Rank rank) {
    switch (rank) {
      case Rank.three:
        return '3';
      case Rank.four:
        return '4';
      case Rank.five:
        return '5';
      case Rank.six:
        return '6';
      case Rank.seven:
        return '7';
      case Rank.eight:
        return '8';
      case Rank.nine:
        return '9';
      case Rank.ten:
        return '10';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'K';
      case Rank.ace:
        return 'A';
      case Rank.two:
        return '2';
      case Rank.smallJoker:
        return '小王'; // 改为中文显示
      case Rank.bigJoker:
        return '大王'; // 改为中文显示
    }
  }

  String _getSuitSymbol(Suit suit) {
    switch (suit) {
      case Suit.spades:
        return '♠';
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
      default:
        return '';
    }
  }
}
