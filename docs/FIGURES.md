# Figures

Journal figures are generated from **frozen result CSVs**, not by re-running PPA or simulation.

```bash
python3 scripts/figures/generate_journal_figures.py
```

Outputs (created under `results/figures/`):

| Kind | Path |
|------|------|
| PDF | `results/figures/pdf/` |
| SVG | `results/figures/svg/` |
| Captions / QA | `results/figures/figure_captions.md`, `figure_qa_report.md`, `figure_manifest.csv` |
| LaTeX include snippet | `results/figures/latex_single_column_figures.tex` |

The public snapshot prefers vector PDF/SVG. Optional 600 dpi PNG duplicates are omitted when vectors exist.

Core paper set used in the manuscript workflow includes Q1, Q3, Q4, Q7, Q8, Q9, Q11, Q12 (see `figure_manifest.csv` and `figure_recommendations.md`).

Do not treat figure images as independent measurements. If a plot disagrees with `results/tables/`, the CSV is authoritative.
