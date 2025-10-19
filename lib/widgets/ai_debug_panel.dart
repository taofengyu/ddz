import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

/// AI调试面板，显示AI的记牌信息和决策过程
class AIDebugPanel extends StatefulWidget {
  const AIDebugPanel({super.key});

  @override
  State<AIDebugPanel> createState() => _AIDebugPanelState();
}

class _AIDebugPanelState extends State<AIDebugPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        return Positioned(
          top: 10,
          right: 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isExpanded ? 280 : 60,
              height: _isExpanded ? 350 : 60,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: _isExpanded
                  ? _buildExpandedPanel(gameProvider)
                  : _buildCollapsedPanel(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedPanel() {
    return InkWell(
      onTap: () => setState(() => _isExpanded = true),
      borderRadius: BorderRadius.circular(10),
      child: const Center(
        child: Icon(
          Icons.psychology,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildExpandedPanel(GameProvider gameProvider) {
    Map<String, dynamic> aiInfo = gameProvider.getAIMemoryInfo();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题栏
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.psychology, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI调试面板',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _isExpanded = false),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),

        // 内容区域
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection(
                    '游戏阶段', _getGamePhaseText(aiInfo['gamePhase'])),
                const SizedBox(height: 8),
                _buildInfoSection('已出牌数量', '${aiInfo['allPlayedCardsCount']}'),
                const SizedBox(height: 8),
                _buildInfoSection('当前玩家手牌', '${aiInfo['myCardsCount']}'),
                const SizedBox(height: 8),
                _buildInfoSection('地主身份', aiInfo['isLandlord'] ? '是' : '否'),
                const SizedBox(height: 12),

                // 已出牌统计
                const Text(
                  '已出牌统计:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _buildPlayedCardsInfo(aiInfo['playedCards']),
                const SizedBox(height: 12),

                // 出牌历史
                const Text(
                  '出牌历史:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _buildPlayHistory(aiInfo['playerPlayHistory']),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            '$title:',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayedCardsInfo(Map<dynamic, dynamic> playedCards) {
    if (playedCards.isEmpty) {
      return const Text(
        '暂无数据',
        style: TextStyle(color: Colors.white70, fontSize: 9),
      );
    }

    // 按出牌数量排序，优先显示重要的牌
    List<MapEntry<dynamic, dynamic>> sortedCards = playedCards.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Widget> cardInfoWidgets = [];
    for (var entry in sortedCards) {
      String cardName = _getCardName(entry.key);
      cardInfoWidgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 1),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            '$cardName:${entry.value}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cardInfoWidgets,
      ),
    );
  }

  Widget _buildPlayHistory(Map<dynamic, dynamic> playHistory) {
    if (playHistory.isEmpty) {
      return const Text(
        '暂无数据',
        style: TextStyle(color: Colors.white70, fontSize: 9),
      );
    }

    List<Widget> historyWidgets = [];
    playHistory.forEach((player, plays) {
      String playerName = _getPlayerName(player);

      historyWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$playerName (${plays.length}次):',
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            ...plays.map<Widget>((play) {
              String playText;
              if (play == "过牌") {
                playText = "过牌";
              } else if (play is List) {
                // 出牌记录 - 已经是字符串列表
                playText = play.join(' ');
              } else {
                playText = play.toString();
              }

              return Container(
                margin: const EdgeInsets.only(left: 6, bottom: 1),
                child: Text(
                  playText.length > 25
                      ? '${playText.substring(0, 25)}...'
                      : playText,
                  style: TextStyle(
                    color: play == "过牌" ? Colors.orange : Colors.white70,
                    fontSize: 8,
                    fontWeight:
                        play == "过牌" ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
            const SizedBox(height: 2),
          ],
        ),
      );
    });

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: historyWidgets,
      ),
    );
  }

  String _getGamePhaseText(int phase) {
    switch (phase) {
      case 0:
        return '开局';
      case 1:
        return '中局';
      case 2:
        return '残局';
      default:
        return '未知';
    }
  }

  String _getCardName(dynamic value) {
    if (value == 16) return '小王';
    if (value == 17) return '大王';
    if (value == 15) return '2';
    if (value == 14) return 'A';
    if (value == 13) return 'K';
    if (value == 12) return 'Q';
    if (value == 11) return 'J';
    if (value == 10) return '10';
    if (value == 9) return '9';
    if (value == 8) return '8';
    if (value == 7) return '7';
    if (value == 6) return '6';
    if (value == 5) return '5';
    if (value == 4) return '4';
    if (value == 3) return '3';
    return '$value';
  }

  String _getPlayerName(dynamic player) {
    String playerStr = player.toString();
    if (playerStr.contains('player')) return '玩家';
    if (playerStr.contains('leftAI')) return '左家AI';
    if (playerStr.contains('rightAI')) return '右家AI';
    return playerStr;
  }
}
