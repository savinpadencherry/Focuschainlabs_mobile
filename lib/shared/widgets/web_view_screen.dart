import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/services/navigator_service.dart';
import '../../core/theme/app_colors.dart';
import 'state_views.dart';

/// Opens a URL inside the app. On Android/iOS it embeds a [WebView]; when
/// [desktopView] is set it spoofs a desktop user-agent so the CRM renders its
/// full desktop layout. On web/desktop (where the plugin has no view) it offers
/// an "open in browser" action instead.
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
    this.desktopView = false,
  });

  final String url;
  final String title;
  final bool desktopView;

  static const String _desktopUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/126.0 Safari/537.36';

  /// Whether an embedded webview is available on this platform.
  static bool get _canEmbed =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> open(
    BuildContext context, {
    required String url,
    required String title,
    bool desktopView = false,
  }) {
    if (url.isEmpty) return Future<void>.value();
    return Navigator.of(context).push<void>(
      AppPageRoute<void>(
        WebViewScreen(url: url, title: title, desktopView: desktopView),
      ),
    );
  }

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  WebViewController? _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (WebViewScreen._canEmbed) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
          ),
        );
      if (widget.desktopView) {
        _controller!.setUserAgent(WebViewScreen._desktopUa);
      }
      _controller!.loadRequest(Uri.parse(widget.url));
    }
  }

  Future<void> _openExternally() async {
    final Uri uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            tooltip: 'Open in browser',
            onPressed: _openExternally,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: WebViewScreen._canEmbed && _controller != null
          ? Stack(
              children: <Widget>[
                WebViewWidget(controller: _controller!),
                if (_loading)
                  const LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.primary,
                    backgroundColor: AppColors.surfaceMuted,
                  ),
              ],
            )
          : _ExternalFallback(
              title: widget.title,
              onOpen: _openExternally,
            ),
    );
  }
}

class _ExternalFallback extends StatelessWidget {
  const _ExternalFallback({required this.title, required this.onOpen});

  final String title;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.open_in_new_rounded,
      title: 'Open $title',
      message: 'On this platform we open the live view in a new browser tab.',
      action: FilledButton.icon(
        onPressed: onOpen,
        icon: const Icon(Icons.launch_rounded),
        label: const Text('Open in browser'),
      ),
    );
  }
}
