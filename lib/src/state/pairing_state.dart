import 'package:flutter/foundation.dart';

import '../storage/local_database.dart';
import '../types/pairing_data.dart';

class PairingState extends ChangeNotifier {
  final LocalDatabase _database;

  PairingState(this._database);

  PairingData? get pairingData => _database.pairingData;

  set pairingData(PairingData? data) {
    _database.pairingData = data;
    notifyListeners();
  }
}
