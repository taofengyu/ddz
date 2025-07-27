# 斗地主 (Fight the Landlord)

一个使用 Flutter 开发的斗地主游戏。

## 功能特性

- 🎮 完整的斗地主游戏逻辑
- 🃏 支持所有标准牌型（单牌、对子、三张、顺子、炸弹、王炸等）
- 🤖 智能AI对手
- 🎨 美观的游戏界面
- 📱 响应式设计，支持不同屏幕尺寸
- 🏆 计分系统

## 游戏规则

斗地主是一种流行的中国扑克游戏，由三名玩家参与：

1. **发牌**: 一副牌54张，每人17张，剩余3张为地主牌
2. **叫地主**: 玩家可以选择成为地主，获得地主牌
3. **出牌**: 地主先出牌，按顺序轮流出牌
4. **牌型**: 支持单牌、对子、三张、顺子、连对、飞机、炸弹、王炸等
5. **胜负**: 先出完手牌者获胜

## 安装和运行

### 环境要求

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code

### 安装步骤

1. 克隆项目
```bash
git clone <repository-url>
cd ddz
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行项目
```bash
flutter run
```

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
│   ├── card.dart            # 扑克牌模型
│   └── card_combination.dart # 牌型组合
├── providers/               # 状态管理
│   └── game_provider.dart   # 游戏状态管理
├── screens/                 # 页面
│   ├── home_screen.dart     # 主页面
│   └── game_screen.dart     # 游戏页面
└── widgets/                 # 组件
    └── card_widget.dart     # 扑克牌组件
```

## 技术栈

- **Flutter**: 跨平台UI框架
- **Provider**: 状态管理
- **Dart**: 编程语言

## 开发计划

- [ ] 添加音效
- [ ] 实现更智能的AI算法
- [ ] 添加多人联网对战
- [ ] 支持自定义规则
- [ ] 添加历史记录
- [ ] 实现排行榜系统

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License 