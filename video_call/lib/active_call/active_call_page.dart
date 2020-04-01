/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:video_call/active_call/active_call.dart';
import 'package:video_call/active_call/bloc/active_call_event.dart';
import 'package:video_call/active_call/bloc/active_call_state.dart';
import 'package:video_call/call_failed/call_failed.dart';
import 'package:video_call/services/navigation_helper.dart';
import 'package:video_call/theme/voximplant_theme.dart';
import 'package:video_call/widgets/widgets.dart';

class ActiveCallPage extends StatefulWidget {
  static const routeName = '/activeCall';

  final bool _isIncoming;
  final String _endpoint;

  @override
  State<StatefulWidget> createState() =>
      _ActiveCallPageState(_isIncoming, _endpoint);

  ActiveCallPage({@required ActiveCallPageArguments arguments})
      : _isIncoming = arguments.isIncoming,
        _endpoint = arguments.endpoint;
}

class _ActiveCallPageState extends State<ActiveCallPage> {
  VIVideoViewController _localVideoViewController = VIVideoViewController();
  VIVideoViewController _remoteVideoViewController = VIVideoViewController();
  double _localVideoAspectRatio = 1.0;
  double _remoteVideoAspectRatio = 1.0;

  final bool _isIncoming;
  final String _endpoint;

  _ActiveCallPageState(bool isIncoming, String endpoint)
      : _isIncoming = isIncoming,
        _endpoint = endpoint;

  @override
  void initState() {
    super.initState();
    _localVideoViewController.addListener(_localVideoHasChanged);
    _remoteVideoViewController.addListener(_remoteVideoHasChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isIncoming
        ? BlocProvider.of<ActiveCallBloc>(context)
            .add(AnswerCallEvent(_endpoint))
        : BlocProvider.of<ActiveCallBloc>(context)
            .add(StartOutgoingCallEvent(_endpoint));
  }

  @override
  void dispose() {
    _localVideoViewController.removeListener(_localVideoHasChanged);
    _remoteVideoViewController.removeListener(_remoteVideoHasChanged);
    _localVideoViewController.dispose();
    _remoteVideoViewController.dispose();
    super.dispose();
  }

  void _localVideoHasChanged() => setState(
      () => _localVideoAspectRatio = _localVideoViewController.aspectRatio);

  void _remoteVideoHasChanged() => setState(
      () => _remoteVideoAspectRatio = _remoteVideoViewController.aspectRatio);

  @override
  Widget build(BuildContext context) {
    ActiveCallBloc _getBlock() => BlocProvider.of<ActiveCallBloc>(context);

    void _hangup() => _getBlock().add(HangupPressedEvent());

    void _hold(bool hold) => _getBlock().add(HoldPressedEvent(hold: hold));

    void _mute(bool mute) => _getBlock().add(MutePressedEvent(mute: mute));

    void _sendVideo(bool send) =>
        _getBlock().add(SendVideoPressedEvent(send: send));

    void _switchCamera() => _getBlock().add(SwitchCameraPressedEvent());

    return BlocListener<ActiveCallBloc, ActiveCallState>(
      listener: (context, state) {
        if (state is CallEndedActiveCallState) {
          state.failed
              ? Navigator.of(context).pushReplacementNamed(AppRoutes.callFailed,
                  arguments: CallFailedPageArguments(
                      failureReason: state.description,
                      endpoint: state.displayName))
              : Navigator.of(context).pushReplacementNamed(AppRoutes.makeCall);
        } else {
          _localVideoViewController.streamId = state.localVideoStreamID;
          _remoteVideoViewController.streamId = state.remoteVideoStreamID;
        }
      },
      child: BlocBuilder<ActiveCallBloc, ActiveCallState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: VoximplantColors.grey,
            body: SafeArea(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      child: Stack(
                        children: <Widget>[
                          Align(
                            alignment: Alignment.center,
                            child: AspectRatio(
                              aspectRatio: _remoteVideoAspectRatio,
                              child: VIVideoView(_remoteVideoViewController),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Container(
                                width: MediaQuery.of(context).size.width / 4,
                                height: MediaQuery.of(context).size.height / 4,
                                child: Align(
                                  child: AspectRatio(
                                    aspectRatio: _localVideoAspectRatio,
                                    child: VIVideoView(_localVideoViewController),
                                  ),
                                ),
                              ),
                            )
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: 20, top: 20),
                              child: Platform.isAndroid ?
                                Widgets.iconButton(
                                  icon: Icons.switch_camera,
                                  color: VoximplantColors.button,
                                  tooltip: 'Switch camera',
                                  onPressed: _switchCamera,
                                ) :
                                  Container()
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              state.description,
                              style: TextStyle(color: VoximplantColors.white),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 80,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            Widgets.iconButton(
                                icon: state.isMuted ? Icons.mic : Icons.mic_off,
                                color: VoximplantColors.button,
                                tooltip: state.isMuted ? 'Unmute' : 'Mute',
                                onPressed: () {
                                  _mute(!state.isMuted);
                                }),
                            Widgets.iconButton(
                                icon: state.isOnHold
                                    ? Icons.play_arrow
                                    : Icons.pause,
                                color: VoximplantColors.button,
                                tooltip: state.isOnHold ? 'Resume' : 'Hold',
                                onPressed: () {
                                  _hold(!state.isOnHold);
                                }),
                            Widgets.iconButton(
                                icon: state.localVideoStreamID != null
                                    ? Icons.videocam_off
                                    : Icons.videocam,
                                color: VoximplantColors.button,
                                tooltip: 'Send video',
                                onPressed: () {
                                  _sendVideo(state.localVideoStreamID == null);
                                }),
                            Widgets.iconButton(
                                icon: Icons.call_end,
                                color: VoximplantColors.red,
                                tooltip: 'Hang up',
                                onPressed: _hangup)
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
