import 'dart:ffi' as ffi;
import 'dart:math';
import 'package:ffi/ffi.dart' as ffi_ext;
import 'package:test/test.dart';

import 'package:dart_2_party_ecdsa/src/ctss_bindings_generated.dart';
import 'package:dart_2_party_ecdsa/src/utils/utils.dart' as utils;
import 'package:dart_2_party_ecdsa/dart_2_party_ecdsa.dart';

void fillWithRandom(ffi.Pointer<tss_buffer> buffer) {
  if (buffer == ffi.nullptr) return;
  for (var i = 0; i < buffer.ref.len; ++i) {
    buffer.ref.ptr[i] = Random().nextInt(256);
  }
}

class TransportMock implements Transport {
  @override
  Future<void> delete(String collection, String docId) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<void> set(String collection, String docId, Map<String, dynamic> data) {
    // TODO: implement set
    throw UnimplementedError();
  }

  @override
  Stream<Map<String, dynamic>?> updates(String collection, String docId) {
    // TODO: implement updates
    throw UnimplementedError();
  }
}

void main() {
  var sdk = Dart2PartySDK(TransportMock());

  ffi.Pointer<Handle> keyshare1 = ffi_ext.calloc<Handle>(1);
  ffi.Pointer<Handle> keyshare2 = ffi_ext.calloc<Handle>(1);

  test('keygen', () {
    var sessionBuffer = utils.allocateTssBuffer();
    fillWithRandom(sessionBuffer);

    var p1Session = ffi_ext.malloc<Handle>(1);
    var p2Session = ffi_ext.malloc<Handle>(1);
    var msg_1 = ffi_ext.malloc<tss_buffer>(1);
    var msg_2 = ffi_ext.malloc<tss_buffer>(1);
    var msg_3 = ffi_ext.malloc<tss_buffer>(1);

    // initialization
    var p1KeyHandle = sdk.ctss.p1_partykeys_new();
    var result = sdk.ctss.p1_keygen_init(sessionBuffer, p1KeyHandle, p1Session);
    expect(result, equals(tss_error.TSS_OK));
    result = sdk.ctss.p2_keygen_init(sessionBuffer, p2Session);
    expect(result, equals(tss_error.TSS_OK));

    // round 1
    result = sdk.ctss.p1_keygen_gen_msg1(p1Session.ref, msg_1);
    expect(result, equals(tss_error.TSS_OK));
    result = sdk.ctss.p2_keygen_process_msg1(p2Session.ref, msg_1, msg_2);
    expect(result, equals(tss_error.TSS_OK));

    // round 2
    result = sdk.ctss.p1_keygen_process_msg2(p1Session.ref, msg_2, msg_3);
    expect(result, equals(tss_error.TSS_OK));
    result = sdk.ctss.p2_keygen_process_msg3(p2Session.ref, msg_3);
    expect(result, equals(tss_error.TSS_OK));

    // finalize
    result = sdk.ctss.p1_keygen_fini(p1Session.ref, keyshare1);
    expect(result, equals(tss_error.TSS_OK));
    result = sdk.ctss.p2_keygen_fini(p2Session.ref, keyshare2);
    expect(result, equals(tss_error.TSS_OK));

    final pubKey1 = utils.getInfoFrom(keyshare1.ref, sdk.ctss.p1_keyshare_public_key, sdk.ctss.tss_buffer_free, utils.toBase64StringUnsafe);
    final pubKey2 = utils.getInfoFrom(keyshare2.ref, sdk.ctss.p2_keyshare_public_key, sdk.ctss.tss_buffer_free, utils.toBase64StringUnsafe);
    expect(pubKey1, equals(pubKey2));
  });

  test('sign', () {
    ffi.Pointer<tss_buffer> signature_1 = ffi_ext.malloc<tss_buffer>(1);
    ffi.Pointer<tss_buffer> signature_2 = ffi_ext.malloc<tss_buffer>(1);

    var sessionBuffer = utils.allocateTssBuffer();
    fillWithRandom(sessionBuffer);

    var hashBuffer = utils.allocateTssBuffer();
    fillWithRandom(hashBuffer);

    // const anchor = "m";
    // var pathBuffer = ffi_ext.malloc<tss_buffer>(1);
    // pathBuffer.ref.ptr = anchor.toNativeUtf8().cast<ffi.Uint8>();
    // pathBuffer.ref.len = anchor.length;

    var p1Session = ffi_ext.malloc<Handle>(1);
    var p2Session = ffi_ext.malloc<Handle>(1);
    var msg_1 = ffi_ext.malloc<tss_buffer>(1);
    var msg_2 = ffi_ext.malloc<tss_buffer>(1);
    var msg_3 = ffi_ext.malloc<tss_buffer>(1);

    // initialization
    var result = sdk.ctss.p1_init_signer(sessionBuffer, keyshare1.ref, hashBuffer, p1Session);
    expect(result, equals(tss_error.TSS_OK));
    result = sdk.ctss.p2_init_signer(sessionBuffer, keyshare2.ref, hashBuffer, p2Session);
    expect(result, equals(tss_error.TSS_OK));

    // round 1
    result = sdk.ctss.p1_signer_gen_msg1(p1Session.ref, msg_1);
    expect(result, equals(tss_error.TSS_OK));
    result = sdk.ctss.p2_signer_process_msg1(p2Session.ref, msg_1, msg_2);
    expect(result, equals(tss_error.TSS_OK));

    // round 2
    result = sdk.ctss.p1_signer_process_msg2(p1Session.ref, msg_2, msg_3);
    expect(result, equals(tss_error.TSS_OK));
    result = sdk.ctss.p2_signer_process_msg3(p2Session.ref, msg_3, signature_2);
    expect(result, equals(tss_error.TSS_OK));

    // finalize
    result = sdk.ctss.p1_singer_fini(p1Session.ref, signature_1);
    expect(result, equals(tss_error.TSS_OK));

    final sig1 = utils.toHexString(signature_1);
    final sig2 = utils.toHexString(signature_2);
    expect(sig1, equals(sig2));
  });
}
