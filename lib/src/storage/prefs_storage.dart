import 'package:shared_preferences/shared_preferences.dart';
import 'storage.dart';

class PrefsStorage implements Storage {
  SharedPreferences? _prefs;

  @override
  Future<void> init() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  String? getString(String key) {
    assert(_prefs != null, 'PrefsStorage wasn\'t initialized');
    return _prefs?.getString(key);
  }

  @override
  void setString(String key, String value) {
    assert(_prefs != null, 'PrefsStorage wasn\'t initialized');
    _prefs?.setString(key, value);
  }
}
