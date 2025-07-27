import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ddz/models/card.dart';
import 'package:ddz/models/card_combination.dart';

void main() {
  group('PlayingCard Tests', () {
    test('should create card with correct properties', () {
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      
      expect(card.suit, Suit.hearts);
      expect(card.rank, Rank.ace);
      expect(card.value, 14);
      expect(card.displayName, '♥A');
      expect(card.color, Colors.red);
    });

    test('should handle joker cards correctly', () {
      final smallJoker = PlayingCard(suit: Suit.joker, rank: Rank.smallJoker);
      final bigJoker = PlayingCard(suit: Suit.joker, rank: Rank.bigJoker);
      
      expect(smallJoker.displayName, '小王');
      expect(bigJoker.displayName, '大王');
      expect(smallJoker.value, 16);
      expect(bigJoker.value, 17);
      expect(smallJoker.color, Colors.red);
      expect(bigJoker.color, Colors.red);
    });
  });

  group('CardCombination Tests', () {
    test('should identify single card', () {
      final cards = [PlayingCard(suit: Suit.hearts, rank: Rank.ace)];
      final combination = CardCombination.analyze(cards);
      
      expect(combination.type, CombinationType.single);
      expect(combination.weight, 14);
    });

    test('should identify pair', () {
      final cards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        PlayingCard(suit: Suit.spades, rank: Rank.ace),
      ];
      final combination = CardCombination.analyze(cards);
      
      expect(combination.type, CombinationType.pair);
      expect(combination.weight, 14);
    });

    test('should identify bomb', () {
      final cards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        PlayingCard(suit: Suit.spades, rank: Rank.ace),
        PlayingCard(suit: Suit.diamonds, rank: Rank.ace),
        PlayingCard(suit: Suit.clubs, rank: Rank.ace),
      ];
      final combination = CardCombination.analyze(cards);
      
      expect(combination.type, CombinationType.bomb);
      expect(combination.weight, 14);
    });

    test('should identify rocket', () {
      final cards = [
        PlayingCard(suit: Suit.joker, rank: Rank.smallJoker),
        PlayingCard(suit: Suit.joker, rank: Rank.bigJoker),
      ];
      final combination = CardCombination.analyze(cards);
      
      expect(combination.type, CombinationType.rocket);
      expect(combination.weight, 100);
    });

    test('should identify straight', () {
      final cards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.three),
        PlayingCard(suit: Suit.spades, rank: Rank.four),
        PlayingCard(suit: Suit.diamonds, rank: Rank.five),
        PlayingCard(suit: Suit.clubs, rank: Rank.six),
        PlayingCard(suit: Suit.hearts, rank: Rank.seven),
      ];
      final combination = CardCombination.analyze(cards);
      
      expect(combination.type, CombinationType.straight);
      expect(combination.weight, 7);
    });

    test('should identify invalid combination', () {
      final cards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        PlayingCard(suit: Suit.spades, rank: Rank.king),
        PlayingCard(suit: Suit.diamonds, rank: Rank.queen),
      ];
      final combination = CardCombination.analyze(cards);
      
      expect(combination.type, CombinationType.invalid);
      expect(combination.weight, 0);
    });
  });

  group('CardCombination Comparison Tests', () {
    test('rocket should beat everything', () {
      final rocket = CardCombination.analyze([
        PlayingCard(suit: Suit.joker, rank: Rank.smallJoker),
        PlayingCard(suit: Suit.joker, rank: Rank.bigJoker),
      ]);
      
      final bomb = CardCombination.analyze([
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        PlayingCard(suit: Suit.spades, rank: Rank.ace),
        PlayingCard(suit: Suit.diamonds, rank: Rank.ace),
        PlayingCard(suit: Suit.clubs, rank: Rank.ace),
      ]);
      
      expect(rocket.canBeat(bomb), true);
      expect(bomb.canBeat(rocket), false);
    });

    test('bomb should beat non-bomb', () {
      final bomb = CardCombination.analyze([
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        PlayingCard(suit: Suit.spades, rank: Rank.ace),
        PlayingCard(suit: Suit.diamonds, rank: Rank.ace),
        PlayingCard(suit: Suit.clubs, rank: Rank.ace),
      ]);
      
      final pair = CardCombination.analyze([
        PlayingCard(suit: Suit.hearts, rank: Rank.king),
        PlayingCard(suit: Suit.spades, rank: Rank.king),
      ]);
      
      expect(bomb.canBeat(pair), true);
      expect(pair.canBeat(bomb), false);
    });

    test('same type should compare by weight', () {
      final highPair = CardCombination.analyze([
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        PlayingCard(suit: Suit.spades, rank: Rank.ace),
      ]);
      
      final lowPair = CardCombination.analyze([
        PlayingCard(suit: Suit.hearts, rank: Rank.king),
        PlayingCard(suit: Suit.spades, rank: Rank.king),
      ]);
      
      expect(highPair.canBeat(lowPair), true);
      expect(lowPair.canBeat(highPair), false);
    });
  });
} 