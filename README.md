# dart_2_party_ecdsa

Dart client SDK for a two party ECDSA TSS (Threshold Signature Scheme). 
Its built on top of Rust-based ECDSA library which utilizes Multiparty Computation (MPC). MPC allows multiple parties to jointly compute digital signatures without exposing their private inputs. Threshold signature scheme enables a minimum number of pre-selected participants to jointly create a cryptographic digital signature using multiparty computation. ECDSA is one type of such a signature scheme based on elliptic curves.

## Functionality overview
- Pairing with remote counterpart
- Key generation
- Signature generation
- Backups

## Getting Started

### To add plugin as a dependency in external app:

1. Add the following to your `pubspec.yaml`:
    ```yaml
    dependencies:
      dart_2_party_ecdsa:
        git:
          url: https://github.com/silence-laboratories/silent-shard-flutter-sdk.git
          ref: release tag

    ```
2. Run ```flutter pub get``` from terminal

## Project structure

* `lib`: contains the Dart code that defines high-level API, and 
  calls into the native code using `dart:ffi`.

* platform folders (`android`, `ios`, `macos`): Contains the build artifacts for bundling the native code libraries with the platform application.

* `example`: sample app for different platforms running integration tests, showcasing usage and serving as an example.

## Development Updates

The binary is built using the following branch: https://github.com/silence-laboratories/rust-2-party-ecdsa/tree/feat/legacy

The binary is a latest commit regarding building scripts. 

Run following scripts 
```
sh ci/build-gmp-android.sh
sh ci/build-gmp-darwin.sh
sh ci/build-android-ctss.sh
sh ci/build-darwin.ctss.sh
```

This will create structured artifacts in the builds directory.

Rust version used is 1.77 during the last build.

## Breaking Changes

### Android
- **Minimum SDK Version Increased**: The minimum Android SDK version has been increased from 16 to 24
- **Impact**: Apps running on Android versions below 7.0 (API level 24) will no longer be supported
- **Affected Devices**: Android 4.1-6.0 devices will not be able to use this SDK
- **Migration**: Ensure your app's `minSdkVersion` is set to at least 24 in your `build.gradle` file

### iOS
- **Platform Version Increased**: The minimum iOS platform version has been increased from 11.0 to 13.0
- **Impact**: Devices running iOS versions below 13.0 will no longer be supported
- **Affected Devices**: iOS 11.0-12.x devices will not be able to use this SDK
- **Migration**: Update your `ios/Podfile` and deployment target to at least iOS 13.0