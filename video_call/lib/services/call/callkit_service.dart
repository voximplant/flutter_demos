/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:flutter_callkit_voximplant/flutter_callkit_voximplant.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:uuid/uuid.dart';
import 'package:video_call/services/navigation_helper.dart';
import 'package:video_call/services/auth_service.dart';
import 'package:video_call/services/call/call_service.dart';

var _uuid = Uuid();

class CallKitService {
  final AuthService _authService;
  final CallService _callService;

  final FCXPlugin _plugin;
  final FCXProvider _provider;
  final FCXCallController _callController;

  bool get hasActiveCall => _activeCall != null;
  bool get _hasNoActiveCalls => _activeCall == null;
  FCXCall _activeCall;

  factory CallKitService() => _cache ?? CallKitService._();
  static CallKitService _cache;
  CallKitService._()
      : this._authService = AuthService(),
        this._callService = CallService(),
        this._plugin = FCXPlugin(),
        this._provider = FCXProvider(),
        this._callController = FCXCallController() {
    _configure();
    _cache = this;
  }

  Future<void> _configure() async {
    await _callController.configure();
    await _provider.configure(FCXProviderConfiguration(
      'VideoCall',
      iconTemplateImageName: 'CallKitLogo',
      includesCallsInRecents: true,
      supportsVideo: true,
      maximumCallsPerCallGroup: 1,
      supportedHandleTypes: <FCXHandleType>{FCXHandleType.Generic},
    ));

    _provider.performStartCallAction = (startCallAction) async {
      if (hasActiveCall && _activeCall.uuid != startCallAction.callUuid) {
        print('Already have active call, failing startCallAction');
        startCallAction.fail();
        return;
      }
      try {
        await _callService.makeVideoCall(callTo: startCallAction.handle.value);
        _callService.callKitUUID = startCallAction.callUuid;
        await Voximplant()
            .getAudioDeviceManager()
            .callKitConfigureAudioSession();
        await _provider.reportOutgoingCall(startCallAction.callUuid, null);
        await startCallAction.fulfill();
      } catch (e) {
        print('There was an error $e, failing startCallAction');
        await startCallAction.fail();
      }
    };

    _provider.performEndCallAction = (endCallAction) async {
      if (_hasNoActiveCalls) {
        print('Active call is null, failing endCallAction');
        await endCallAction.fail();
        return;
      }
      try {
        _activeCall.outgoing || _activeCall.hasConnected
            ? await _callService.hangup()
            : await _callService.decline();
        await Voximplant().getAudioDeviceManager().callKitReleaseAudioSession();
        await _plugin.processPushCompletion();
        await endCallAction.fulfill();
      } catch (e) {
        print('There was an error $e, failing endCallAction');
        await endCallAction.fail();
      }
    };

    _provider.performAnswerCallAction = (answerCallAction) async {
      if (_hasNoActiveCalls) {
        print('Active call is null, failing answerCallAction');
        await answerCallAction.fail();
        return;
      }
      try {
        NavigationHelper.pushToActiveCall(isIncoming: true, callTo: null);
        await Voximplant()
            .getAudioDeviceManager()
            .callKitConfigureAudioSession();
        Future<void> Function() answerCall = () async {
          await _callService.answerVideoCall();
          await _plugin.processPushCompletion();
          await answerCallAction.fulfill();
        };
        // if already received call via Voximplant
        if (_callService.hasActiveCall) {
          await answerCall();
          return;
        }
        // else should wait till Voximplant send onIncomingCall
        _callService.answerOnceReady = () async => await answerCall();
      } catch (e) {
        print('There was an error $e, failing answerCallAction');
        await answerCallAction.fail();
      }
    };

    _provider.performSetHeldCallAction = (setHeldCallAction) async {
      if (_hasNoActiveCalls) {
        print('Active call is null, failing setHeldCallAction');
        await setHeldCallAction.fail();
        return;
      }
      try {
        await _callService.holdCall(hold: setHeldCallAction.onHold);
        await setHeldCallAction.fulfill();
      } catch (e) {
        print('There was an error $e, failing setHeldCallAction');
        await setHeldCallAction.fail();
      }
    };

    _provider.performSetMutedCallAction = (setMutedCallAction) async {
      if (_hasNoActiveCalls) {
        print('Active call is null, failing setMutedCallAction');
        await setMutedCallAction.fail();
        return;
      }
      try {
        await _callService.muteCall(mute: setMutedCallAction.muted);
        await setMutedCallAction.fulfill();
      } catch (e) {
        print('There was an error $e, failing setMutedCallAction');
        await setMutedCallAction.fail();
      }
    };

    _provider.providerDidActivateAudioSession = () async =>
      await Voximplant().getAudioDeviceManager().callKitStartAudio();

    _provider.providerDidDeactivateAudioSession = () async =>
      await Voximplant().getAudioDeviceManager().callKitStopAudio();

    _callController.callObserver.callChanged = (call) async {
      if (_hasNoActiveCalls) {
        _activeCall = call;
        return;
      }

      if (call.uuid == _activeCall.uuid) {
        _activeCall = call.hasEnded ? null : call;
      } else {
        print('Received callChanged for a wrong call, ending it');
        _provider.reportCallEnded(call.uuid, null, FCXCallEndedReason.failed);
      }
    };

    _provider.executeTransaction = (transaction) {
      if (_authService.clientState == VIClientState.LoggedIn) {
        return false;
      }
      if (_authService.clientState == VIClientState.Disconnected) {
        _authService
            .loginWithAccessToken()
            .then((_) => _provider
                .getPendingTransactions()
                .then((transactions) => _commitTransactions(transactions)
                    .catchError((e) => reportCallEnded()))
                .catchError((e) => reportCallEnded()))
            .catchError((e) => reportCallEnded());
      }
      return true;
    };
  }

