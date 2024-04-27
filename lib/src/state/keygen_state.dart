// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'package:flutter/foundation.dart';

import '../types/keyshare.dart';
import '../storage/local_database.dart';

class KeygenState extends ChangeNotifier {
  final LocalDatabase _database;

  KeygenState(this._database);

  Map<String, List<Keyshare2>> get keysharesMap => _database.keyshares;

  set keysharesMap(Map<String, List<Keyshare2>> keyshares) {
    _database.keyshares = keyshares;
    notifyListeners();
  }

  void addKeyshare(String walletId, Keyshare2 newKeyshare) {
    _database.addKeyshare(walletId, newKeyshare);
    notifyListeners();
  }

  void replaceKeyshares(String walletId, Iterable<Keyshare2> newKeyshares) {
    _database.replaceKeyshares(walletId, newKeyshares);
    notifyListeners();
  }

  void removeKeyshareAt(String walletId, int index) {
    _database.removeKeyshareAt(walletId, index);
    notifyListeners();
  }

  void removeAllKeyshares(String walletId) {
    _database.removeAllKeyshares(walletId);
    notifyListeners();
  }
}
