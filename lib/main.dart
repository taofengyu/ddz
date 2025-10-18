import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/game_provider.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置横屏模式
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 隐藏状态栏和操作栏，但保留安全区域
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // 设置系统UI覆盖样式，减少OpenGL相关警告
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  // 设置Flutter引擎选项以减少OpenGL警告
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化音频服务
  await AudioService().initialize();

  runApp(const DDZApp());
}

class DDZApp extends StatelessWidget {
  const DDZApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameProvider>(
          create: (context) => GameProvider(),
        ),
      ],
      child: MaterialApp(
        title: '斗地主',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'PingFang SC',
          // 设置应用主题以减少OpenGL相关警告
          brightness: Brightness.light,
          useMaterial3: false, // 禁用Material 3以减少渲染复杂性
          // 禁用动画以减少OpenGL调用
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            },
          ),
          // 禁用阴影和动画效果
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
