import 'package:flutter_test/flutter_test.dart';
import 'package:ddz/models/card.dart';
import 'package:ddz/models/card_combination.dart';
import 'package:ddz/services/ai_service.dart';
import 'package:ddz/providers/game_provider.dart';

void main() {
  group('AIService Tests', () {
    late AIService aiService;

    setUp(() {
      aiService = AIService();
      aiService.reset();
    });

    test('AI服务初始化和重置', () {
      expect(aiService.getMemoryInfo()['playedCards'], isEmpty);
      expect(aiService.getMemoryInfo()['allPlayedCardsCount'], 0);
      expect(aiService.getMemoryInfo()['gamePhase'], 0);
      expect(aiService.getMemoryInfo()['isLandlord'], false);
    });

    test('记录已出的牌', () {
      List<PlayingCard> playedCards = [
        PlayingCard(suit: Suit.spades, rank: Rank.three),
        PlayingCard(suit: Suit.hearts, rank: Rank.four),
      ];

      aiService.recordPlayedCards(playedCards, PlayerType.player);

      var memoryInfo = aiService.getMemoryInfo();
      expect(memoryInfo['allPlayedCardsCount'], 2);
      expect(memoryInfo['playedCards'][3], 1);
      expect(memoryInfo['playedCards'][4], 1);
    });

    test('AI首出牌策略', () {
      List<PlayingCard> aiCards = [
        PlayingCard(suit: Suit.spades, rank: Rank.ace),
        PlayingCard(suit: Suit.hearts, rank: Rank.king),
        PlayingCard(suit: Suit.diamonds, rank: Rank.three),
        PlayingCard(suit: Suit.clubs, rank: Rank.four),
        PlayingCard(suit: Suit.spades, rank: Rank.five),
      ];

      aiService.setAIInfo(aiCards, false);

      List<PlayingCard> firstPlay = aiService.getAdvancedAIPlay(aiCards, []);

      expect(firstPlay, isNotEmpty);
      expect(firstPlay.length, 1);
      // 开局应该优先出小牌
      expect(firstPlay.first.value, lessThanOrEqualTo(7));
    });

    test('AI压牌策略', () {
      List<PlayingCard> aiCards = [
        PlayingCard(suit: Suit.spades, rank: Rank.ace),
        PlayingCard(suit: Suit.hearts, rank: Rank.king),
        PlayingCard(suit: Suit.diamonds, rank: Rank.three),
        PlayingCard(suit: Suit.clubs, rank: Rank.four),
        PlayingCard(suit: Suit.spades, rank: Rank.five),
      ];

      List<PlayingCard> targetPlay = [
        PlayingCard(suit: Suit.spades, rank: Rank.six),
      ];

      aiService.setAIInfo(aiCards, false);

      List<PlayingCard> response =
          aiService.getAdvancedAIPlay(aiCards, targetPlay);

      if (response.isNotEmpty) {
        CardCombination targetCombination = CardCombination.analyze(targetPlay);
        CardCombination responseCombination = CardCombination.analyze(response);

        expect(responseCombination.canBeat(targetCombination), true);
      }
    });

    test('AI炸弹策略', () {
      List<PlayingCard> aiCards = [
        PlayingCard(suit: Suit.spades, rank: Rank.three),
        PlayingCard(suit: Suit.hearts, rank: Rank.three),
        PlayingCard(suit: Suit.diamonds, rank: Rank.three),
        PlayingCard(suit: Suit.clubs, rank: Rank.three),
        PlayingCard(suit: Suit.spades, rank: Rank.four),
      ];

      List<PlayingCard> targetPlay = [
        PlayingCard(suit: Suit.spades, rank: Rank.ace),
      ];

      aiService.setAIInfo(aiCards, false);

      List<PlayingCard> response =
          aiService.getAdvancedAIPlay(aiCards, targetPlay);

      if (response.isNotEmpty) {
        CardCombination responseCombination = CardCombination.analyze(response);
        expect(responseCombination.type, CombinationType.bomb);
      }
    });

    test('游戏阶段判断', () {
      // 模拟开局阶段
      aiService.setAIInfo([], false);
      var memoryInfo = aiService.getMemoryInfo();
      expect(memoryInfo['gamePhase'], 0);

      // 模拟中局阶段
      List<PlayingCard> midGameCards = List.generate(
          20, (index) => PlayingCard(suit: Suit.spades, rank: Rank.three));
      for (var card in midGameCards) {
        aiService.recordPlayedCards([card], PlayerType.player);
      }

      aiService.setAIInfo([], false);
      memoryInfo = aiService.getMemoryInfo();
      expect(memoryInfo['gamePhase'], 1);
    });

    test('地主身份影响策略', () {
      List<PlayingCard> aiCards = [
        PlayingCard(suit: Suit.spades, rank: Rank.three),
        PlayingCard(suit: Suit.hearts, rank: Rank.four),
        PlayingCard(suit: Suit.diamonds, rank: Rank.five),
      ];

      // 测试农民策略
      aiService.setAIInfo(aiCards, false);
      List<PlayingCard> farmerPlay = aiService.getAdvancedAIPlay(aiCards, []);

      // 测试地主策略
      aiService.setAIInfo(aiCards, true);
      List<PlayingCard> landlordPlay = aiService.getAdvancedAIPlay(aiCards, []);

      // 地主和农民的出牌策略应该有所不同
      // 这里主要验证方法能正常调用
      expect(farmerPlay, isA<List<PlayingCard>>());
      expect(landlordPlay, isA<List<PlayingCard>>());
    });
  });
}
