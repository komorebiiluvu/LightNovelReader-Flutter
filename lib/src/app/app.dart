import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import 'app_router.dart';

class LightNovelReaderApp extends ConsumerWidget {
  const LightNovelReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp(
      title: 'LightNovelReader',
      initialRoute: AppRouter.home,
      onGenerateRoute: router.onGenerateRoute,
    );
  }
}
