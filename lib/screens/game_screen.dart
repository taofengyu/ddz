import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/card_widget.dart';
import '../models/card.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Timer? _timer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    // 确保游戏已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = context.read<GameProvider>();
      gameProvider.initGame();
    });

    // 初始化时间并启动定时器
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[300]!,
              Colors.green[600]!,
            ],
          ),
        ),
        child: Consumer<GameProvider>(
          builder: (context, gameProvider, child) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    // 安全区域内容
                    Flexible(
                      child: SafeArea(
                        child: Column(
                          children: [
                            // 顶部信息栏
                            _buildTopInfoBar(context, gameProvider),
                            // 游戏区域
                            Flexible(
                              child: _buildGameArea(context, gameProvider),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 玩家手牌区域（在底部）
                    SizedBox(
                      height: 200, // 增加高度确保选中状态完全展示
                      child: SafeArea(
                        bottom: true,
                        child: _buildPlayerHandArea(context, gameProvider),
                      ),
                    ),
                  ],
                ),

                // 游戏结束弹框
                if (gameProvider.gameState == GameState.finished)
                  _buildGameOverDialog(context, gameProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopInfoBar(BuildContext context, GameProvider gameProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧：房号、信号、时间
          Row(
            children: [
              // 返回按钮
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              // 房号
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '房号: 123456',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 信号图标
              const Icon(Icons.wifi, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              // 时间
              Text(
                _currentTime,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // 中间：地主牌区域
          if (gameProvider.gameState == GameState.bidding ||
              gameProvider.gameState == GameState.playing)
            Center(
              child: _buildLandlordCards(context, gameProvider),
            ),

          // 右侧：功能图标
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.star, color: Colors.white, size: 18),
                padding: const EdgeInsets.all(0),
                constraints: const BoxConstraints(),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.flash_on, color: Colors.white, size: 18),
                padding: const EdgeInsets.all(0),
                constraints: const BoxConstraints(),
              ),
              IconButton(
                onPressed: () {},
                icon:
                    const Icon(Icons.copyright, color: Colors.white, size: 18),
                padding: const EdgeInsets.all(0),
                constraints: const BoxConstraints(),
              ),
              IconButton(
                onPressed: () {},
                icon:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                padding: const EdgeInsets.all(0),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea(BuildContext context, GameProvider gameProvider) {
    return Column(
      children: [
        // AI玩家信息区和出牌区在屏幕中央
        Container(
          height: 115, // 减少高度以适应117像素约束，解决溢出
          child: Row(
            children: [
              // 左侧AI玩家信息
              SizedBox(
                width: 80,
                child: Center(
                  child: _buildAIPlayerArea(
                    context,
                    gameProvider,
                    PlayerType.leftAI,
                    '昵称XXX',
                    Alignment.centerLeft,
                  ),
                ),
              ),
              // 中央出牌区 - 拉满宽度
              Expanded(
                flex: 3,
                child: _buildCenterArea(context, gameProvider),
              ),
              // 右侧AI玩家信息
              SizedBox(
                width: 80,
                child: Center(
                  child: _buildAIPlayerArea(
                    context,
                    gameProvider,
                    PlayerType.rightAI,
                    '昵称XXX',
                    Alignment.centerRight,
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildLandlordCards(BuildContext context, GameProvider gameProvider) {
    // 判断是否已经叫地主
    bool isLandlordSelected = gameProvider.landlord != null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.lightBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 底分
          Column(
            children: [
              const Text(
                '底分',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
              Text(
                '${gameProvider.baseScore}', // 动态显示底分
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // 地主牌（根据叫地主状态显示正面或背面）
          Row(
            children: [
              for (int i = 0; i < gameProvider.landlordCards.length; i++)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: CardWidget(
                    card: gameProvider.landlordCards[i],
                    isFaceDown: !isLandlordSelected, // 未叫地主时显示背面，叫地主后显示正面
                    width: 25,
                    height: 35,
                    compactJoker: true, // 使用紧凑的大小王显示
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // 倍数
          Column(
            children: [
              const Text(
                '倍数',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
              Text(
                '${gameProvider.multiplier}', // 动态显示倍数
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: gameProvider.multiplier > 1
                      ? Colors.yellow
                      : Colors.white, // 倍数大于1时显示黄色
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCenterArea(BuildContext context, GameProvider gameProvider) {
    // 出牌区分三块：左家、玩家、右家
    return Container(
      padding: const EdgeInsets.all(0), // 内边距设置为0
      height: 115, // 与上一层高度保持一致
      child: Row(
        children: [
          // 左家出牌 - 靠左
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: (gameProvider.leftLastPlay.isNotEmpty)
                  ? SizedBox(
                      width: gameProvider.leftLastPlay!.length * 25.0 + 50.0,
                      height: 80,
                      child: Stack(
                        children: [
                          for (int i = 0;
                              i < gameProvider.leftLastPlay!.length && i < 8;
                              i++)
                            Positioned(
                              left: i * 25.0,
                              child: CardWidget(
                                card: gameProvider.leftLastPlay![i],
                                width: 50, // 调大尺寸
                                height: 70, // 调大尺寸
                              ),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // 玩家出牌 - 底部居中
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter, // 靠底部居中
              child: (gameProvider.playerLastPlay.isNotEmpty)
                  ? SizedBox(
                      width: gameProvider.playerLastPlay!.length * 25.0 + 50.0,
                      height: 77, // 与卡片高度一致
                      child: Stack(
                        children: [
                          for (int i = 0;
                              i < gameProvider.playerLastPlay!.length && i < 8;
                              i++)
                            Positioned(
                              left: i * 25.0,
                              bottom: 0, // 确保靠底部
                              child: CardWidget(
                                card: gameProvider.playerLastPlay![i],
                                width: 55, // 调大尺寸
                                height: 77, // 调大尺寸
                              ),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // 右家出牌 - 靠右
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: (gameProvider.rightLastPlay != null &&
                      gameProvider.rightLastPlay!.isNotEmpty)
                  ? SizedBox(
                      width: gameProvider.rightLastPlay!.length * 25.0 + 50.0,
                      height: 80,
                      child: Stack(
                        children: [
                          for (int i = 0;
                              i < gameProvider.rightLastPlay!.length && i < 8;
                              i++)
                            Positioned(
                              left: i * 25.0,
                              child: CardWidget(
                                card: gameProvider.rightLastPlay![i],
                                width: 50, // 调大尺寸
                                height: 70, // 调大尺寸
                              ),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIPlayerArea(
    BuildContext context,
    GameProvider gameProvider,
    PlayerType playerType,
    String nickname,
    Alignment alignment,
  ) {
    List<PlayingCard> cards = playerType == PlayerType.leftAI
        ? gameProvider.leftAICards
        : gameProvider.rightAICards;

    // 获取AI的叫分状态
    String aiStatus = '';
    if (gameProvider.gameState == GameState.bidding) {
      if (playerType == gameProvider.maxBidder) {
        aiStatus = '${gameProvider.maxBid}分';
      } else if (gameProvider.maxBid > 0 &&
          playerType != gameProvider.maxBidder) {
        // 如果有叫分但不是最高叫分者，说明已经过牌
        aiStatus = '不叫';
      }
    }

    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头像
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.blue[300],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(height: 1),

          // 分数
          const Text(
            '9999',
            style: TextStyle(
              fontSize: 10, // 调大字体
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          // 昵称
          Text(
            nickname,
            style: const TextStyle(
              fontSize: 8, // 调大字体
              color: Colors.white,
            ),
          ),

          // 地主标识
          if (gameProvider.landlord == playerType)
            Container(
              margin: const EdgeInsets.only(top: 1),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.yellow[600],
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text(
                '地主',
                style: TextStyle(
                  fontSize: 8, // 调大字体
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

          // AI状态（叫分信息）
          if (aiStatus.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 1),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.yellow[600],
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                aiStatus,
                style: const TextStyle(
                  fontSize: 8, // 调大字体
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

          const SizedBox(height: 1),

          // 手牌数量显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Text(
              '${cards.length}张',
              style: const TextStyle(
                fontSize: 9, // 调大字体
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHandArea(BuildContext context, GameProvider gameProvider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16), // 添加底部安全边距

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 0), // 移除上方间距，让操作区继续往上移
          // 玩家头像和操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 玩家头像和信息
              Row(
                children: [
                  // 头像
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.blue[300],
                      borderRadius: BorderRadius.circular(17.5),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 玩家信息
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '9999',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        '昵称XXX',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // 地主标识
                  if (gameProvider.landlord == PlayerType.player)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.yellow[600],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        '地主',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // 操作按钮区域 - 根据游戏状态显示不同按钮
              if (gameProvider.gameState == GameState.bidding)
                // 叫地主阶段的按钮
                Row(children: [
                  // 不叫按钮
                  ElevatedButton(
                    onPressed: () => gameProvider.passBid(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('不叫', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  // 叫分按钮组
                  Row(
                    children: [
                      // 一分
                      if (gameProvider.maxBid < 1)
                        ElevatedButton(
                          onPressed: () => gameProvider.bid(1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child:
                              const Text('一分', style: TextStyle(fontSize: 12)),
                        ),
                      if (gameProvider.maxBid < 1) const SizedBox(width: 4),

                      // 二分
                      if (gameProvider.maxBid < 2)
                        ElevatedButton(
                          onPressed: () => gameProvider.bid(2),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child:
                              const Text('二分', style: TextStyle(fontSize: 12)),
                        ),
                      if (gameProvider.maxBid < 2) const SizedBox(width: 4),

                      // 三分
                      if (gameProvider.maxBid < 3)
                        ElevatedButton(
                          onPressed: () => gameProvider.bid(3),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child:
                              const Text('三分', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ])
              else if (gameProvider.gameState == GameState.playing)
                // 出牌阶段的按钮
                Row(
                  children: [
                    // 不出按钮
                    ElevatedButton(
                      onPressed:
                          (gameProvider.currentPlayer == PlayerType.player &&
                                  gameProvider.lastPlay.isNotEmpty)
                              ? () => gameProvider.pass()
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (gameProvider.currentPlayer == PlayerType.player &&
                                    gameProvider.lastPlay.isNotEmpty)
                                ? Colors.red[600]
                                : Colors.grey[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text('不出', style: TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                    // 出牌按钮 - 始终显示，根据选中牌状态改变可点击状态
                    ElevatedButton(
                      onPressed:
                          (gameProvider.currentPlayer == PlayerType.player &&
                                  gameProvider.selectedCards.isNotEmpty)
                              ? () => gameProvider.playCards()
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (gameProvider.currentPlayer == PlayerType.player &&
                                    gameProvider.selectedCards.isNotEmpty)
                                ? Colors.orange[600]
                                : Colors.grey[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text('出牌', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 2), // 进一步减少操作区和手牌之间的间距

          // 手牌显示区域
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double cardWidth = 60.0;
                double cardOverlap = 25.0;
                int cardCount = gameProvider.playerCards.length;
                double totalWidth = cardCount > 0
                    ? (cardCount - 1) * cardOverlap + cardWidth
                    : cardWidth;
                double startLeft = (constraints.maxWidth - totalWidth) / 2;
                return SizedBox(
                  height: 180, // 增加高度确保选中状态完全展示
                  child: Stack(
                    children: [
                      for (int i = 0; i < cardCount; i++)
                        Positioned(
                          left: startLeft + i * cardOverlap,
                          bottom: gameProvider.selectedCards
                                  .contains(gameProvider.playerCards[i])
                              ? 20 // 增加选中状态的移动距离
                              : 0,
                          child: GestureDetector(
                            onTap: () => gameProvider
                                .selectCard(gameProvider.playerCards[i]),
                            child: CardWidget(
                              card: gameProvider.playerCards[i],
                              width: cardWidth,
                              height: 80,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverDialog(BuildContext context, GameProvider gameProvider) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '游戏结束',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 获胜者
              Text(
                '获胜者: ${gameProvider.getPlayerName(gameProvider.winner!)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 16),

              // 得分
              _buildScoreItem('玩家', gameProvider.playerScore),
              _buildScoreItem('左家AI', gameProvider.leftAIScore),
              _buildScoreItem('右家AI', gameProvider.rightAIScore),
              const SizedBox(height: 20),

              // 按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      gameProvider.initGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('再来一局'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('结束游戏'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem(String playerName, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(playerName),
          Text(
            score.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
