import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class FullscreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;

  const FullscreenVideoPlayer({Key? key, required this.videoUrl, required this.title}) : super(key: key);

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  late YoutubePlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  String? _extractVideoId(String url) {
    final RegExp regExp = RegExp(
      r'^.*(?:(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/|live\/)|(?:(?:watch)?\?v(?:i)?=|\&v(?:i)?=))([^#\&\?]*).*',
      caseSensitive: false,
    );

    final Match? match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      final String? id = match.group(1);
      if (id != null && id.length == 11) {
        return id;
      }
    }
    return YoutubePlayerController.convertUrlToId(url);
  }

  void _initializePlayer() {
    final String? videoId = _extractVideoId(widget.videoUrl);

    if (videoId != null && videoId.isNotEmpty) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
          enableCaption: true,
        ),
      );
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _resetOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _resetOrientation();
    if (_isInitialized) {
      _controller.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _resetOrientation();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              await _resetOrientation();
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
        body: Center(
          child: _isInitialized
              ? YoutubePlayer(
            controller: _controller,
            aspectRatio: 16 / 9,
          )
              : const CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
