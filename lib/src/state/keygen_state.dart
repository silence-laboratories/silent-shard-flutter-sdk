// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'package:flutter/foundation.dart';

import '../types/keyshare.dart';
import '../storage/local_database.dart';

class KeygenState extends ChangeNotifier {
  final LocalDatabase _database;

  KeygenState(this._database);

  Map<String, List<Keyshare2>> get keysharesMap => _database.keysharesMap;

  set keysharesMap(Map<String, List<Keyshare2>> keyshares) {
    _database.keyshares = keyshares;
    notifyListeners();
  }

  void addKeyshare(String walletId, Keyshare2 newKeyshare) {
    _database.addKeyshare(walletId, newKeyshare);
    notifyListeners();
  }

  void upsertKeyshares(String walletId, Iterable<Keyshare2> newKeyshares) {
    _database.upsertKeyshares(walletId, newKeyshares);
    notifyListeners();
  }

  void removeKeyshareBy(String walletId, String address) {
    _database.removeKeyshareBy(walletId, address);
    notifyListeners();
  }
}
