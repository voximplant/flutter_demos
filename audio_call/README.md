# audio_call

This demo demonstrates basic audio call functionality of the Voximplant Flutter SDK. The application supports audio calls between this mobile applications that use any Voximplant SDK.

This demo application doesn't handle push notifications, so it doesn't receive incoming calls if the application is in the background or killed.
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
});
```

## Instaling
1. Clone this repo
2. Run `flutter pub get`
3. For iOS, go to `audio_call/ios` directory and run `pod install`


