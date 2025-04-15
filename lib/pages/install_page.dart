import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pwa_install/pwa_install.dart';

class InstallPage extends StatefulWidget {
  const InstallPage({Key? key}) : super(key: key);

  @override
  _InstallPageState createState() => _InstallPageState();
}

class _InstallPageState extends State<InstallPage> {

  static bool get isPwa => kIsWeb && PWAInstall().launchMode!.installed;
  static bool get isNative => !const bool.fromEnvironment('dart.library.js_util');
  static bool isPwaInstalledOrNative() => isNative || isPwa;

  bool _isInstalled = false;

  @override
  void initState() {
    super.initState();
    _isInstalled = isPwaInstalledOrNative();
  }

  void _installApp() {
    try {
      PWAInstall().promptInstall_();
      setState(() {
        _isInstalled = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Instalace selhala")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Instalovat aplikaci"),
      ),
      body: Center(
        child: _isInstalled
            ? const Text("Aplikace je již nainstalována.")
            : ElevatedButton(
          onPressed: _installApp,
          child: const Text("Instalovat aplikaci"),
        ),
      ),
    );
  }
}
