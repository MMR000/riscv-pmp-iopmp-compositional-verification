#include "ref_iopmp_adapter.h"

#include <stdlib.h>
#include <string.h>

#include "config.h"
#include "iopmp.h"
#include "iopmp_ref_api.h"
#include "test_utils.h"

struct m5_ref_state {
    iopmp_dev_t dev;
    iopmp_cfg_t cfg;
};

static void m5_ref_default_cfg(iopmp_cfg_t *cfg, bool enable_at_reset)
{
    memset(cfg, 0, sizeof(*cfg));
    cfg->vendor = 1;
    cfg->specver = 1;
    cfg->enable = enable_at_reset;
    cfg->md_num = 63;
    cfg->addrh_en = true;
    cfg->tor_en = true;
    cfg->rrid_num = 64;
    cfg->entry_num = 512;
    cfg->prio_entry = 16;
    cfg->non_prio_en = true;
    cfg->chk_x = true;
    cfg->peis = true;
    cfg->pees = true;
    cfg->sps_en = true;
    cfg->stall_en = true;
    cfg->mfr_en = true;
    cfg->mdcfg_fmt = 0;
    cfg->srcmd_fmt = 0;
    cfg->md_entry_num = 0;
    cfg->rrid_transl_en = true;
    cfg->rrid_transl = 48;
    cfg->entryoffset = 0x2000;
    cfg->granularity = MIN_GRANULARITY;
    cfg->imp_mdlck = true;
    cfg->imp_error_capture = true;
    cfg->imp_err_reqid_eid = true;
    cfg->imp_rridscp = true;
    cfg->imp_msi = true;
    cfg->imp_stall_buffer = true;
}

m5_ref_state_t *m5_ref_create(bool enable_at_reset)
{
    m5_ref_state_t *st = calloc(1, sizeof(*st));
    if (!st) return NULL;
    m5_ref_default_cfg(&st->cfg, enable_at_reset);
    reset_iopmp(&st->dev, &st->cfg);
    return st;
}

void m5_ref_destroy(m5_ref_state_t *st)
{
    free(st);
}

bool m5_ref_hw_enable(m5_ref_state_t *st)
{
    hwcfg0_t hwcfg0;
    hwcfg0.raw = read_register(&st->dev, HWCFG0_OFFSET, 4);
    return hwcfg0.enable;
}

void m5_ref_set_hw_enable(m5_ref_state_t *st, bool enable)
{
    if (enable) {
        set_hwcfg0_enable(&st->dev);
    }
}

void m5_ref_install_policy(m5_ref_state_t *st, uint16_t rrid, uint64_t addr,
                           bool allow_read, bool allow_write)
{
    uint32_t entry_cfg = NA4;
    if (allow_read) entry_cfg |= R;
    if (allow_write) entry_cfg |= W;

    configure_srcmd_n(&st->dev, SRCMD_EN, rrid, 0x10, 4);
    if (allow_read) configure_srcmd_n(&st->dev, SRCMD_R, rrid, 0x10, 4);
    if (allow_write) configure_srcmd_n(&st->dev, SRCMD_W, rrid, 0x10, 4);
    configure_mdcfg_n(&st->dev, 3, 2, 4);
    configure_entry_n(&st->dev, ENTRY_ADDR, 1, addr >> 2, 4);
    configure_entry_n(&st->dev, ENTRY_CFG, 1, entry_cfg, 4);
    set_hwcfg0_enable(&st->dev);
}

m5_ref_result_e m5_ref_check(m5_ref_state_t *st, uint16_t rrid, uint64_t addr,
                             bool is_write)
{
    iopmp_trans_req_t req;
    iopmp_trans_rsp_t rsp;
    uint8_t intrpt = 0;

    receiver_port(rrid, addr, 0, 2, is_write ? WRITE_ACCESS : READ_ACCESS, 0, &req);
    iopmp_validate_access(&st->dev, &req, &rsp, &intrpt);
    return (rsp.status == IOPMP_SUCCESS) ? M5_REF_ALLOW : M5_REF_DENY;
}
