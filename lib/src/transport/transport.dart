// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

/// Simple abstraction of underlying NoSQL shared remote database
/// between two parties, used as a means of communication channel
abstract interface class Transport {
  /// Provide real-time updates of [collection] and document with [docId]
  Stream<Map<String, dynamic>?> updates(String collection, String docId);

  /// Set specific document with [docId] in [collection]
  Future<void> set(String collection, String docId, Map<String, dynamic> data);

  /// Update specific document with [docId] in [collection]
  Future<void> update(String collection, String docId, Map<String, dynamic> data);

  /// Delete specific document with [docId] in [collection]
  Future<void> delete(String collection, String docId);
}
