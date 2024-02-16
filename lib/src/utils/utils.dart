// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi_ext;
import 'package:convert/convert.dart';

import '../ctss_bindings_generated.dart';

typedef InfoProvider = int Function(Handle, ffi.Pointer<tss_buffer>);
typedef FreeFunction = void Function(ffi.Pointer<tss_buffer>);
typedef Converter<T> = T Function(ffi.Pointer<tss_buffer>);

ffi.Pointer<tss_buffer> allocateTssBuffer([int size = 32]) {
  final buffer = ffi_ext.calloc<tss_buffer>(1);
  buffer.ref.ptr = ffi_ext.calloc<ffi.Uint8>(size);
  buffer.ref.len = size;
  return buffer;
}

void freeTssBuffer(ffi.Pointer<tss_buffer> buffer) {
  ffi_ext.calloc.free(buffer.ref.ptr);
  ffi_ext.calloc.free(buffer);
}

Uint8List? toBytes(ffi.Pointer<tss_buffer> buffer) {
  if (buffer == ffi.nullptr) return null;
  return toBytes(buffer);
}

Uint8List toBytesUnsafe(ffi.Pointer<tss_buffer> buffer) => Uint8List.fromList(buffer.ref.ptr.asTypedList(buffer.ref.len));

String? toHexString(ffi.Pointer<tss_buffer> buffer) {
  if (buffer == ffi.nullptr) return null;
  return toHexStringUnsafe(buffer);
}

String toHexStringUnsafe(ffi.Pointer<tss_buffer> buffer) => hex.encode(buffer.ref.ptr.asTypedList(buffer.ref.len));

String? toBase64String(ffi.Pointer<tss_buffer> buffer, {int offset = 0, int? length}) {
  if (buffer == ffi.nullptr) return null;
  if (buffer.ref.len < offset + (length ?? 0)) return null;
  return toBase64StringUnsafe(buffer, offset: offset, length: length);
}

String toBase64StringUnsafe(ffi.Pointer<tss_buffer> buffer, {int offset = 0, int? length}) {
  if (buffer.ref.len <= offset + (length ?? 0)) return "";
  return base64Encode(buffer.ref.ptr.elementAt(offset).asTypedList(length ?? buffer.ref.len - offset));
}

String? fromAsciBytes(ffi.Pointer<tss_buffer> buffer) {
  if (buffer == ffi.nullptr) return null;
  return fromAsciiBytesUnsafe(buffer);
}

String fromAsciiBytesUnsafe(ffi.Pointer<tss_buffer> buffer) {
  if (buffer.ref.len < 1) return "";
  var base64String = String.fromCharCodes(buffer.ref.ptr.asTypedList(buffer.ref.len));
  return base64String;
}

T getInfoFrom<T>(Handle handle, InfoProvider provider, FreeFunction freeFunction, Converter<T> converter) {
  var buffer = ffi_ext.calloc<tss_buffer>(1);
  var errorCode = provider(handle, buffer);

  if (errorCode != tss_error.TSS_OK) {
    ffi_ext.calloc.free(buffer);
    throw errorCode;
  }

  var result = converter(buffer);

  freeFunction(buffer);
  ffi_ext.calloc.free(buffer);

  return result;
}
