import 'package:apivideo_live_stream/apivideo_live_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LiveViewPage extends StatefulWidget {
  const LiveViewPage({Key? key}) : super(key: key);

  @override
  _LiveViewPageState createState() => _LiveViewPageState();
}

class _LiveViewPageState extends State<LiveViewPage>
    with WidgetsBindingObserver {
  final ButtonStyle buttonStyle =
      ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));
  Params config = Params();
  late ApiVideoLiveStreamController _controller;
  bool _isStreaming = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    _controller = createLiveStreamController();

    _controller.initialize().catchError((e) {
      showInSnackBar(e.toString());
    });
    super.initState();
  }

  Future<void> initController() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.startPreview();
    }
  }

  ApiVideoLiveStreamController createLiveStreamController() {
    return ApiVideoLiveStreamController(
      initialAudioConfig: config.audio,
      initialVideoConfig: config.video,
      onConnectionSuccess: () {
        print('Connection succeeded');
      },
      onConnectionFailed: (error) {
        print('Connection failed: $error');
        _showDialog(context, 'Connection failed', error);
        if (mounted) {
          setIsStreaming(false);
        }
      },
      onDisconnection: () {
        showInSnackBar('Disconnected');
        if (mounted) {
          setIsStreaming(false);
        }
      },
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Live Stream Example'),
        actions: const <Widget>[],
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Center(
                    child: ApiVideoCameraPreview(controller: _controller),
                  ),
                ),
              ),
            ),
            _controlRowWidget()
          ],
        ),
      ),
    );
  }

  void _awaitResultFromSettingsFinal(BuildContext context) async {
    // await Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //         builder: (context) => SettingsScreen(params: config)));
    // _controller.setVideoConfig(config.video);
    // _controller.setAudioConfig(config.audio);
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _controlRowWidget() {
    final ApiVideoLiveStreamController liveStreamController = _controller;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.cameraswitch),
          onPressed:
              liveStreamController != null ? onSwitchCameraButtonPressed : null,
        ),
        IconButton(
          icon: const Icon(Icons.mic_off),
          onPressed: liveStreamController != null
              ? onToggleMicrophoneButtonPressed
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.fiber_manual_record),
          color: Colors.red,
          onPressed: !_isStreaming ? onStartStreamingButtonPressed : null,
        ),
        IconButton(
            icon: const Icon(Icons.stop),
            color: Colors.red,
            onPressed: _isStreaming ? onStopStreamingButtonPressed : null),
      ],
    );
  }

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> switchCamera() async {
    final ApiVideoLiveStreamController liveStreamController = _controller;

    if (liveStreamController == null) {
      showInSnackBar('Error: create a camera controller first.');
      return;
    }

    try {
      liveStreamController.switchCamera();
    } catch (error) {
      if (error is PlatformException) {
        _showDialog(
            context, "Error", "Failed to switch camera: ${error.message}");
      } else {
        _showDialog(context, "Error", "Failed to switch camera: $error");
      }
    }
  }

  Future<void> toggleMicrophone() async {
    final ApiVideoLiveStreamController liveStreamController = _controller;

    if (liveStreamController == null) {
      showInSnackBar('Error: create a camera controller first.');
      return;
    }

    try {
      liveStreamController.toggleMute();
    } catch (error) {
      if (error is PlatformException) {
        _showDialog(
            context, "Error", "Failed to toggle mute: ${error.message}");
      } else {
        _showDialog(context, "Error", "Failed to toggle mute: $error");
      }
    }
  }

  Future<void> startStreaming() async {
    final ApiVideoLiveStreamController liveStreamController = _controller;

    if (liveStreamController == null) {
      showInSnackBar('Error: create a camera controller first.');
      return;
    }

    try {
      await liveStreamController.startStreaming(streamKey: '', url: '');
    } catch (error) {
      setIsStreaming(false);
      if (error is PlatformException) {
        print("Error: failed to start stream: ${error.message}");
      } else {
        print("Error: failed to start stream: $error");
      }
    }
  }

  Future<void> stopStreaming() async {
    final ApiVideoLiveStreamController liveStreamController = _controller;

    if (liveStreamController == null) {
      showInSnackBar('Error: create a camera controller first.');
      return;
    }

    try {
      liveStreamController.stopStreaming();
    } catch (error) {
      if (error is PlatformException) {
        _showDialog(
            context, "Error", "Failed to stop stream: ${error.message}");
      } else {
        _showDialog(context, "Error", "Failed to stop stream: $error");
      }
    }
  }

  void onSwitchCameraButtonPressed() {
    switchCamera().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void onToggleMicrophoneButtonPressed() {
    toggleMicrophone().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void onStartStreamingButtonPressed() {
    startStreaming().then((_) {
      if (mounted) {
        setIsStreaming(true);
      }
    });
  }

  void onStopStreamingButtonPressed() {
    stopStreaming().then((_) {
      if (mounted) {
        setIsStreaming(false);
      }
    });
  }

  void setIsStreaming(bool isStreaming) {
    setState(() {
      _isStreaming = isStreaming;
    });
  }
}

Future<void> _showDialog(
    BuildContext context, String title, String description) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(description),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Dismiss'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

List<int> fpsList = [24, 25, 30];
List<int> audioBitrateList = [32000, 64000, 128000, 192000];

String defaultValueTransformation(int e) {
  return "$e";
}

extension ListExtension on List<int> {
  Map<int, dynamic> toMap(
      {Function(int e) valueTransformation = defaultValueTransformation}) {
    var map = {for (var e in this) e: valueTransformation(e)};
    return map;
  }
}

String bitrateToPrettyString(int bitrate) {
  return "${bitrate / 1000} Kbps";
}

class Params {
  final VideoConfig video = VideoConfig.withDefaultBitrate();
  final AudioConfig audio = AudioConfig();

  String rtmpUrl = "rtmp://broadcast.api.video/s/";
  String streamKey = "";

  String getResolutionToString() {
    return video.resolution.toString();
  }

  String getChannelToString() {
    return audio.channel.toString();
  }

  String getBitrateToString() {
    return bitrateToPrettyString(audio.bitrate);
  }

  String getSampleRateToString() {
    return audio.sampleRate.toString();
  }
}
