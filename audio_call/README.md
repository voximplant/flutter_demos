# audio_call

This demo demonstrates basic audio call functionality of the Voximplant Flutter SDK. 

It is possible to make audio calls with any application (mobile or web) that have integrated
Voximplant SDKs.

## Features

The application is able to:

- log in to the Voximplant Cloud
- make an audio call
- receive an incoming call
- put a call on hold / take it off hold
- change an audio device (speaker, receiver, wired headset, bluetooth headset) during a call
- mute audio during a call

## Getting started

To get started, you'll need to register a free Voximplant developer account.

You'll need the following:

- Voximplant application
- two Voximplant users
- VoxEngine scenario
- routing setup

#### VoxEngine scenario example
```js
require(Modules.PushService);
VoxEngine.addEventListener(AppEvents.CallAlerting, (e) => {
const newCall = VoxEngine.callUserDirect(
  e.call, 
  e.destination,
  e.callerid,
  e.displayName,
  null
);
VoxEngine.easyProcess(e.call, newCall, ()=>{}, true);
});
```

## Instaling
1. Clone this repo
2. Run `flutter pub get`
3. For iOS, go to `audio_call/ios` directory and run `pod install`

--------------------------------------------------------------------------------
In these demo sound resources are used whose authors are:
* [fennelliott_beeping.wav](ios/Runner) by author [fennelliott](https://freesound.org/people/fennelliott/sounds/379419/) with [CC-BY-3.0](https://creativecommons.org/licenses/by/3.0/legalcode) license

