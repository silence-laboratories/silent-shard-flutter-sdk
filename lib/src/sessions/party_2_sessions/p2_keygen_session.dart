// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:ffi' as ffi;

import 'package:convert/convert.dart';
import 'package:ffi/ffi.dart' as ffi_ext;

import '../../types/keyshare.dart';
import '../../ctss_bindings_generated.dart';
import '../../utils/utils.dart' as utils;
import '../../utils/string_tss_buffer.dart';

///
/// Represents party one key generation sequence. Should not be reused.
///
final class P2KeygenSession {
  final CTSSBindings _ctss;
  final String id;
  final session = ffi_ext.calloc<Handle>(1);

  P2KeygenSession(this._ctss, this.id, [Handle? refreshKeyshare]) {
    id.withTssBuffer((idBuffer) {
      int errorCode;
      if (refreshKeyshare != null) {
        errorCode = _ctss.p2_ephmeral(idBuffer, refreshKeyshare, session);
      } else {
        errorCode = _ctss.p2_keygen_init(idBuffer, session);
      }
      if (errorCode != tss_error.TSS_OK) {
        throw errorCode;
      }
    }, hex);
  }

  String processMessage1(String message1) => message1.withTssBuffer((message1Buffer) => utils.getInfoFrom(
        session.ref,
        (handle, output) => _ctss.p2_keygen_process_msg1(session.ref, message1Buffer, output),
        _ctss.tss_buffer_free,
        utils.toBase64StringUnsafe,
      ));

  Keyshare2 processMessage3(String message3) {
    var errorCode = _processMessage3(message3);
    if (errorCode != tss_error.TSS_OK) {
      throw errorCode;
    }
    return _finalize();
  }

  int _processMessage3(String message3) => message3.withTssBuffer((message3Buffer) => _ctss.p2_keygen_process_msg3(session.ref, message3Buffer));

  Keyshare2 _finalize() {
    var keyshareHandle = ffi_ext.calloc<Handle>(1);
    var errorCode = _ctss.p2_keygen_fini(session.ref, keyshareHandle);
    ffi_ext.calloc.free(session);

    if (errorCode != tss_error.TSS_OK) {
      ffi_ext.calloc.free(keyshareHandle);
      throw errorCode;
    }

    return Keyshare2(_ctss, keyshareHandle);
  }
}
