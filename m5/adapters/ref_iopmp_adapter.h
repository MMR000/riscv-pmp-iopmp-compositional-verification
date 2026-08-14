#ifndef M5_REF_IOPMP_ADAPTER_H
#define M5_REF_IOPMP_ADAPTER_H

#include <stdbool.h>
#include <stdint.h>

/* Adapter over REF-IOPMP (official v0.8.2 reference model). */

typedef struct m5_ref_state m5_ref_state_t;

typedef enum {
    M5_REF_ALLOW = 0,
    M5_REF_DENY  = 1,
} m5_ref_result_e;

m5_ref_state_t *m5_ref_create(bool enable_at_reset);
void m5_ref_destroy(m5_ref_state_t *st);

bool m5_ref_hw_enable(m5_ref_state_t *st);
void m5_ref_set_hw_enable(m5_ref_state_t *st, bool enable);

/* Install minimal NA4 region policy for one RRID (full_model / fmt0). */
void m5_ref_install_policy(m5_ref_state_t *st, uint16_t rrid, uint64_t addr,
                           bool allow_read, bool allow_write);

/* Check one 4-byte transaction against current REF-IOPMP state. */
m5_ref_result_e m5_ref_check(m5_ref_state_t *st, uint16_t rrid, uint64_t addr,
                               bool is_write);

#endif
