import 'package:flutter/foundation.dart';

import '../types/keyshare.dart';
import '../storage/local_database.dart';

class KeygenState extends ChangeNotifier {
  final LocalDatabase _database;

  KeygenState(this._database);

  List<Keyshare2> get keyshares => _database.keyshares;

  set keyshares(Iterable<Keyshare2> keyshares) {
    _database.keyshares = keyshares;
    notifyListeners();
  }

  void addKeyshare(Keyshare2 newKeyshare) {
    _database.addKeyshare(newKeyshare);
    notifyListeners();
  }

  void addKeyshares(Iterable<Keyshare2> newKeyshares) {
    _database.addKeyshares(newKeyshares);
    notifyListeners();
  }

  void removeKeyshareAt(int index) {
    _database.removeKeyshareAt(index);
    notifyListeners();
  }

  void removeAllKeyshares() {
    _database.removeAllKeyshares();
    notifyListeners();
  }
}
