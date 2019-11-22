/// Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.

import 'package:audio_call/screens/main_screen.dart';
import 'package:audio_call/services/call_service.dart';
import 'package:audio_call/theme/voximplant_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';

class CallScreen extends StatefulWidget {
  static const routeName = '/callScreen';
  final String callId;

  CallScreen({Key key, @required this.callId}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new CallScreenState(this.callId);
  }
}

class CallScreenState extends State<CallScreen> {
  String _endpointName;
  String _callStatus = 'Connecting...';
  bool _isAudioMuted = false;
  bool _isOnHold = false;
  String _callId;
  IconData _audioDeviceIcon = Icons.hearing;
  AudioDeviceManager _audioDeviceManager;
  final CallService _callService = CallService();

  CallScreenState(this._callId) {
    _audioDeviceManager = Voximplant().getAudioDeviceManager();
    _audioDeviceManager.onAudioDeviceChanged = _onAudioDeviceChange;
    _callService.bind(
      onCallDisconnected: _onCallDisconnected,
      onCallFailed: _onCallFailed,
      onCallConnected: _onCallConnected,
      onCallRinging: _onCallRinging,
      onCallAudioStarted: _onCallAudioStarted,
      onEndpointAdded: _onEndpointAdded,

      onCallMuted: _onCallMuted,
      onCallPutOnHold: _onCallPutOnHold,
    );
    _endpointName = _callService.getEndpointNameForCall(_callId) ?? 'Unknown';

    print('CallScreen: received callId: $_callId');
  }

  _onAudioDeviceChange(AudioDevice audioDevice) {
    setState(() {
      switch (audioDevice) {
        case AudioDevice.Bluetooth:
          _audioDeviceIcon = Icons.bluetooth_audio;
          break;
        case AudioDevice.Earpiece:
          _audioDeviceIcon = Icons.hearing;
          break;
        case AudioDevice.Speaker:
          _audioDeviceIcon = Icons.volume_up;
          break;
        case AudioDevice.WiredHeadset:
          _audioDeviceIcon = Icons.headset;
          break;
        case AudioDevice.None:
          break;
      }
    });
  }

  _onCallDisconnected(Map<String, String> headers, bool answeredElsewhere) {
    print('CallScreen: onCallDisconnected');
    Navigator.pushReplacementNamed(context, MainScreen.routeName);
  }

  _onCallFailed(int code, String description, Map<String, String> headers) {
    print('CallScreen: onCallFailed');
    Navigator.pushReplacementNamed(context, MainScreen.routeName);
  }

  _onCallConnected(Map<String, String> headers) {
    print('CallScreen: onCallConnected');
    setState(() {
      _callStatus = 'Call in progress';
      _endpointName = _callService.getEndpointNameForCall(_callId) ?? 'Unknown';
    });
  }

  _onCallRinging(Map<String, String> headers) {
    print('CallScreen: onCallRinging');
    setState(() {
      _callStatus = 'Ringing...';
    });
  }

  _onCallAudioStarted() {
    print('CallScreen: onCallAudioStarted');
  }

  _onEndpointAdded(Endpoint endpoint) {
    print('CallScreen: onEndpointAdded');
    endpoint.onEndpointUpdated = _onEndpointUpdated;
    setState(() {
      _endpointName = endpoint.userName ?? 'Unknown';
    });
  }

  _onEndpointUpdated(Endpoint endpoint) {
    print('CallScreen: onEndpointUpdated');
    setState(() {
      _endpointName = endpoint.userName;
    });
  }

  _onCallMuted(bool muted) {
    setState(() {
      _isAudioMuted = muted;
    });
  }

  _muteAudio() async {
    try {
      await _callService.sendAudio(_isAudioMuted);
      setState(() {
        _isAudioMuted = !_isAudioMuted;
      });
    } catch (e) {
    }
  }

  _onCallPutOnHold(bool onHold) {
    setState(() {
      _isOnHold = onHold;
    });
  }

  _hold() async {
    try {
      await _callService.hold(!_isOnHold);
      setState(() {
        _isOnHold = !_isOnHold;
      });
    } catch (e) {
    }
  }

  _selectAudioDevice(AudioDevice device) async {
    await _audioDeviceManager.selectAudioDevice(device);
  }

  _showAvailableAudioDevices() async {
    List<AudioDevice> availableAudioDevices =
        await _audioDeviceManager.getAudioDevices();
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select audio device'),
            content: SingleChildScrollView(
                child: Container(
              width: 100,
              height: 100,
              child: ListView.builder(
                  itemCount: availableAudioDevices.length,
                  itemBuilder: (BuildContext ctxt, int index) {
                    return FlatButton(
                      child: Text(
                        availableAudioDevices[index].toString(),
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        _selectAudioDevice(availableAudioDevices[index]);
                      },
                    );
                  }),
            )),
          );
        });
  }

  _hangup() async {
    await _callService.hangup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Flexible(
              flex: 2,
              child: Column(
                children: <Widget>[
                  Text(
                    '$_endpointName',
                    style: TextStyle(
                      fontSize: 26,
                    ),
                  ),
                  Text(
                    '$_callStatus',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Ink(
                          decoration: ShapeDecoration(
                            color: VoximplantColors.white,
                            shape: CircleBorder(
                                side: BorderSide(
                                    width: 2,
                                    color: VoximplantColors.button,
                                    style: BorderStyle.solid)),
                          ),
                          child: IconButton(
                            onPressed: _muteAudio,
                            iconSize: 40,
                            icon: Icon(
                                _isAudioMuted ? Icons.mic_off : Icons.mic,
                                color: VoximplantColors.button),
                            tooltip: 'Mute',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: 20, right: 20, left: 20),
                        child: Ink(
                          decoration: ShapeDecoration(
                            color: VoximplantColors.white,
                            shape: CircleBorder(
                                side: BorderSide(
                                    width: 2,
                                    color: VoximplantColors.button,
                                    style: BorderStyle.solid)),
                          ),
                          child: IconButton(
                            onPressed: _hold,
                            iconSize: 40,
                            icon: Icon(
                                _isOnHold ? Icons.play_arrow : Icons.pause,
                                color: VoximplantColors.button),
                            tooltip: 'Hold',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Ink(
                          decoration: ShapeDecoration(
                            color: VoximplantColors.white,
                            shape: CircleBorder(
                                side: BorderSide(
                                    width: 2,
                                    color: VoximplantColors.button,
                                    style: BorderStyle.solid)),
                          ),
                          child: IconButton(
                            onPressed: _showAvailableAudioDevices,
                            iconSize: 40,
                            icon: Icon(_audioDeviceIcon,
                                color: VoximplantColors.button),
                            tooltip: 'Select audio device',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Ink(
                  decoration: ShapeDecoration(
                    color: VoximplantColors.white,
                    shape: CircleBorder(
                        side: BorderSide(
                            width: 2,
                            color: VoximplantColors.red,
                            style: BorderStyle.solid)),
                  ),
                  child: IconButton(
                    onPressed: _hangup,
                    iconSize: 40,
                    icon: Icon(
                      Icons.call_end,
                      color: VoximplantColors.red,
                    ),
                    tooltip: 'Hang up',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
