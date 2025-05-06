// lib/pages/scan_page.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

import '../helpers/storage_helper.dart';

class ScanPage extends StatefulWidget {
  /// Initial list of already-scanned picture codes
  final List<String> initialItems;

  const ScanPage({Key? key, this.initialItems = const []}) : super(key: key);

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  /// The set of codes that came from the exhibition (cannot be removed)
  late final Set<String> _initialSet;

  /// All codes currently shown in the list (initial + newly scanned)
  late List<String> scannedItems;

  /// When we last showed a “duplicate” banner for each code
  final Map<String, DateTime> _lastDuplicateBannerTime = {};

  /// When we last showed an “invalid” banner for each code
  final Map<String, DateTime> _lastInvalidBannerTime = {};

  final MobileScannerController controller = MobileScannerController(
    formats: [BarcodeFormat.code128],
    detectionSpeed: DetectionSpeed.normal,
    torchEnabled: true,
  );

  // Regex: either a four-digit year 20xx or '201x', then '/', then three digits
  final RegExp codeRegex = RegExp(r'^(?:20\d{2}|201x)/\d{3}$');

  bool _isLoading = false;

  /// Controller to scroll the list of scanned items
  final ScrollController _scrollController = ScrollController();

  /// Just Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _soundEnabled = true;
  static const _soundPrefKey = 'scan_sound_enabled';

  @override
  void initState() {
    super.initState();

    // Remember which codes were “already there”
    _initialSet = Set.from(widget.initialItems);
    scannedItems = List.from(widget.initialItems);

    // Load sound setting from storage
    StorageHelper.get(_soundPrefKey).then((value) {
      if (value != null) {
        setState(() {
          _soundEnabled = value == 'true';
        });
      }
    });

    // Preload the success sound
    _initAudio();

    // On first frame, scroll to bottom if there are any items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && scannedItems.isNotEmpty) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _initAudio() async {
    // Configure the audio session for speech/dialogue short sounds
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    try {
      // Preload your asset (ensure it's in pubspec.yaml under flutter.assets)
      await _audioPlayer.setAsset('assets/success.wav');
    } catch (e) {
      debugPrint('Error loading success sound: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kIsWeb) {
      MobileScannerPlatform.instance.setBarcodeLibraryScriptUrl(
        "https://unpkg.com/@zxing/library@0.21.3",
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Shows a MaterialBanner at the top, auto-dismissed after 5 seconds.
  void _showBanner(String message, Color backgroundColor) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        actions: [
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: const Text(
              'Zavřít',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) messenger.hideCurrentMaterialBanner();
    });
  }

  /// Animate the list to the bottom after adding a new item
  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final isValid = codeRegex.hasMatch(code);
    final alreadyScanned = scannedItems.contains(code);

    if (isValid) {
      if (!alreadyScanned) {
        // New valid code: add, prevent immediate duplicate alert, show banner, scroll
        setState(() => scannedItems.add(code));
        _lastDuplicateBannerTime[code] = now;
        _showBanner('Kód přidán: "$code"', Colors.green);

        // Vibrace
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 100);
        }
        // Zvuk
        if (_soundEnabled) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.play();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
      } else {
        // Duplicate: only if >5s since last duplicate banner for this code
        final lastDup = _lastDuplicateBannerTime[code];
        if (lastDup == null || now.difference(lastDup) >= const Duration(seconds: 5)) {
          _lastDuplicateBannerTime[code] = now;
          _showBanner('Kód již existuje: "$code"', Colors.orange);
        }
      }
    } else {
      // Invalid code: only if >5s since last invalid banner for this code
      final lastInv = _lastInvalidBannerTime[code];
      if (lastInv == null || now.difference(lastInv) >= const Duration(seconds: 5)) {
        _lastInvalidBannerTime[code] = now;
        _showBanner('Neplatný kód: "$code"', Colors.redAccent);
      }
    }

    setState(() => _isLoading = false);
  }

  void _endAndSave() {
    Navigator.pop(context, scannedItems);
  }

  void _toggleSound() {
    setState(() {
      _soundEnabled = !_soundEnabled;
    });
    StorageHelper.set(_soundPrefKey, _soundEnabled.toString());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<List<String>>(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Režim skenování"),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(
                _soundEnabled ? Icons.volume_up : Icons.volume_off,
              ),
              onPressed: _toggleSound,
            ),
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, child) => IconButton(
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
                onPressed: () => controller.toggleTorch(),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Camera preview
                Expanded(
                  flex: 2,
                  child: MobileScanner(
                    controller: controller,
                    onDetect: _onDetect,
                  ),
                ),
                // Scanned items list
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Naskenované položky:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: scannedItems.length,
                          itemBuilder: (context, index) {
                            final item = scannedItems[index];
                            final isInitial = _initialSet.contains(item);
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              color: isInitial
                                  ? Colors.grey.shade100
                                  : Colors.white,
                              child: ListTile(
                                leading: Icon(
                                  isInitial ? Icons.history : Icons.fiber_new,
                                  color: isInitial
                                      ? Colors.grey
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                title: Text(item),
                                trailing: isInitial
                                    ? const SizedBox(width: 48)
                                    : IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      scannedItems.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Loading overlay during processing
            if (_isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black45,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _endAndSave,
              icon: const Icon(Icons.check),
              label: const Text("Ukončit a uložit"),
            ),
          ),
        ),
      ),
    );
  }
}
