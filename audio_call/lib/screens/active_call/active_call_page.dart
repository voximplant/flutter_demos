/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'package:audio_call/screens/active_call/active_call.dart';
import 'package:audio_call/screens/call_failed/call_failed.dart';
import 'package:audio_call/theme/voximplant_theme.dart';
import 'package:audio_call/utils/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';

class ActiveCallPage extends StatefulWidget {
  static const routeName = '/activeCall';

  @override
  State<StatefulWidget> createState() => _ActiveCallPageState();
}

class _ActiveCallPageState extends State<ActiveCallPage> {
  late ActiveCallBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = BlocProvider.of<ActiveCallBloc>(context);
    context.read<ActiveCallBloc>().add(ReadyToStartCallEvent());
  }

  @override
  Widget build(BuildContext context) {
    void hangup() => _bloc.add(HangupPressedEvent());

    void _hold(bool hold) => _bloc.add(HoldPressedEvent(hold));

    void _mute(bool mute) => _bloc.add(MutePressedEvent(mute));

    void selectAudioDevice(VIAudioDevice device) => _bloc.add(
          SelectAudioDevicePressedEvent(device),
        );

    IconData getIconForDevice(VIAudioDevice device) {
      switch (device) {
        case VIAudioDevice.Bluetooth:
          return Icons.bluetooth_audio;
        case VIAudioDevice.Speaker:
          return Icons.volume_up;
        case VIAudioDevice.WiredHeadset:
          return Icons.headset;
        default:
          return Icons.hearing;
      }
    }

    String getNameForDevice(VIAudioDevice device) {
      List<String> splitted = device.toString().split('.');
      if (splitted.length >= 2) {
        return splitted[1];
      } else {
        return device.toString();
      }
    }

    showAvailableAudioDevices(List<VIAudioDevice> devices) {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select audio device'),
            content: SingleChildScrollView(
              child: Container(
                width: 100,
                height: 100,
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (_, int index) {
                    return TextButton(
                      child: Text(
                        getNameForDevice(devices[index]),
                        style: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        selectAudioDevice(devices[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    }

    return BlocListener<ActiveCallBloc, ActiveCallState>(
      listener: (context, state) {
        if (state is CallEndedActiveCallState) {
          state.failed
              ? Navigator.of(context).pushReplacementNamed(
                  AppRoutes.callFailed,
                  arguments: CallFailedPageArguments(
                    failureReason: state.reason,
                    endpoint: state.endpointName,
                  ),
                )
              : Navigator.of(context).pushReplacementNamed(AppRoutes.main);
        }
      },
      child: BlocBuilder<ActiveCallBloc, ActiveCallState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Call'),
            ),
            backgroundColor: VoximplantColors.white,
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
                          state.endpointName,
                          style: const TextStyle(
                            fontSize: 26,
                          ),
                        ),
                        Text(
                          state.callStatus,
                          style: const TextStyle(
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
                              padding: const EdgeInsets.only(
                                bottom: 20,
                              ),
                              child: Ink(
                                decoration: const ShapeDecoration(
                                  color: VoximplantColors.white,
                                  shape: CircleBorder(
                                    side: BorderSide(
                                      width: 2,
                                      color: VoximplantColors.button,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    _mute(!state.isMuted);
                                  },
                                  iconSize: 40,
                                  icon: Icon(
                                    state.isMuted ? Icons.mic_off : Icons.mic,
                                    color: VoximplantColors.button,
                                  ),
                                  tooltip: 'Mute',
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 20,
                                right: 20,
                                left: 20,
                              ),
                              child: Ink(
                                decoration: const ShapeDecoration(
                                  color: VoximplantColors.white,
                                  shape: CircleBorder(
                                    side: BorderSide(
                                      width: 2,
                                      color: VoximplantColors.button,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    _hold(!state.isOnHold);
                                  },
                                  iconSize: 40,
                                  icon: Icon(
                                    state.isOnHold
                                        ? Icons.play_arrow
                                        : Icons.pause,
                                    color: VoximplantColors.button,
                                  ),
                                  tooltip: 'Hold',
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 20,
                              ),
                              child: Ink(
                                decoration: const ShapeDecoration(
                                  color: VoximplantColors.white,
                                  shape: CircleBorder(
                                    side: BorderSide(
                                      width: 2,
                                      color: VoximplantColors.button,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    showAvailableAudioDevices(
                                      state.availableAudioDevices,
                                    );
                                  },
                                  iconSize: 40,
                                  icon: Icon(
                                    getIconForDevice(state.activeAudioDevice),
                                    color: VoximplantColors.button,
                                  ),
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
                      padding: const EdgeInsets.only(
                        bottom: 20,
                      ),
                      child: Ink(
                        decoration: const ShapeDecoration(
                          color: VoximplantColors.white,
                          shape: CircleBorder(
                            side: BorderSide(
                              width: 2,
                              color: VoximplantColors.red,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                        child: IconButton(
                          onPressed: hangup,
                          iconSize: 40,
                          icon: const Icon(
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
        },
      ),
    );
  }
}
