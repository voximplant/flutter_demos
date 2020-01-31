/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:video_call/active_call/active_call.dart';
import 'package:video_call/call_failed/call_failed.dart';
import 'package:video_call/routes.dart';
import 'package:video_call/theme/voximplant_theme.dart';
import 'package:video_call/widgets/widgets.dart';

import 'bloc/active_call_state.dart';

class ActiveCallPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ActiveCallPageState();
  }
}

class _ActiveCallPageState extends State<ActiveCallPage> {
  String callState = 'Connecting';
  VIVideoViewController _localVideoViewController = VIVideoViewController();
  VIVideoViewController _remoteVideoViewController = VIVideoViewController();
  double _localVideoAspectRatio = 1.0;
  double _remoteVideoAspectRatio = 1.0;
  bool isOnHold = false;
  bool isSendingVideo = true;
  ActiveCallPageArguments _arguments;

  void _localVideoHasChanged() {
    setState(() {
      _localVideoAspectRatio = _localVideoViewController.aspectRatio;
    });
  }

  void _remoteVideoHasChanged() {
    setState(() {
      _remoteVideoAspectRatio = _remoteVideoViewController.aspectRatio;
    });
  }

  @override
  void initState() {
    super.initState();
    _localVideoViewController.addListener(_localVideoHasChanged);
    _remoteVideoViewController.addListener(_remoteVideoHasChanged);
  }

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    _arguments =
        ModalRoute.of(context).settings.arguments;
    if (_arguments.isIncoming) {
      BlocProvider.of<ActiveCallBloc>(context).add(AnswerIncomingCall());
    } else {
      BlocProvider.of<ActiveCallBloc>(context)
          .add(StartOutgoingCall(callTo: _arguments.callTo));
    }
  }

  @override
  void dispose() {
    _localVideoViewController.removeListener(_localVideoHasChanged);
    _remoteVideoViewController.removeListener(_remoteVideoHasChanged);
    _localVideoViewController.dispose();
    _remoteVideoViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void _hangup() {
      BlocProvider.of<ActiveCallBloc>(context).add(EndCall());
    }

    void _hold() {
      BlocProvider.of<ActiveCallBloc>(context).add(HoldCall(doHold: !isOnHold));
    }

    void _sendVideo() {
      BlocProvider.of<ActiveCallBloc>(context)
          .add(SendVideo(doSend: !isSendingVideo));
    }

    void _switchCamera() {
      BlocProvider.of<ActiveCallBloc>(context).add(SwitchCamera());
    }

    return BlocListener<ActiveCallBloc, ActiveCallState>(
      listener: (context, state) {
        if (state is ActiveCallDisconnected) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.makeCall);
        }
        if (state is ActiveCallFailed) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.callFailed,
            arguments: CallFailedPageArguments(failureReason: state.errorDescription,
              endpoint: state.endpoint ?? _arguments.callTo
            )
          );
        }
        if (state is ActiveCallConnecting) {
          setState(() {
            callState = 'Connecting';
          });
        }
        if (state is ActiveCallRinging) {
          setState(() {
            callState = 'Ringing';
          });
        }
        if (state is ActiveCallConnected) {
          setState(() {
            callState = 'Connected';
          });
        }
        if (state is ActiveCallVideoStreamAdded) {
          if (state.isLocal) {
            _localVideoViewController.streamId = state.streamId;
          } else {
            _remoteVideoViewController.streamId = state.streamId;
          }
        }
        if (state is ActiveCallVideoStreamRemoved) {
          if (state.isLocal) {
            _localVideoViewController.streamId = null;
          } else {
            _remoteVideoViewController.streamId = null;
          }
        }
        if (state is ActiveCallHold) {
          setState(() {
            isOnHold = state.isHeld;
          });
        }
        if (state is ActiveCallSendVideo) {
          setState(() {
            isSendingVideo = state.isSendingVideo;
          });
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
                              callState,
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
                                icon: isSendingVideo
                                    ? Icons.videocam_off
                                    : Icons.videocam,
                                color: VoximplantColors.button,
                                tooltip: 'Send video',
                                onPressed: _sendVideo),
                            Widgets.iconButton(
                                icon: Icons.call_end,
                                color: VoximplantColors.red,
                                tooltip: 'Hang up',
                                onPressed: _hangup),
                            Widgets.iconButton(
                                icon: isOnHold ? Icons.play_arrow : Icons.pause,
                                color: VoximplantColors.button,
                                tooltip: 'Hold',
                                onPressed: _hold),
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
