/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:audio_call/services/auth_service.dart';
import 'package:audio_call/services/call/call_event.dart';
import 'package:audio_call/services/call/call_service.dart';
import 'package:audio_call/utils/log.dart';
import 'package:audio_call/utils/navigation_helper.dart';
import 'package:flutter_callkit_voximplant/flutter_callkit_voximplant.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:uuid/uuid.dart';

// to generate uuids for callKit
var _uuid = const Uuid();

// to remember a call even when only uuid available
class CallWrapper {
  final String uuid;
  FCXCall? call;

  CallWrapper(this.uuid);

  CallWrapper.withCall(FCXCall this.call) : uuid = call.uuid;
}

class CallKitService {
  final AuthService _authService = AuthService();
  final CallService _callService = CallService();

  final FCXPlugin _plugin = FCXPlugin();
  final FCXProvider _provider = FCXProvider();
  final FCXCallController _callController = FCXCallController();

  CallWrapper? _activeCall;

  bool get _hasActiveCall => _activeCall != null;

  bool get _hasNoActiveCalls => _activeCall == null;

  bool _callStarting = false;

  // To handle late push, which call already been ended
  final List<String> _endedCalls = [];

  bool _alreadyEnded(String uuid) => _endedCalls.contains(uuid);

  factory CallKitService() {
    return _instance;
  }

  static final CallKitService _instance = CallKitService._();

  CallKitService._() {
    _configure();
    _callService.subscribeToCallEvents().listen((event) {
      if (event is OnDisconnectedCallEvent && _hasActiveCall) {
        _reportEnded(_activeCall?.uuid, FCXCallEndedReason.declinedElsewhere);
      }
    });
  }

