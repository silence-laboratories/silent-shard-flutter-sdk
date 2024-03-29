/*
 * Generated by cbindgen Do not edit directly.
 */

#ifndef _TSS_H
#define _TSS_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

typedef enum tss_error {
  TSS_OK,
  TSS_NO_ERROR,
  TSS_INVALID_HANDLE,
  TSS_HANDLE_IN_USE,
  TSS_INVALID_HANDLE_TYPE,
  TSS_NULL_PTR,
  TSS_INVALID_SESSION_ID,
  TSS_INVALID_SESSION_STATE,
  TSS_UNKNOWN_ERROR,
  TSS_SERIALIZATION_ERROR,
  TSS_PROCESS_MESSAGE_ERROR,
  TSS_INVALID_MSG_HASH,
  TSS_INVALID_DERIVATION_PATH_STR,
  TSS_MESSAGE_SIGNATURE,
  TSS_MESSAGE_SIGN_PK,
  TSS_MESSAGE_SIGN_VERIFY,
} tss_error;

typedef struct tss_buffer {
  const uint8_t *ptr;
  uintptr_t len;
} tss_buffer;

typedef struct Handle {
  int32_t _0;
} Handle;

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

void tss_buffer_free(struct tss_buffer *buf);

enum tss_error p1_keygen_init(const struct tss_buffer *session_id,
                              struct Handle keys,
                              struct Handle *output);

enum tss_error p1_ephmeral(const struct tss_buffer *session_id,
                           struct Handle party_keys,
                           struct Handle keyshare,
                           struct Handle *output);

enum tss_error p2_ephmeral(const struct tss_buffer *session_id,
                           struct Handle keyshare,
                           struct Handle *output);

enum tss_error p2_keygen_init(const struct tss_buffer *session_id, struct Handle *output);

enum tss_error p1_keygen_gen_msg1(struct Handle session, struct tss_buffer *output);

enum tss_error p2_keygen_process_msg1(struct Handle session,
                                      const struct tss_buffer *msg1,
                                      struct tss_buffer *msg2_output);

enum tss_error p1_keygen_process_msg2(struct Handle session,
                                      const struct tss_buffer *msg2,
                                      struct tss_buffer *msg3_output);

enum tss_error p2_keygen_process_msg3(struct Handle p2_handle, const struct tss_buffer *msg3);

enum tss_error p1_keygen_fini(struct Handle p1, struct Handle *output);

enum tss_error p2_keygen_fini(struct Handle p2, struct Handle *output);

enum tss_error p1_keygen_error_msg(struct Handle p1, struct tss_buffer *msg);

enum tss_error p2_keygen_error_msg(struct Handle p2, struct tss_buffer *msg);

enum tss_error p1_keyshare_from_bytes(const struct tss_buffer *buf, struct Handle *hnd);

enum tss_error p1_keyshare_to_bytes(struct Handle share, struct tss_buffer *buf);

enum tss_error p1_keyshare_public_key(struct Handle share, struct tss_buffer *buf);

enum tss_error p1_keyshare_free(struct Handle hnd);

enum tss_error p2_keyshare_from_bytes(const struct tss_buffer *buf, struct Handle *hnd);

enum tss_error p2_keyhare_to_bytes(struct Handle share, struct tss_buffer *buf);

enum tss_error p2_keyshare_public_key(struct Handle share, struct tss_buffer *buf);

enum tss_error p2_keyshare_free(struct Handle hnd);

struct Handle p1_partykeys_new(void);

enum tss_error p1_partykeys_from_bytes(const struct tss_buffer *bytes, struct Handle *hnd);

enum tss_error p1_partykeys_to_bytes(struct Handle keys, struct tss_buffer *buf);

enum tss_error p1_partykeys_message_pk(struct Handle keys, struct tss_buffer *pk);

enum tss_error p1_partykeys_message_sign(struct Handle keys,
                                         const struct tss_buffer *message,
                                         struct tss_buffer *signature);

enum tss_error p1_verify_message(const struct tss_buffer *pk,
                                 const struct tss_buffer *msg,
                                 const struct tss_buffer *sign);

enum tss_error p1_init_signer(const struct tss_buffer *session_id,
                              struct Handle keyshare,
                              const struct tss_buffer *message_hash,
                              struct Handle *p1_out);

enum tss_error p2_init_signer(const struct tss_buffer *session_id,
                              struct Handle keyshare,
                              const struct tss_buffer *message_hash,
                              struct Handle *p2_out);

enum tss_error p1_signer_gen_msg1(struct Handle handle, struct tss_buffer *msg1_out);

enum tss_error p2_signer_process_msg1(struct Handle handle,
                                      const struct tss_buffer *msg1,
                                      struct tss_buffer *msg2_out);

enum tss_error p1_signer_process_msg2(struct Handle handle,
                                      const struct tss_buffer *msg2,
                                      struct tss_buffer *msg3_out);

enum tss_error p2_signer_process_msg3(struct Handle handle,
                                      const struct tss_buffer *msg3,
                                      struct tss_buffer *msg4_out);

enum tss_error p1_signer_process_msg4(struct Handle handle,
                                      const struct tss_buffer *msg4,
                                      struct tss_buffer *msg5_out);

enum tss_error p1_singer_fini(struct Handle p1, struct tss_buffer *output);

enum tss_error p2_signer_process_msg5(struct Handle handle,
                                      const struct tss_buffer *msg5,
                                      struct tss_buffer *sign_out);

enum tss_error p1_signer_error_msg(struct Handle p1, struct tss_buffer *msg);

enum tss_error p2_signer_error_msg(struct Handle p2, struct tss_buffer *msg);

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus

#endif /* _TSS_H */
