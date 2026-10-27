import 'package:flutter/material.dart';

import '../services/firebase_bootstrap.dart';

/// Keeps startup errors visible and retryable instead of crashing at launch.
class FirebaseAppLoader extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? initialize;
  const FirebaseAppLoader({super.key, required this.child, this.initialize});

  @override
  State<FirebaseAppLoader> createState() => _FirebaseAppLoaderState();
}

class _FirebaseAppLoaderState extends State<FirebaseAppLoader> {
  late Future<void> _startup;

  @override
  void initState() {
    super.initState();
    _startup = (widget.initialize ?? FirebaseBootstrap.initialize)();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _startup,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return widget.child;
      }
      return MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: snapshot.hasError
                      ? [
                          const Text(
                            'Chưa thể khởi động ứng dụng. Vui lòng thử lại.',
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {
                              _startup =
                                  (widget.initialize ??
                                  FirebaseBootstrap.initialize)();
                            }),
                            child: const Text('Thử lại'),
                          ),
                        ]
                      : [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          const Text('Đang khởi động…'),
                        ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
