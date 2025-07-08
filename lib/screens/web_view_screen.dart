import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../config/env_config.dart';

class WebViewScreen extends StatefulWidget {
  final String initialUrl;
  final Function(String) onUrlChanged;

  const WebViewScreen({
    Key? key,
    required this.initialUrl,
    required this.onUrlChanged,
  }) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _webViewController;
  late RefreshController _refreshController;
  bool _isLoading = true;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _refreshController = RefreshController(initialRefresh: false);
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            widget.onUrlChanged(url);
            _refreshController.refreshCompleted();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
            _refreshController.refreshFailed();
          },
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
  }

  void _onRefresh() {
    _webViewController.reload();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EnvConfig.isPulldown
          ? SmartRefresher(
              controller: _refreshController,
              onRefresh: _onRefresh,
              header: const WaterDropHeader(),
              child: _buildWebView(),
            )
          : _buildWebView(),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_isLoading && EnvConfig.isLoadInd)
          Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitFadingCircle(
                    color: _parseColor(EnvConfig.splashTaglineColor),
                    size: 50.0,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 16,
                      color: _parseColor(EnvConfig.splashTaglineColor),
                      fontFamily: EnvConfig.bottommenuFont,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
          int.parse(colorString.substring(1), radix: 16) + 0xFF000000,
        );
      }
      return Colors.blue; // fallback
    } catch (e) {
      return Colors.blue; // fallback
    }
  }
}
