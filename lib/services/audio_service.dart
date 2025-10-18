import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // 背景音乐播放器
  final AudioPlayer _bgmPlayer = AudioPlayer();
  // 音效播放器
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  // 音频功能开关 - 当音频文件不存在时设为false
  bool _audioEnabled = false;
  bool get audioEnabled => _audioEnabled;

  // 防抖机制 - 避免快速点击导致音效丢失
  DateTime _lastButtonClickTime = DateTime(0);
  static const Duration _buttonClickCooldown = Duration(milliseconds: 100);

  // 初始化音频服务
  Future<void> initialize() async {
    try {
      // 设置背景音乐循环播放
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.3); // 背景音乐音量较低

      // 设置音效播放器
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.setVolume(0.7); // 音效音量较高

      // 测试音频文件是否存在
      await _testAudioFiles();

      // 背景音乐已禁用，不播放
      if (kDebugMode) {
        print('背景音乐已禁用，跳过播放');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioService初始化失败: $e');
      }
    }
  }

  // 测试音频文件是否存在
  Future<void> _testAudioFiles() async {
    try {
      // 测试背景音乐文件
      await _bgmPlayer.setSource(AssetSource('audio/bgm.mp3'));
      _audioEnabled = true;
      if (kDebugMode) {
        print('音频文件检测成功，音频功能已启用');
      }
    } catch (e) {
      // 即使音频文件不存在，也启用基本功能（使用系统音效）
      _audioEnabled = true;
      if (kDebugMode) {
        print('音频文件不存在，使用系统音效作为备用');
        print('提示：可以添加自定义音频文件到 assets/audio/ 目录获得更好体验');
      }
    }
  }

  // 播放背景音乐
  Future<void> playBackgroundMusic() async {
    // 背景音乐已禁用
    if (kDebugMode) {
      print('背景音乐已禁用');
    }
    return;
  }

  // 停止背景音乐
  Future<void> stopBackgroundMusic() async {
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      if (kDebugMode) {
        print('停止背景音乐失败: $e');
      }
    }
  }

  // 切换静音状态
  Future<void> toggleMute() async {
    if (!_audioEnabled) return; // 如果音频功能未启用，不执行静音切换

    _isMuted = !_isMuted;

    if (_isMuted) {
      await stopBackgroundMusic();
    } else {
      // 背景音乐已禁用，不播放
      if (kDebugMode) {
        print('取消静音，但背景音乐已禁用');
      }
    }
  }

  // 播放发牌音效
  Future<void> playCardDeal() async {
    if (!_audioEnabled || _isMuted) return;
    await _playSfx('audio/card_deal.mp3');
  }

  // 播放出牌音效
  Future<void> playCardPlay() async {
    if (!_audioEnabled || _isMuted) return;
    await _playSfx('audio/card_play.mp3');
  }

  // 播放叫牌音效
  Future<void> playBid() async {
    if (!_audioEnabled || _isMuted) return;
    await _playSfx('audio/bid.mp3');
  }

  // 播放过牌音效
  Future<void> playPass() async {
    if (!_audioEnabled || _isMuted) return;
    await _playSfx('audio/pass.mp3');
  }

  // 播放胜利音效
  Future<void> playWin() async {
    if (!_audioEnabled || _isMuted) return;
    await _playSfx('audio/win.mp3');
  }

  // 播放失败音效
  Future<void> playLose() async {
    if (!_audioEnabled || _isMuted) return;
    await _playSfx('audio/lose.mp3');
  }

  // 播放按钮点击音效
  Future<void> playButtonClick() async {
    if (!_audioEnabled || _isMuted) return;

    // 防抖机制 - 避免快速点击导致音效丢失
    final now = DateTime.now();
    if (now.difference(_lastButtonClickTime) < _buttonClickCooldown) {
      if (kDebugMode) {
        print('按钮点击过于频繁，跳过音效播放');
      }
      return;
    }
    _lastButtonClickTime = now;

    // 停止当前播放的音效，确保新音效能立即播放
    try {
      await _sfxPlayer.stop();
    } catch (e) {
      // 忽略停止失败的错误
    }

    await _playSfx('audio/button_click.mp3');
  }

  // 播放成为地主音效
  Future<void> playLandlord() async {
    if (!_audioEnabled || _isMuted) return;
    await _playSfx('audio/landlord.mp3');
  }

  // 播放选牌音效
  Future<void> playCardSelect() async {
    if (!_audioEnabled || _isMuted) return;
    await _playSfx('audio/card_select.mp3');
  }

  // 私有方法：播放音效
  Future<void> _playSfx(String assetPath) async {
    try {
      // 确保音效播放器处于正确状态
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (e) {
      if (kDebugMode) {
        print('播放音效失败 $assetPath: $e');
        print('使用系统音效作为备用');
      }
      // 如果音频文件不存在，使用系统音效作为备用
      await _playSystemSound();
    }
  }

  // 播放系统音效作为备用
  Future<void> _playSystemSound() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      if (kDebugMode) {
        print('系统音效播放失败: $e');
      }
    }
  }

  // 释放资源
  Future<void> dispose() async {
    await _bgmPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
