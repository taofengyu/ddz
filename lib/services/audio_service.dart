import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // 背景音乐播放器
  final AudioPlayer _bgmPlayer = AudioPlayer();
  // 音效播放器
  final AudioPlayer _sfxPlayer = AudioPlayer();
  // 游戏音效播放器（独立于按钮音效）
  final AudioPlayer _gameSfxPlayer = AudioPlayer();

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  // 音频功能开关 - 当音频文件不存在时设为false
  bool _audioEnabled = false;
  bool get audioEnabled => _audioEnabled;

  // 防抖机制 - 避免快速点击导致音效丢失
  DateTime _lastButtonClickTime = DateTime(0);
  static const Duration _buttonClickCooldown = Duration(milliseconds: 200);

  // 初始化音频服务
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('AudioService初始化开始');
      }

      // 设置背景音乐循环播放
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.3); // 背景音乐音量较低

      // 设置音效播放器
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.setVolume(0.7); // 音效音量较高

      // 设置游戏音效播放器
      await _gameSfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _gameSfxPlayer.setVolume(0.7); // 游戏音效音量较高

      // 测试音频文件是否存在
      await _testAudioFiles();

      if (kDebugMode) {
        print('AudioService初始化完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioService初始化失败');
      }
    }
  }

  // 测试音频文件是否存在
  Future<void> _testAudioFiles() async {
    try {
      // 只测试按钮音效文件，避免测试有问题的文件
      await _sfxPlayer.setSource(AssetSource('audio/button_click.mp3'));
      _audioEnabled = true;
      if (kDebugMode) {
        print('音频服务初始化成功');
      }
    } catch (e) {
      // 即使音频文件不存在，也启用基本功能（使用系统音效）
      _audioEnabled = true;
      if (kDebugMode) {
        print('音频文件检测失败，使用系统音效');
      }
    }
  }

  // 播放背景音乐
  Future<void> playBackgroundMusic() async {
    // 背景音乐已禁用
    return;
  }

  // 停止背景音乐
  Future<void> stopBackgroundMusic() async {
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      // 忽略停止失败的错误
    }
  }

  // 切换静音状态
  Future<void> toggleMute() async {
    if (!_audioEnabled) return; // 如果音频功能未启用，不执行静音切换

    _isMuted = !_isMuted;

    if (_isMuted) {
      await stopBackgroundMusic();
    }
  }

  // 播放发牌音效
  Future<void> playCardDeal() async {
    if (!_audioEnabled || _isMuted) return;
    await _playGameSfx('audio/card_deal.mp3');
  }

  // 播放出牌音效
  Future<void> playCardPlay() async {
    if (!_audioEnabled || _isMuted) return;
    await _playGameSfx('audio/card_play.mp3');
  }

  // 播放叫牌音效
  Future<void> playBid() async {
    if (!_audioEnabled || _isMuted) return;
    await _playGameSfx('audio/bid.mp3');
  }

  // 播放过牌音效
  Future<void> playPass() async {
    if (!_audioEnabled || _isMuted) return;
    await _playGameSfx('audio/pass.mp3');
  }

  // 播放胜利音效
  Future<void> playWin() async {
    if (!_audioEnabled || _isMuted) return;
    await _playGameSfx('audio/win.mp3');
  }

  // 播放失败音效
  Future<void> playLose() async {
    if (!_audioEnabled || _isMuted) return;
    await _playGameSfx('audio/lose.mp3');
  }

  // 播放按钮点击音效
  Future<void> playButtonClick() async {
    if (!_audioEnabled || _isMuted) {
      if (kDebugMode) {
        print('按钮音效被跳过 - 音频未启用或静音');
      }
      return;
    }

    // 防抖机制 - 避免快速点击导致音效重复
    final now = DateTime.now();
    if (now.difference(_lastButtonClickTime) < _buttonClickCooldown) {
      return;
    }
    _lastButtonClickTime = now;

    if (kDebugMode) {
      print('播放按钮点击音效');
    }

    // 直接播放按钮音效，_playSfx方法内部会处理停止逻辑
    await _playSfx('audio/button_click.mp3');
  }

  // 播放成为地主音效
  Future<void> playLandlord() async {
    if (!_audioEnabled || _isMuted) return;
    await _playGameSfx('audio/landlord.mp3');
  }

  // 播放选牌音效
  Future<void> playCardSelect() async {
    if (!_audioEnabled || _isMuted) {
      if (kDebugMode) {
        print('选牌音效被跳过 - 音频未启用或静音');
      }
      return;
    }

    if (kDebugMode) {
      print('播放选牌音效');
    }

    try {
      if (Platform.isAndroid) {
        // Android上尝试播放修复后的音频文件
        try {
          await _playSfx('audio/card_select_fixed.mp3');
        } catch (e) {
          if (kDebugMode) {
            print('修复后的选牌音效播放失败，使用系统音效');
          }
          await _playSystemSound();
        }
      } else {
        // iOS上尝试播放自定义音效
        await _playSfx('audio/card_select.mp3');
      }
    } catch (e) {
      if (kDebugMode) {
        print('选牌音效播放失败，使用系统音效');
      }
      // 如果播放失败，使用系统音效作为备用
      await _playSystemSound();
    }
  }

  // 私有方法：播放音效
  Future<void> _playSfx(String assetPath) async {
    try {
      // 确保音效播放器处于正确状态
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);

      // Android特定处理
      if (Platform.isAndroid) {
        // 先停止当前播放
        try {
          await _sfxPlayer.stop();
        } catch (e) {
          // 忽略停止失败的错误
        }
        // 等待一小段时间确保停止完成
        await Future.delayed(const Duration(milliseconds: 30));
      }

      // 设置音源并播放
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (e) {
      // 如果音频文件不存在，使用系统音效作为备用
      await _playSystemSound();
    }
  }

  // 私有方法：播放游戏音效（使用独立的播放器）
  Future<void> _playGameSfx(String assetPath) async {
    try {
      // 确保游戏音效播放器处于正确状态
      await _gameSfxPlayer.setReleaseMode(ReleaseMode.stop);

      // Android特定处理
      if (Platform.isAndroid) {
        // 先停止当前播放
        await _gameSfxPlayer.stop();
        // 等待一小段时间确保停止完成
        await Future.delayed(const Duration(milliseconds: 50));
      }

      await _gameSfxPlayer.play(AssetSource(assetPath));
    } catch (e) {
      // 如果音频文件不存在，使用系统音效作为备用
      await _playSystemSound();
    }
  }

  // 播放系统音效作为备用
  Future<void> _playSystemSound() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      // 忽略系统音效播放失败
    }
  }

  // 释放资源
  Future<void> dispose() async {
    await _bgmPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