  Future<void> _configure() async {
    _plugin.didDisplayIncomingCall = (uuid, update) async {
      if (_alreadyEnded(uuid)) {
        return;
      }
      try {
        if (_hasActiveCall) {
          if (_activeCall?.uuid != uuid) {
            await _reportEnded(uuid, FCXCallEndedReason.failed);
          }
          return;
        } else {
          _activeCall = CallWrapper(uuid);
        }
        await _authService.loginWithAccessToken();
        await _commitTransactions();
      } catch (e) {
        _log('There was an error $e, ending call');
        await _reportEnded(uuid, FCXCallEndedReason.failed);
      }
    };

    _provider.performStartCallAction = (startCallAction) async {
      if (_hasActiveCall) {
        if (_activeCall?.uuid != startCallAction.callUuid) {
          startCallAction.fail();
          return;
        }
      } else {
        _activeCall = CallWrapper(startCallAction.callUuid);
      }

      _callStarting = false;

      try {
        await Voximplant().audioDeviceManager.callKitConfigureAudioSession();
        await _callService.makeCall(callTo: startCallAction.handle.value);
        _callService.callKitUUID = startCallAction.callUuid;
        await _provider.reportOutgoingCall(startCallAction.callUuid, null);
        await startCallAction.fulfill();
      } catch (e) {
        forgetCall(startCallAction.callUuid);
        _log('There was an error $e, failing startCallAction');
        await startCallAction.fail();
      }
    };

    _provider.executeTransaction = (transaction) {
      _log('Should execute or delay transaction...');

      if ((_authService.clientState == VIClientState.LoggedIn || _authService.clientState == VIClientState.Reconnecting)
          && (_callService.hasActiveCall || _callStarting)
      ) {
        _log('Executing transaction now');
        return false;
      } else if (_authService.clientState == VIClientState.Disconnected || _authService.clientState == VIClientState.Connected) {
        _log('Need to connect or login...');
        Future<void> loginAndCommitTransactions() async {
          try {
            await _authService.loginWithAccessToken();
            await _commitTransactions();
          } catch (e) {
            _log('There was an error $e, failing');
            final callKitUUID = _callService.callKitUUID;
            if (callKitUUID != null) {
              await _provider.reportCallEnded(
                  callKitUUID, null, FCXCallEndedReason.failed);
            }
          }
        }
        loginAndCommitTransactions();
      }
      _log('Delaying transaction');
      return true;
    };

    _provider.performEndCallAction = (endCallAction) async {
      if (endCallAction.callUuid != _activeCall?.uuid) {
        forgetCall(endCallAction.callUuid);
        endCallAction.fail();
        return;
      }

      Future<void> end() async {
        try {
          (_activeCall?.call?.outgoing ?? false) ||
                  (_activeCall?.call?.hasConnected ?? false)
              ? await _callService.hangup()
              : await _callService.decline();
          await Voximplant().audioDeviceManager.callKitReleaseAudioSession();
          forgetCall(endCallAction.callUuid);
          await endCallAction.fulfill();
        } catch (e) {
          _log('There was an error $e, failing endCallAction');
          await endCallAction.fail();
        }
      }

      // if already received call via Voximplant
      if (_callService.hasActiveCall) {
        await end();
        // else should wait till Voximplant send onIncomingCall
      } else {
        _callService.onIncomingCall = () async => await end();
      }
    };

    _provider.performAnswerCallAction = (answerCallAction) async {
      if (_hasNoActiveCalls) {
        _log('Active call is null, failing answerCallAction');
        await answerCallAction.fail();
        return;
      }

      NavigationHelper.pushToActiveCall(isIncoming: true, callTo: "");

      Future<void> answer() async {
        try {
          await Voximplant().audioDeviceManager.callKitConfigureAudioSession();
          await _callService.answerCall();
          await answerCallAction.fulfill();
        } catch (e) {
          _log('There was an error $e, failing answerCallAction');
          await answerCallAction.fail();
        }
      }

      // if already received call via Voximplant
      if (_callService.hasActiveCall) {
        await answer();
        // else should wait till Voximplant send onIncomingCall
      } else {
        _callService.onIncomingCall = () async => await answer();
      }
    };

    _provider.performSetHeldCallAction = (setHeldCallAction) async {
      if (_hasNoActiveCalls) {
        _log('Active call is null, failing setHeldCallAction');
        await setHeldCallAction.fail();
        return;
      }
      try {
        await _callService.holdCall(hold: setHeldCallAction.onHold);
        await setHeldCallAction.fulfill();
      } catch (e) {
        _log('There was an error $e, failing setHeldCallAction');
        await setHeldCallAction.fail();
      }
    };

    _provider.performSetMutedCallAction = (setMutedCallAction) async {
      if (_hasNoActiveCalls) {
        _log('Active call is null, failing setMutedCallAction');
        await setMutedCallAction.fail();
        return;
      }
      try {
        await _callService.muteCall(mute: setMutedCallAction.muted);
        await setMutedCallAction.fulfill();
      } catch (e) {
        _log('There was an error $e, failing setMutedCallAction');
        await setMutedCallAction.fail();
      }
    };

    _provider.providerDidActivateAudioSession =
        () async => await Voximplant().audioDeviceManager.callKitStartAudio();

    _provider.providerDidDeactivateAudioSession =
        () async => await Voximplant().audioDeviceManager.callKitStopAudio();

    _callController.callObserver.callChanged = (call) async {
      if (call.hasEnded) {
        return;
      }

      if (_alreadyEnded(call.uuid)) {
        return;
      }

      if (_hasNoActiveCalls) {
        _activeCall = CallWrapper.withCall(call);
        return;
      }

      if (call.uuid == _activeCall?.uuid) {
        _activeCall?.call = call;
      } else {
        await _reportEnded(call.uuid, FCXCallEndedReason.failed);
      }
    };

    // Its recommended to configure AFTER all callbacks been set
    // to prevent race conditions
    await _callController.configure();
    await _provider.configure(FCXProviderConfiguration(
      'AudioCall',
      iconTemplateImageName: 'CallKitLogo',
      includesCallsInRecents: true,
      supportsVideo: true,
      maximumCallsPerCallGroup: 1,
      supportedHandleTypes: <FCXHandleType>{FCXHandleType.Generic},
    ));
  }

  Future<void> _commitTransactions() async {
    List<FCXTransaction> transactions =
    await _provider.getPendingTransactions();
    for (final transaction in transactions) {
      List<FCXAction> actions = await transaction.getActions();
      for (final action in actions) {
        if (action is FCXStartCallAction) {
          final perform = _provider.performStartCallAction;
          if (perform != null) {
            perform(action);
          }
        }
        if (action is FCXAnswerCallAction) {
          final perform = _provider.performAnswerCallAction;
          if (perform != null) {
            perform(action);
          }
        }
        if (action is FCXEndCallAction) {
          final perform = _provider.performEndCallAction;
          if (perform != null) {
            perform(action);
          }
        }
        if (action is FCXSetHeldCallAction) {
          final perform = _provider.performSetHeldCallAction;
          if (perform != null) {
            perform(action);
          }
        }
        if (action is FCXSetMutedCallAction) {
          final perform = _provider.performSetMutedCallAction;
          if (perform != null) {
            perform(action);
          }
        }
        if (action is FCXSetGroupCallAction) {
          final perform = _provider.performSetGroupCallAction;
          if (perform != null) {
            perform(action);
          }
        }
        if (action is FCXPlayDTMFCallAction) {
          final perform = _provider.performPlayDTMFCallAction;
          if (perform != null) {
            perform(action);
          }
        }
      }
    }
  }

