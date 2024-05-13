// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'package:flutter/foundation.dart';

import '../storage/local_database.dart';
import '../types/pairing_data.dart';

class PairingState extends ChangeNotifier {
  final LocalDatabase _database;

  PairingState(this._database);

  Map<String, PairingData> get pairingDataMap => _database.pairingDataMap;

  void setPairingData(String? address, PairingData data) {
    _database.setPairingData(address, data);
    notifyListeners();
  }

  void removePairingDataBy(String address) {
    _database.removePairingDataBy(address);
    notifyListeners();
  }
}
