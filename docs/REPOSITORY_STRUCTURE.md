# Repository structure

Layout is the working research layout. Paths were **not** renamed for cosmetics so Makefile and script references stay valid.

```text
.
├── README.md
├── PROVENANCE.md
├── CITATION.cff
├── SECURITY.md
├── LICENSES.md
├── THIRD_PARTY_NOTICES.md
├── Makefile
├── rtl/                         # research PMP/IOPMP/fabric RTL (M1–M4 lineage)
├── tb/                          # simulation testbenches
├── formal/                      # harnesses, properties, .sby tasks
│   ├── harness/
│   ├── properties/
│   ├── sby/
│   └── tasks/
├── m7/                          # real-Ibex composition, reset, PPA wrappers, software
│   ├── rtl/
│   ├── sw/
│   ├── ppa/
│   ├── sim/
│   └── fusesoc/
├── m5/ m55/ m56/                # external IOPMP adapters / FIX-2 research files
├── patches/                     # research patches against fetched third-party RTL
├── scripts/
│   ├── run/
│   ├── analysis/
│   ├── figures/
│   ├── ppa/
│   ├── setup/
│   └── artifact/
├── docs/                        # methodology, assumptions, evidence notes
├── paper/                       # LaTeX manuscript sources (no IEEEtran.cls)
├── results/
│   ├── tables/                  # frozen CSV matrices
│   ├── figures/                 # generated PDF/SVG (+ data)
│   └── m7/                      # compact logs, PPA metrics, Phase A–D records
└── third_party/
    ├── README.md
    └── pins/                    # exact commits / Docker digest
```

`third_party/ibex` and `third_party/OpenROAD-flow-scripts` appear only after `bash scripts/setup/fetch_dependencies.sh`.
