import 'package:flutter/material.dart';

enum Suit { spades, hearts, diamonds, clubs, joker }

enum Rank {
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace,
  two,
  smallJoker,
  bigJoker
}

class PlayingCard {
  final Suit suit;
  final Rank rank;
  final bool isSelected;

  const PlayingCard({
    required this.suit,
    required this.rank,
    this.isSelected = false,
  });

  PlayingCard copyWith({bool? isSelected}) {
    return PlayingCard(
      suit: suit,
      rank: rank,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  int get value {
    switch (rank) {
      case Rank.three:
        return 3;
      case Rank.four:
        return 4;
      case Rank.five:
        return 5;
      case Rank.six:
        return 6;
      case Rank.seven:
        return 7;
      case Rank.eight:
        return 8;
      case Rank.nine:
        return 9;
      case Rank.ten:
        return 10;
      case Rank.jack:
        return 11;
      case Rank.queen:
        return 12;
      case Rank.king:
        return 13;
      case Rank.ace:
        return 14;
      case Rank.two:
        return 15;
      case Rank.smallJoker:
        return 16;
      case Rank.bigJoker:
        return 17;
    }
  }

  // 获取牌的分值（用于炸弹比较）
  int get score {
    switch (rank) {
      case Rank.three:
        return 3;
      case Rank.four:
        return 4;
      case Rank.five:
        return 5;
      case Rank.six:
        return 6;
      case Rank.seven:
        return 7;
      case Rank.eight:
        return 8;
      case Rank.nine:
        return 9;
      case Rank.ten:
        return 10;
      case Rank.jack:
        return 11;
      case Rank.queen:
        return 12;
      case Rank.king:
        return 13;
      case Rank.ace:
        return 14;
      case Rank.two:
        return 15;
      case Rank.smallJoker:
        return 16;
      case Rank.bigJoker:
        return 17;
    }
  }

  String get displayName {
    if (rank == Rank.smallJoker) return '小王';
    if (rank == Rank.bigJoker) return '大王';

    String rankStr;
    switch (rank) {
      case Rank.three:
        rankStr = '3';
        break;
      case Rank.four:
        rankStr = '4';
        break;
      case Rank.five:
        rankStr = '5';
        break;
      case Rank.six:
        rankStr = '6';
        break;
      case Rank.seven:
        rankStr = '7';
        break;
      case Rank.eight:
        rankStr = '8';
        break;
      case Rank.nine:
        rankStr = '9';
        break;
      case Rank.ten:
        rankStr = '10';
        break;
      case Rank.jack:
        rankStr = 'J';
        break;
      case Rank.queen:
        rankStr = 'Q';
        break;
      case Rank.king:
        rankStr = 'K';
        break;
      case Rank.ace:
        rankStr = 'A';
        break;
      case Rank.two:
        rankStr = '2';
        break;
      default:
        rankStr = '';
    }

    String suitStr;
    switch (suit) {
      case Suit.spades:
        suitStr = '♠';
        break;
      case Suit.hearts:
        suitStr = '♥';
        break;
      case Suit.diamonds:
        suitStr = '♦';
        break;
      case Suit.clubs:
        suitStr = '♣';
        break;
      default:
        suitStr = '';
    }

    return '$suitStr$rankStr';
  }

  Color get color {
    if (suit == Suit.hearts || suit == Suit.diamonds) {
      return Colors.red;
    }
    if (rank == Rank.bigJoker) {
      return Colors.red; // 大王用红色
    }
    if (rank == Rank.smallJoker) {
      return Colors.black; // 小王用黑色
    }
    return Colors.black;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayingCard && other.suit == suit && other.rank == rank;
  }

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;

  @override
  String toString() => displayName;
}
