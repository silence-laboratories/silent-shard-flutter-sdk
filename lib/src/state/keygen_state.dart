// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'package:flutter/foundation.dart';

import '../types/keyshare.dart';
import '../storage/local_database.dart';

class KeygenState extends ChangeNotifier {
  final LocalDatabase _database;

  KeygenState(this._database);

  Map<String, List<Keyshare2>> get keyshares => _database.keyshares;

  set keyshares(Map<String, List<Keyshare2>> keyshares) {
    _database.keyshares = keyshares;
    notifyListeners();
  }

  void addKeyshare(String walletName, Keyshare2 newKeyshare) {
    _database.addKeyshare(walletName, newKeyshare);
    notifyListeners();
  }

  void addKeyshares(String walletName, Iterable<Keyshare2> newKeyshares) {
    _database.addKeyshares(walletName, newKeyshares);
    notifyListeners();
  }

  void removeKeyshareAt(String walletName, int index) {
    _database.removeKeyshareAt(walletName, index);
    notifyListeners();
  }

  void removeAllKeyshares() {
    _database.removeAllKeyshares();
    notifyListeners();
  }
}
