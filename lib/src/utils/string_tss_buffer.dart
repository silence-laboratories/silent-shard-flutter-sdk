// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:convert';
import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi_ext;

import '../ctss_bindings_generated.dart';
import 'utils.dart' as utils;

typedef Handler<T> = T Function(ffi.Pointer<tss_buffer>);

extension StringTssBuffer on String {
  ///
  /// Expects base64-encoded string
  ///
  ffi.Pointer<tss_buffer> toTssBuffer([Codec? codec = base64]) {
    var bytes = codec != null ? codec.decode(this) : codeUnits;
    final buffer = ffi_ext.malloc<ffi.Uint8>(bytes.length);
    buffer.asTypedList(bytes.length).setAll(0, bytes);

    final result = ffi_ext.malloc<tss_buffer>(1);
    result.ref.ptr = buffer;
    result.ref.len = bytes.length;

    return result;
  }

  ///
  /// Wraps access to string content as a temporary tss_buffer
  ///
  T withTssBuffer<T>(Handler<T> handler, [Codec? codec = base64]) {
    T result;
    var buffer = toTssBuffer(codec);
    try {
      result = handler(buffer);
    } finally {
      utils.freeTssBuffer(buffer);
    }
    return result;
  }
}
