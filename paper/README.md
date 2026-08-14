# Paper build (M6)

## Quick start

From repository root:

```bash
make paper
```

Output: `paper/build/main.pdf`

## Manual build

```bash
python3 scripts/analysis/generate_paper_artifacts.py
cd paper
export TEXINPUTS=./vendor//:$TEXINPUTS
pdflatex -interaction=nonstopmode -output-directory=build main.tex
bibtex build/main
pdflatex -interaction=nonstopmode -output-directory=build main.tex
pdflatex -interaction=nonstopmode -output-directory=build main.tex
```

## Clean

```bash
make paper-clean
```

If `latexmk` is installed, you may use `latexmk -pdf -output-directory=build main.tex` instead.

## Requirements

- `pdflatex` (TeX Live recommended)
- IEEE `IEEEtran` class from TeX Live or IEEE (this public artifact does **not** redistribute `IEEEtran.cls`)
- Standard packages: tikz, booktabs, hyperref, cleveref, siunitx, etc. (`texlive-latex-extra`)

Set `TEXINPUTS` so `pdflatex` finds a locally installed `IEEEtran.cls`. The historical vendor copy used internally is omitted from the public snapshot.

If LaTeX is not installed:

```bash
# Debian/Ubuntu (requires appropriate permissions)
sudo apt install texlive-latex-extra texlive-fonts-recommended
# optional: latexmk
sudo apt install latexmk
```

## Note

M6 generates a **skeleton** with verified facts and TODO markers — not final prose.
Evidence sources: `results/tables/m510_*.csv`, `results/m510/m510_summary.md`.
