#!/usr/bin/env python3
"""Line-level compare: staged formal arbiter vs production .sv."""
from __future__ import annotations
import hashlib
from pathlib import Path

ROOT = Path("/home/mmr/ricv_paper")
PROD = ROOT / "m7/rtl/m7_research_arbiter.sv"
FORM = ROOT / "IEEE_Access_End_to_End_Authorization_Proof_Closure/formal/configurations/stage_v2/m7_research_arbiter.v"
OUT = ROOT / "results/m7/evidence_cleanup/arbiter_diff"


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def lines(p: Path) -> list[str]:
    return p.read_text().replace("\r\n", "\n").splitlines()


def classify(prod_line: str | None, form_line: str | None) -> str:
    a = (prod_line or "").strip()
    b = (form_line or "").strip()
    blob = a + " " + b
    if "ifdef FORMAL" in blob or "endif" in blob and "FORMAL" in blob:
        return "FORMAL_OBSERVATION_ONLY"
    if a.startswith("output wire") and a.startswith("output wire                     f_"):
        return "FORMAL_OBSERVATION_ONLY"
    if "f_state" in blob or "f_serve_cpu" in blob or "f_target_issued" in blob or "f_a_" in blob:
        return "FORMAL_OBSERVATION_ONLY"
    if "FORMAL-ONLY" in blob or "Non-FORMAL elaboration" in blob:
        return "FORMAL_OBSERVATION_ONLY"
    if blob.strip() in {",", ");"} and (prod_line is None or form_line is None or a != b):
        return "FORMAL_OBSERVATION_ONLY"
    if a == b:
        return "IDENTICAL"
    # filename / comment-only header
    if a.startswith("//") and b.startswith("//"):
        return "COMMENT_ONLY"
    if (a.startswith("`include") and b.startswith("`include")) or a.startswith("`") or b.startswith("`"):
        if a == b:
            return "IDENTICAL"
        return "SYNTAX_BUILD_ADAPTATION"
    return "SYNTHESIZED_FUNCTIONAL_DIFFERENCE"


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    pl, fl = lines(PROD), lines(FORM)
    report = []
    report.append(f"production {PROD} sha256={sha(PROD)}")
    report.append(f"formal     {FORM} sha256={sha(FORM)}")
    report.append(f"production_lines={len(pl)} formal_lines={len(fl)}")
    report.append("")

    # Strip FORMAL-only regions from formal file for functional compare
    def strip_formal(ls: list[str]) -> list[str]:
        out = []
        skip = False
        for ln in ls:
            s = ln.strip()
            if s.startswith("`ifdef FORMAL"):
                skip = True
                continue
            if skip and s.startswith("`endif"):
                skip = False
                continue
            if skip:
                continue
            if s.startswith("// FORMAL-ONLY"):
                continue
            out.append(ln)
        return out

    fl_nf = strip_formal(fl)
    # Normalize trailing port ); after removing FORMAL ports: formal may have
    # `ifdef FORMAL , ports `endif );
    # After strip, last port line may still have no comma difference vs prod.

    def norm_body(ls: list[str]) -> list[str]:
        body = []
        started = False
        for ln in ls:
            if "module m7_research_arbiter" in ln:
                started = True
            if started:
                # drop purely blank
                if ln.strip() == "":
                    continue
                body.append(ln.rstrip())
        return body

    pb, fb = norm_body(pl), norm_body(fl_nf)
    # LCS-free pairwise: walk with simple alignment
    i = j = 0
    functional = []
    formal_only = []
    comment = []
    while i < len(pl) or j < len(fl):
        a = pl[i] if i < len(pl) else None
        b = fl[j] if j < len(fl) else None
        if a == b:
            i += 1
            j += 1
            continue
        # skip formal-only block in formal
        if b is not None and ("`ifdef FORMAL" in b or b.strip().startswith("output wire") and "f_" in b
                              or "assign f_" in (b or "") or "FORMAL-ONLY" in (b or "")):
            cls = "FORMAL_OBSERVATION_ONLY"
            formal_only.append((j + 1, b))
            report.append(f"F{j+1}: {cls}: {b}")
            j += 1
            continue
        if b is not None and b.strip() in ("`endif", ","):
            # likely FORMAL port list punctuation
            if a is None or a.strip() != b.strip():
                formal_only.append((j + 1, b))
                report.append(f"F{j+1}/P{i+1 if a else '-'}: FORMAL_OR_PUNCT: F={b!r} P={a!r}")
                j += 1
                continue
        cls = classify(a, b)
        rec = f"P{i+1 if a is not None else '-'} F{j+1 if b is not None else '-'}: {cls}: P={a!r} F={b!r}"
        report.append(rec)
        if cls == "SYNTHESIZED_FUNCTIONAL_DIFFERENCE":
            functional.append(rec)
        elif cls == "COMMENT_ONLY":
            comment.append(rec)
        if a is not None:
            i += 1
        if b is not None:
            j += 1

    # Functional body equality after FORMAL strip
    def canon(ls: list[str]) -> list[str]:
        out = []
        for ln in ls:
            s = ln.strip()
            if not s or s.startswith("//"):
                continue
            out.append(s)
        return out

    pc, fc = canon(pb), canon(fb)
    # Remove leftover `endif
    fc = [x for x in fc if x not in ("`endif",)]
    body_equal = pc == fc
    report.append("")
    report.append(f"functional_body_equal_after_FORMAL_strip={body_equal}")
    if not body_equal:
        report.append("CANON_PROD_ONLY / CANON_FORM_ONLY mismatches:")
        for n, (x, y) in enumerate(zip(pc, fc)):
            if x != y:
                report.append(f"  idx={n} P={x!r} F={y!r}")
        if len(pc) != len(fc):
            report.append(f"  length prod={len(pc)} form={len(fc)}")
            for x in pc[len(fc):]:
                report.append(f"  extra_prod {x!r}")
            for x in fc[len(pc):]:
                report.append(f"  extra_form {x!r}")

    report.append("")
    report.append(f"formal_observation_lines={len(formal_only)}")
    report.append(f"comment_only_diffs={len(comment)}")
    report.append(f"synthesized_functional_diff_count={len(functional)}")
    if functional:
        report.append("FLAG: SYNTHESIZED_FUNCTIONAL_DIFFERENCE present")
    else:
        report.append("NO synthesized functional difference after classifying FORMAL ports/assigns.")

    (OUT / "FORMAL_VS_PRODUCTION_ARBITER.md").write_text("\n".join(report) + "\n")
    print("\n".join(report[-20:]))


if __name__ == "__main__":
    main()
