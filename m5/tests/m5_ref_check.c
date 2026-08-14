/* CLI: single REF-IOPMP access check for differential harness */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "ref_iopmp_adapter.h"

int main(int argc, char **argv)
{
    if (argc < 6) {
        fprintf(stderr, "usage: m5_ref_check <enable> <configured> <rrid> <addr> <read|write>\n");
        return 2;
    }
    bool enable = atoi(argv[1]) != 0;
    bool configured = atoi(argv[2]) != 0;
    uint16_t rrid = (uint16_t)atoi(argv[3]);
    uint64_t addr = strtoull(argv[4], NULL, 0);
    bool write = argv[5][0] == 'w';

    m5_ref_state_t *st = m5_ref_create(enable);
    if (configured) {
        m5_ref_install_policy(st, rrid, addr & ~0x3ULL, true, true);
    }
    m5_ref_result_e r = m5_ref_check(st, rrid, addr, write);
    puts(r == M5_REF_ALLOW ? "ALLOW" : "DENY");
    m5_ref_destroy(st);
    return 0;
}
