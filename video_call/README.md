# video_call

This demo demonstrates basic video call functionality of the Voximplant Flutter SDK. 
It is possible to make video calls with any application (mobile or web) that have integrated
Voximplant SDKs.

This demo application doesn't handle push notifications, so it doesn't receive incoming 
calls if the application is in the background or killed.

## Features

The application is able to:

- log in to the Voximplant Cloud
- make a video call
- receive an incoming call
- put a call on hold / take it off hold
- stop/start sending video during a call

## Getting started

To get started, you'll need to register a free Voximplant developer account.

You'll need the following:

- Voximplant application
- two Voximplant users
- VoxEngine scenario
- routing setup

#### VoxEngine scenario example
```js
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
