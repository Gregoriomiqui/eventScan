import 'package:flutter/material.dart';

import 'brand_config.dart';

class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({required this.error, super.key});

  final BrandConfigException error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 16),
                const Text(
                  'No se pudo cargar la configuración de esta marca.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  [if (error.path != null) error.path!, error.message].join('\n'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}