import 'package:flutter_test/flutter_test.dart';
import 'package:ddz/models/card.dart';
import 'package:ddz/models/card_combination.dart';

void main() {
  group('Bomb Comparison Tests', () {
    test('4个Q应该比4个10大', () {
      // 创建4个Q
      List<PlayingCard> fourQueens = [
        PlayingCard(suit: Suit.spades, rank: Rank.queen),
        PlayingCard(suit: Suit.hearts, rank: Rank.queen),
        PlayingCard(suit: Suit.diamonds, rank: Rank.queen),
        PlayingCard(suit: Suit.clubs, rank: Rank.queen),
      ];

      // 创建4个10
      List<PlayingCard> fourTens = [
        PlayingCard(suit: Suit.spades, rank: Rank.ten),
        PlayingCard(suit: Suit.hearts, rank: Rank.ten),
        PlayingCard(suit: Suit.diamonds, rank: Rank.ten),
        PlayingCard(suit: Suit.clubs, rank: Rank.ten),
      ];

      // 分析牌型
      CardCombination queensBomb = CardCombination.analyze(fourQueens);
      CardCombination tensBomb = CardCombination.analyze(fourTens);

      // 验证牌型
      expect(queensBomb.type, CombinationType.bomb);
      expect(tensBomb.type, CombinationType.bomb);

      // 验证权重
      print('4个Q的权重: ${queensBomb.weight}');
      print('4个10的权重: ${tensBomb.weight}');

      // 4个Q应该比4个10大
      expect(queensBomb.weight, greaterThan(tensBomb.weight));
      expect(queensBomb.canBeat(tensBomb), true);
      expect(tensBomb.canBeat(queensBomb), false);
    });

    test('炸弹大小顺序测试', () {
      List<List<PlayingCard>> bombs = [
        // 4个3
        [
          PlayingCard(suit: Suit.spades, rank: Rank.three),
          PlayingCard(suit: Suit.hearts, rank: Rank.three),
          PlayingCard(suit: Suit.diamonds, rank: Rank.three),
          PlayingCard(suit: Suit.clubs, rank: Rank.three),
        ],
        // 4个10
        [
          PlayingCard(suit: Suit.spades, rank: Rank.ten),
          PlayingCard(suit: Suit.hearts, rank: Rank.ten),
          PlayingCard(suit: Suit.diamonds, rank: Rank.ten),
          PlayingCard(suit: Suit.clubs, rank: Rank.ten),
        ],
        // 4个Q
        [
          PlayingCard(suit: Suit.spades, rank: Rank.queen),
          PlayingCard(suit: Suit.hearts, rank: Rank.queen),
          PlayingCard(suit: Suit.diamonds, rank: Rank.queen),
          PlayingCard(suit: Suit.clubs, rank: Rank.queen),
        ],
        // 4个A
        [
          PlayingCard(suit: Suit.spades, rank: Rank.ace),
          PlayingCard(suit: Suit.hearts, rank: Rank.ace),
          PlayingCard(suit: Suit.diamonds, rank: Rank.ace),
          PlayingCard(suit: Suit.clubs, rank: Rank.ace),
        ],
        // 4个2
        [
          PlayingCard(suit: Suit.spades, rank: Rank.two),
          PlayingCard(suit: Suit.hearts, rank: Rank.two),
          PlayingCard(suit: Suit.diamonds, rank: Rank.two),
          PlayingCard(suit: Suit.clubs, rank: Rank.two),
        ],
      ];

      List<CardCombination> bombCombinations =
          bombs.map((bomb) => CardCombination.analyze(bomb)).toList();

      // 验证所有都是炸弹
      for (var combination in bombCombinations) {
        expect(combination.type, CombinationType.bomb);
      }

      // 验证大小顺序：3 < 10 < Q < A < 2
      expect(bombCombinations[0].weight,
          lessThan(bombCombinations[1].weight)); // 3 < 10
      expect(bombCombinations[1].weight,
          lessThan(bombCombinations[2].weight)); // 10 < Q
      expect(bombCombinations[2].weight,
          lessThan(bombCombinations[3].weight)); // Q < A
      expect(bombCombinations[3].weight,
          lessThan(bombCombinations[4].weight)); // A < 2

      // 验证canBeat方法
      expect(bombCombinations[2].canBeat(bombCombinations[1]), true); // Q > 10
      expect(bombCombinations[1].canBeat(bombCombinations[2]), false); // 10 < Q
    });
  });
}
