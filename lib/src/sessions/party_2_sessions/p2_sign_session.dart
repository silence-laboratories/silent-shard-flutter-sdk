import 'dart:ffi' as ffi;

import 'package:convert/convert.dart';
import 'package:ffi/ffi.dart' as ffi_ext;

import '../../types/keyshare.dart';
import '../../ctss_bindings_generated.dart';
import '../../utils/utils.dart' as utils;
import '../../utils/string_tss_buffer.dart';

///
/// Represents party one signature generation sequence. Should not be reused.
///
final class P2SignSession {
  final CTSSBindings _ctss;
  final String id;
  final Keyshare2 keyshare;
  final session = ffi_ext.calloc<Handle>(1);

  P2SignSession(this._ctss, this.id, this.keyshare, String messageHash, [String derivationPath = 'm']) {
    id.withTssBuffer((idBuffer) {
      messageHash.withTssBuffer((messageHashBuffer) {
        derivationPath.withTssBuffer((derivationPathBuffer) {
          int errorCode = _ctss.p2_init_signer(idBuffer, keyshare.handle.ref, messageHashBuffer, /*derivationPathBuffer,*/ session);
          if (errorCode != tss_error.TSS_OK) {
            throw errorCode;
          }
        }, null);
      }, hex);
    }, hex);
  }

  String processMessage1(String message1) => message1.withTssBuffer((message1Buffer) => utils.getInfoFrom(
        session.ref,
        (handle, output) => _ctss.p2_signer_process_msg1(handle, message1Buffer, output),
        _ctss.tss_buffer_free,
        utils.toBase64StringUnsafe,
      ));

  String processMessage3(String message3) => message3.withTssBuffer((message3Buffer) => utils.getInfoFrom(
        session.ref,
        (handle, output) => _ctss.p2_signer_process_msg3(handle, message3Buffer, output),
        _ctss.tss_buffer_free,
        utils.toBase64StringUnsafe,
      ));

  String processMessage5(String message3) => message3.withTssBuffer((message3Buffer) => utils.getInfoFrom(
        session.ref,
        (handle, output) => _ctss.p2_signer_process_msg5(handle, message3Buffer, output),
        _ctss.tss_buffer_free,
        utils.toBase64StringUnsafe,
      ));
}
