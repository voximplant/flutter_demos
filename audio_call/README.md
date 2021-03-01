# audio_call

This demo demonstrates basic audio call functionality of the Voximplant Flutter SDK. 

It is possible to make audio calls with any application (mobile or web) that have integrated
Voximplant SDKs.

## Features

The application is able to:

- log in to the Voximplant Cloud
- auto login using access tokens
- make an audio call
- receive an incoming call
- put a call on hold / take it off hold
- change an audio device (speaker, receiver, wired headset, bluetooth headset) during a call
- mute audio during a call
- play VIAudioFile progresstone on ringing
- push notifications
- CallKit integration (iOS)

## Getting started

To get started, you'll need to [register](https://manage.voximplant.com/auth/sign_up) a free Voximplant developer account.

You'll need the following:

- Voximplant application
- two Voximplant users
- VoxEngine scenario
- routing setup
- VoIP services certificate for iOS push notifications. Follow [this tutorial](https://voximplant.com/docs/introduction/integration/adding_sdks/push_notifications/ios_sdk) to upload the certificate to the Voximplant Control Panel
- Push certificate for Android push notifications. Follow [this tutorial](https://voximplant.com/docs/howtos/sdks/push_notifications/android_sdk) to upload the certificate to the Voximplant Control Panel

### Automatic

We've implemented a special template to enable you to quickly use the demo – just
install [SDK tutorial](https://manage.voximplant.com/marketplace/sdk_tutorial) from our marketplace:
![marketplace](Screenshots/market.png)

### Manual

You can set up it manually using our [Getting started](https://voximplant.com/docs/introduction) guide and tutorials

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

## Installing
1. Clone this repo
2. Run `flutter pub get`

## Usage

### User login

Log in using:
* Voximplant user name in the format `user@app.account`
* password

### Make calls

Enter a Voximplant user name to the input field and press "Call" button to make a call.

--------------------------------------------------------------------------------
In these demo sound resources are used whose authors are:
* [fennelliott_beeping.wav](ios/Runner) by author [fennelliott](https://freesound.org/people/fennelliott/sounds/379419/) with [CC-BY-3.0](https://creativecommons.org/licenses/by/3.0/legalcode) license

