import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../pages/multi_camera_page.dart';

part 'app_router.g.dart';

/// 라우트 경로 상수
abstract class AppRoutes {
  static const home = '/';
}

/// GoRouter 프로바이더
@Riverpod(keepAlive: true)
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const MultiCameraPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          '페이지를 찾을 수 없습니다: ${state.uri}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
}
