import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ffi/ffi.dart' as ffi_ext;
import 'package:hashlib/hashlib.dart';

import '../ctss_bindings_generated.dart';
import '../utils/utils.dart' as utils;
import '../utils/string_tss_buffer.dart';

/// Base keyshare class
abstract class Keyshare {
  // String get id;

  Uint8List get publicKeyData;

  String get publicKey;

  String get publicKeyHex;

  String get ethAddress {
    final hash = keccak256.convert(publicKeyData.sublist(1));
    final addressBytes = hash.buffer.asUint8List(12, 20);
    return '0x${hex.encode(addressBytes)}';
  }

  String toBytes();

  void free();
}

/// Party two keyshare (part of distributed key).
final class Keyshare2 extends Keyshare {
  final CTSSBindings _ctss;
  late final ffi.Pointer<Handle> handle;

  Keyshare2(this._ctss, this.handle);

  Keyshare2.fromBytes(this._ctss, String bytes) {
    handle = ffi_ext.calloc<Handle>(1);
    var bytesBuffer = bytes.toTssBuffer();

    int errCode = _ctss.p2_keyshare_from_bytes(bytesBuffer, handle);
    utils.freeTssBuffer(bytesBuffer);

    if (errCode != tss_error.TSS_OK) {
      ffi_ext.calloc.free(handle);
      throw errCode;
    }
  }

  // @override
  // String get id => utils.getInfoFrom(handle.ref, _ctss.p2_keyshare_key_id, _ctss.tss_buffer_free, utils.fromAsciiBytesUnsafe);

  @override
  Uint8List get publicKeyData => utils.getInfoFrom(handle.ref, _ctss.p2_keyshare_public_key, _ctss.tss_buffer_free, utils.toBytesUnsafe);

  @override
  String get publicKey => utils.getInfoFrom(handle.ref, _ctss.p2_keyshare_public_key, _ctss.tss_buffer_free, utils.toBase64StringUnsafe);

  @override
  String get publicKeyHex => utils.getInfoFrom(handle.ref, _ctss.p2_keyshare_public_key, _ctss.tss_buffer_free, utils.toHexStringUnsafe);

  @override
  String toBytes() => utils.getInfoFrom(handle.ref, _ctss.p2_keyhare_to_bytes, _ctss.tss_buffer_free, utils.toBase64StringUnsafe);

  @override
  void free() {
    _ctss.p2_keyshare_free(handle.ref);
  }
}
