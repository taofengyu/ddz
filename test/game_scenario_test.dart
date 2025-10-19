import 'package:flutter_test/flutter_test.dart';
import 'package:ddz/models/card.dart';
import 'package:ddz/models/card_combination.dart';

void main() {
  group('Game Scenario Tests', () {
    test('模拟左家4个Q被右家4个10压过的场景', () {
      // 创建4个Q（左家出牌）
      List<PlayingCard> leftAIFourQueens = [
        PlayingCard(suit: Suit.spades, rank: Rank.queen),
        PlayingCard(suit: Suit.hearts, rank: Rank.queen),
        PlayingCard(suit: Suit.diamonds, rank: Rank.queen),
        PlayingCard(suit: Suit.clubs, rank: Rank.queen),
      ];

      // 创建4个10（右家出牌）
      List<PlayingCard> rightAIFourTens = [
        PlayingCard(suit: Suit.spades, rank: Rank.ten),
        PlayingCard(suit: Suit.hearts, rank: Rank.ten),
        PlayingCard(suit: Suit.diamonds, rank: Rank.ten),
        PlayingCard(suit: Suit.clubs, rank: Rank.ten),
      ];

      // 分析牌型
      CardCombination leftAIBomb = CardCombination.analyze(leftAIFourQueens);
      CardCombination rightAIBomb = CardCombination.analyze(rightAIFourTens);

      print('左家4个Q: ${leftAIFourQueens.map((c) => c.displayName).join(' ')}');
      print('左家炸弹权重: ${leftAIBomb.weight}');
      print('左家炸弹类型: ${leftAIBomb.type}');

      print('右家4个10: ${rightAIFourTens.map((c) => c.displayName).join(' ')}');
      print('右家炸弹权重: ${rightAIBomb.weight}');
      print('右家炸弹类型: ${rightAIBomb.type}');

      // 验证牌型识别
      expect(leftAIBomb.type, CombinationType.bomb);
      expect(rightAIBomb.type, CombinationType.bomb);

      // 验证权重比较
      expect(leftAIBomb.weight, greaterThan(rightAIBomb.weight));
      print('左家炸弹权重 > 右家炸弹权重: ${leftAIBomb.weight > rightAIBomb.weight}');

      // 验证canBeat方法
      bool rightCanBeatLeft = rightAIBomb.canBeat(leftAIBomb);
      bool leftCanBeatRight = leftAIBomb.canBeat(rightAIBomb);

      print('右家4个10能压过左家4个Q: $rightCanBeatLeft');
      print('左家4个Q能压过右家4个10: $leftCanBeatRight');

      // 根据斗地主规则，4个Q应该比4个10大
      expect(rightCanBeatLeft, false, reason: '4个10不应该能压过4个Q');
      expect(leftCanBeatRight, true, reason: '4个Q应该能压过4个10');
    });

    test('测试所有炸弹的大小顺序', () {
      Map<String, List<PlayingCard>> bombs = {
        '4个3': [
          PlayingCard(suit: Suit.spades, rank: Rank.three),
          PlayingCard(suit: Suit.hearts, rank: Rank.three),
          PlayingCard(suit: Suit.diamonds, rank: Rank.three),
          PlayingCard(suit: Suit.clubs, rank: Rank.three),
        ],
        '4个4': [
          PlayingCard(suit: Suit.spades, rank: Rank.four),
          PlayingCard(suit: Suit.hearts, rank: Rank.four),
          PlayingCard(suit: Suit.diamonds, rank: Rank.four),
          PlayingCard(suit: Suit.clubs, rank: Rank.four),
        ],
        '4个5': [
          PlayingCard(suit: Suit.spades, rank: Rank.five),
          PlayingCard(suit: Suit.hearts, rank: Rank.five),
          PlayingCard(suit: Suit.diamonds, rank: Rank.five),
          PlayingCard(suit: Suit.clubs, rank: Rank.five),
        ],
        '4个10': [
          PlayingCard(suit: Suit.spades, rank: Rank.ten),
          PlayingCard(suit: Suit.hearts, rank: Rank.ten),
          PlayingCard(suit: Suit.diamonds, rank: Rank.ten),
          PlayingCard(suit: Suit.clubs, rank: Rank.ten),
        ],
        '4个J': [
          PlayingCard(suit: Suit.spades, rank: Rank.jack),
          PlayingCard(suit: Suit.hearts, rank: Rank.jack),
          PlayingCard(suit: Suit.diamonds, rank: Rank.jack),
          PlayingCard(suit: Suit.clubs, rank: Rank.jack),
        ],
        '4个Q': [
          PlayingCard(suit: Suit.spades, rank: Rank.queen),
          PlayingCard(suit: Suit.hearts, rank: Rank.queen),
          PlayingCard(suit: Suit.diamonds, rank: Rank.queen),
          PlayingCard(suit: Suit.clubs, rank: Rank.queen),
        ],
        '4个K': [
          PlayingCard(suit: Suit.spades, rank: Rank.king),
          PlayingCard(suit: Suit.hearts, rank: Rank.king),
          PlayingCard(suit: Suit.diamonds, rank: Rank.king),
          PlayingCard(suit: Suit.clubs, rank: Rank.king),
        ],
        '4个A': [
          PlayingCard(suit: Suit.spades, rank: Rank.ace),
          PlayingCard(suit: Suit.hearts, rank: Rank.ace),
          PlayingCard(suit: Suit.diamonds, rank: Rank.ace),
          PlayingCard(suit: Suit.clubs, rank: Rank.ace),
        ],
        '4个2': [
          PlayingCard(suit: Suit.spades, rank: Rank.two),
          PlayingCard(suit: Suit.hearts, rank: Rank.two),
          PlayingCard(suit: Suit.diamonds, rank: Rank.two),
          PlayingCard(suit: Suit.clubs, rank: Rank.two),
        ],
      };

      // 分析所有炸弹
      Map<String, CardCombination> bombCombinations = {};
      bombs.forEach((name, cards) {
        bombCombinations[name] = CardCombination.analyze(cards);
        print('$name: 权重 ${bombCombinations[name]!.weight}');
      });

      // 验证大小顺序
      List<String> bombNames = bombCombinations.keys.toList();
      bombNames.sort((a, b) =>
          bombCombinations[a]!.weight.compareTo(bombCombinations[b]!.weight));

      print('\n炸弹大小顺序（从小到大）:');
      for (int i = 0; i < bombNames.length; i++) {
        print(
            '${i + 1}. ${bombNames[i]} (权重: ${bombCombinations[bombNames[i]]!.weight})');
      }

      // 验证4个Q在4个10之后
      int qIndex = bombNames.indexOf('4个Q');
      int tenIndex = bombNames.indexOf('4个10');
      expect(qIndex, greaterThan(tenIndex), reason: '4个Q应该在4个10之后（更大）');
    });
  });
}
