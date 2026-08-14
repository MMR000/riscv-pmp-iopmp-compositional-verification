/* M5 REF-IOPMP experiment campaign — outputs CSV results. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ref_iopmp_adapter.h"

#define M5_PROTECT_ADDR 0x20000000ULL
#define M5_AUTH_RRID    1
#define M5_UNAUTH_RRID  2

static const char *res_str(m5_ref_result_e r) { return r == M5_REF_ALLOW ? "ALLOW" : "DENY"; }

static void emit_row(FILE *f, const char *exp, const char *cfg, uint16_t rrid,
                     uint64_t addr, const char *op, int enable, int configured,
                     m5_ref_result_e result)
{
    fprintf(f, "%s,%s,%u,0x%llx,%s,%d,%d,%s\n",
            exp, cfg, rrid, (unsigned long long)addr, op, enable, configured, res_str(result));
}

static void run_baseline(FILE *ref, FILE *range)
{
    /* REF-M1 / reset-default central experiment */
    m5_ref_state_t *c0 = m5_ref_create(false);
    m5_ref_state_t *c1 = m5_ref_create(true);

    emit_row(ref, "REF-M1-C", "REF-C0", M5_AUTH_RRID, M5_PROTECT_ADDR, "write", 0, 0,
             m5_ref_check(c0, M5_AUTH_RRID, M5_PROTECT_ADDR, true));
    emit_row(ref, "REF-M1-D", "REF-C1", M5_AUTH_RRID, M5_PROTECT_ADDR, "write", 1, 0,
             m5_ref_check(c1, M5_AUTH_RRID, M5_PROTECT_ADDR, true));

    m5_ref_install_policy(c1, M5_AUTH_RRID, M5_PROTECT_ADDR, true, true);
    emit_row(ref, "REF-M1-A", "REF-C1", M5_AUTH_RRID, M5_PROTECT_ADDR, "write", 1, 1,
             m5_ref_check(c1, M5_AUTH_RRID, M5_PROTECT_ADDR, true));
    emit_row(ref, "REF-M1-B", "REF-C1", M5_UNAUTH_RRID, M5_PROTECT_ADDR, "write", 1, 1,
             m5_ref_check(c1, M5_UNAUTH_RRID, M5_PROTECT_ADDR, true));

    m5_ref_destroy(c0);
    m5_ref_destroy(c1);

    /* Range / partial-hit spot checks (full_model) */
    m5_ref_state_t *st = m5_ref_create(true);
    m5_ref_install_policy(st, M5_AUTH_RRID, M5_PROTECT_ADDR, true, true);
    emit_row(range, "range-exact", "REF-C1", M5_AUTH_RRID, M5_PROTECT_ADDR, "write", 1, 1,
             m5_ref_check(st, M5_AUTH_RRID, M5_PROTECT_ADDR, true));
    emit_row(range, "range-wrong-rrid", "REF-C1", M5_UNAUTH_RRID, M5_PROTECT_ADDR, "write", 1, 1,
             m5_ref_check(st, M5_UNAUTH_RRID, M5_PROTECT_ADDR, true));
    emit_row(range, "range-read-deny", "REF-C1", M5_AUTH_RRID, M5_PROTECT_ADDR, "read", 1, 1,
             m5_ref_check(st, M5_AUTH_RRID, M5_PROTECT_ADDR, false));
    m5_ref_destroy(st);

    st = m5_ref_create(true);
    emit_row(range, "range-no-entry", "REF-C1", M5_AUTH_RRID, M5_PROTECT_ADDR, "write", 1, 0,
             m5_ref_check(st, M5_AUTH_RRID, M5_PROTECT_ADDR, true));
    m5_ref_destroy(st);
}

int main(void)
{
    const char *ref_path = getenv("M5_REF_RESULTS");
    const char *range_path = getenv("M5_RANGE_RESULTS");
    if (!ref_path) ref_path = "results/m5/reference_model/reference_results.csv";
    if (!range_path) range_path = "results/m5/reference_model/range_results.csv";

    FILE *ref = fopen(ref_path, "w");
    FILE *range = fopen(range_path, "w");
    if (!ref || !range) {
        fprintf(stderr, "Cannot open M5 result files\n");
        return 1;
    }
    fprintf(ref, "experiment,configuration,rrid,address,operation,enable,configured,result\n");
    fprintf(range, "experiment,configuration,rrid,address,operation,enable,configured,result\n");
    run_baseline(ref, range);
    fclose(ref);
    fclose(range);
    return 0;
}
