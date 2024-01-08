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

## Usage examples