  Future<void> _commitTransactions(List<FCXTransaction> transactions) async =>
      transactions.forEach((transaction) async {
        List<FCXAction> actions = await transaction.getActions();
        actions.forEach((action) {
          if (action is FCXStartCallAction)
            _provider.performStartCallAction(action);
          else if (action is FCXAnswerCallAction)
            _provider.performAnswerCallAction(action);
          else if (action is FCXEndCallAction)
            _provider.performEndCallAction(action);
          else if (action is FCXSetHeldCallAction)
            _provider.performSetHeldCallAction(action);
          else if (action is FCXSetMutedCallAction)
            _provider.performSetMutedCallAction(action);
          else if (action is FCXSetGroupCallAction)
            _provider.performSetGroupCallAction(action);
          else if (action is FCXPlayDTMFCallAction)
            _provider.performPlayDTMFCallAction(action);
          else
            print('Cant commit action ${action.uuid} ${action.runtimeType}');
        });
      });

  Future<void> createIncomingCall(
      String uuid, String username, String displayName, bool video) async {
    if (hasActiveCall) {
      throw 'There is already an active call';
    }

    await _provider.reportNewIncomingCall(
      uuid,
      FCXCallUpdate(
        remoteHandle: FCXHandle(FCXHandleType.Generic, username),
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        supportsDTMF: false,
        hasVideo: video,
        localizedCallerName: displayName,
      ),
    );
  }

  Future<void> startOutgoingCall(String contactName) async {
    FCXHandle handle = FCXHandle(FCXHandleType.Generic, contactName);
    FCXStartCallAction action = FCXStartCallAction(_uuid.v4(), handle);
    await _callController.requestTransactionWithAction(action);
  }

  Future<void> reportConnected(
      String username, String displayName, bool hasVideo) async {
    if (_hasNoActiveCalls) {
      throw 'Active call is null, reportConnected failed';
    }
    _activeCall.outgoing
        ? await _reportOutgoingCallConnected()
        : await _reportUpdated(username, displayName, hasVideo);
  }

  Future<void> _reportOutgoingCallConnected() async {
    if (_activeCall.hasConnected) { return; }
    await _provider.reportOutgoingCallConnected(_activeCall?.uuid, null);
  }

  Future<void> _reportUpdated(
          String username, String displayName, bool hasVideo) async =>
      await _provider.reportCallUpdated(
        _activeCall?.uuid,
        FCXCallUpdate(
          remoteHandle: FCXHandle(FCXHandleType.Generic, username),
          hasVideo: hasVideo,
          localizedCallerName: displayName,
        ),
      );

  Future<void> holdCall(bool hold) async {
    if (_hasNoActiveCalls) {
      throw 'Active call is null, holdCall failed';
    }
    if (!_activeCall.hasConnected) {
      print('Cant hold due to call not being connected yet');
      return;
    }
    await _callController.requestTransactionWithAction(
        FCXSetHeldCallAction(_activeCall.uuid, hold));
  }

  Future<void> muteCall(bool mute) async {
    if (_hasNoActiveCalls) {
      throw 'Active call is null, muteCall failed';
    }
    if (!_activeCall.hasConnected) {
      print('Cant mute due to call not being connected yet');
      return;
    }
    await _callController.requestTransactionWithAction(
        FCXSetMutedCallAction(_activeCall.uuid, mute));
  }

  Future<void> sendVideo(bool send) async {
    if (_hasNoActiveCalls) {
      throw 'Active call is null, sendVideo failed';
    }
    await _provider.reportCallUpdated(
      _activeCall.uuid,
      FCXCallUpdate(hasVideo: send),
    );
    await _callService.sendVideo(send: send);
  }

  Future<void> endCall() async {
    if (_hasNoActiveCalls) {
      throw 'Active call is null, endCall failed';
    }
    await _callController
        .requestTransactionWithAction(FCXEndCallAction(_activeCall.uuid));
  }

  Future<void> reportCallEnded(
      {FCXCallEndedReason reason = FCXCallEndedReason.failed}) async {
    if (_hasNoActiveCalls) {
      throw 'Active call is null, reportCallEnded failed';
    }

    List<FCXTransaction> transactions =
        await _provider.getPendingTransactions();

    if (transactions.isNotEmpty) {
      transactions.forEach((transaction) async {
        List<FCXAction> pendingActions = await transaction.getActions();
        if (pendingActions.isNotEmpty) {
          pendingActions.forEach((action) async => await action.fail());
        }
      });
    }

    await _provider.reportCallEnded(_activeCall.uuid, null, reason);
  }
}