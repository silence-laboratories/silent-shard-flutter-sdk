// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

/// Abstraction of a persistent key-value storage
abstract interface class Storage {
  /// Subclasses can override this functions to perform any initialization required
  Future<void> init() async => Future.value();

  String? getString(String key);

  void setString(String key, String value);
}