  Future<void> createIncomingCall(
    String uuid,
    String username,
    String displayName,
  ) async {
    if (_hasActiveCall) {
      if (_activeCall?.uuid == uuid) {
        return;
      } else {
        throw 'There is already an active call';
      }
    }

    await _provider.reportNewIncomingCall(
      uuid,
      FCXCallUpdate(
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        supportsDTMF: false,
        hasVideo: false,
        localizedCallerName: displayName,
      ),
    );
  }

  Future<void> startOutgoingCall(String contactName) async {
    if (_hasActiveCall) {
      throw 'Already have an active call, throwing from startOutgoingCall';
    }
    FCXHandle handle = FCXHandle(FCXHandleType.Generic, contactName);
    FCXStartCallAction action = FCXStartCallAction(_uuid.v4(), handle);
    _callStarting = true;
    await _callController.requestTransactionWithAction(action);
  }

  Future<void> reportConnected(String username, String displayName) async {
    if (_hasNoActiveCalls) {
      throw 'Active call is null, reportConnected failed';
    }
    final call = _activeCall?.call;
    if (call == null) {
      return;
    }
    if (call.outgoing) {
      await _reportOutgoingCallConnected();
    }
    await _reportUpdated(username, displayName);
  }

  Future<void> _reportOutgoingCallConnected() async {
    final call = _activeCall?.call;
    if (call == null || call.hasConnected) {
      return;
    }
    await _provider.reportOutgoingCallConnected(call.uuid, null);
  }

  Future<void> _reportUpdated(String username, String displayName) async {
    final call = _activeCall?.call;
    if (call == null) {
      return;
    }
    await _provider.reportCallUpdated(
      call.uuid,
      FCXCallUpdate(
        hasVideo: false,
        localizedCallerName: displayName,
      ),
    );
  }

  Future<void> holdCall(bool hold) async {
    if (_hasNoActiveCalls) {
      throw 'Active call is null, holdCall failed';
    }
    final call = _activeCall?.call;
    if (call == null || call.hasConnected) {
      return;
    }
    await _callController.requestTransactionWithAction(
        FCXSetHeldCallAction(call.uuid, hold));
  }

  Future<void> muteCall(bool mute) async {
    if (_hasNoActiveCalls) {
      throw 'Active call is null, muteCall failed';
    }
    final call = _activeCall?.call;
    if (call == null || call.hasConnected) {
      return;
    }
    await _callController.requestTransactionWithAction(
        FCXSetMutedCallAction(call.uuid, mute));
  }

  Future<void> endCall() async {
    if (_hasNoActiveCalls) {
      throw 'Active call is null, endCall failed';
    }
    final call = _activeCall?.call;
    if (call == null) {
      return;
    }
    await _callController
        .requestTransactionWithAction(FCXEndCallAction(call.uuid));
  }

  Future<void> reportCallEnded(
      {FCXCallEndedReason reason = FCXCallEndedReason.failed}) async {
    await _reportEnded(_activeCall?.uuid, reason);
  }

  void forgetCall(String uuid) {
    if (!_alreadyEnded(uuid)) {
      _endedCalls.add(uuid);
    }
    if (uuid == _activeCall?.uuid) {
      _activeCall = null;
    }
  }

  Future<void> _reportEnded(String? uuid, FCXCallEndedReason reason) async {
    if (uuid == null) {
      return;
    }
    await _provider.reportCallEnded(uuid, null, reason);
    forgetCall(uuid);
    if (_activeCall?.uuid == uuid) {
      await _failTransactions();
      await _plugin.processPushCompletion();
    }
  }

  Future<void> _failTransactions() async {
    List<FCXAction> actions = [];
    for (var transaction in (await _provider.getPendingTransactions())) {
      actions.addAll(await transaction.getActions());
    }

    if (actions.isNotEmpty) {
      for (var action in actions) {
        await action.fail();
      }
    }
  }

  void _log<T>(T message) {
    log('CallKitService($hashCode): ${message.toString()}');
  }
}
