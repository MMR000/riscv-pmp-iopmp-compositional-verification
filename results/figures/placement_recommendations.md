# Placement recommendations

Cite each figure in the text **before** the float appears. Use single-column `figure`, never `figure*`.

## Q1

- Section: Section 6 (implementation / PPA)
- Place after: After stating that J0--J3 were compared at a common 20 ns post-route target.
- First textual reference: `The common-target post-route standard-cell area of J0--J3 is shown in Fig.~\ref{fig:ppa-area}.`

## Q2

- Section: Section 6 or appendix
- Place after: Beside or after Q1 if mapped cells are discussed.
- First textual reference: `Mapped cell counts from the same 20\,ns netlists are shown in Fig.~\ref{fig:ppa-cells}.`

## Q3

- Section: Section 6 (implementation / PPA)
- Place after: Immediately after Q1, when incremental overhead is interpreted.
- First textual reference: `Incremental post-route area relative to each baseline is shown in Fig.~\ref{fig:ppa-overhead}.`

## Q4

- Section: Section 6 (timing)
- Place after: After distinguishing Fmax from the 20 ns area table.
- First textual reference: `Demonstrated post-route $F_{\mathrm{max}}$ for each variant is shown in Fig.~\ref{fig:fmax}.`

## Q5

- Section: Appendix / supplementary timing
- Place after: If the sweep and GRT failures are discussed.
- First textual reference: `Every tested full-flow clock period and its setup WNS is shown in Fig.~\ref{fig:fmax-sweep}.`

## Q6

- Section: Section 6 (timing anomaly)
- Place after: After stating that J1 is slower than J2/J3 and that the cause is not definitively established.
- First textual reference: `The near-limit setup-path categories are summarized in Fig.~\ref{fig:crit-path}.`

## Q7

- Section: Section 5 or 6 (performance)
- Place after: After describing authorized vs faulting CPU accesses.
- First textual reference: `Simulation-measured CPU access and fault latencies are shown in Fig.~\ref{fig:cpu-lat}.`

## Q8

- Section: Section 5 or 6 (performance)
- Place after: After defining DMA admission landmarks.
- First textual reference: `Distinct DMA transaction landmarks after admission are shown in Fig.~\ref{fig:dma-lat}.`

## Q9

- Section: Section 5 or 6 (performance)
- Place after: After stating single-outstanding sequential DMA measurement.
- First textual reference: `Measured sequential DMA cycles per transfer versus $N$ are shown in Fig.~\ref{fig:dma-thru}.`

## Q10

- Section: Appendix
- Place after: If the 500-seed constant campaign is mentioned.
- First textual reference: `The 500-seed authorized and denied DMA completions are summarized in Fig.~\ref{fig:dma-rand}.`

## Q11

- Section: Section 5 (reset)
- Place after: After defining PMP\_READY / IOPMP\_READY / secure\_ready landmarks.
- First textual reference: `RST-B directed reset-recovery latencies are shown in Fig.~\ref{fig:reset-lat}.`

## Q12

- Section: Section 5 (reset / release order)
- Place after: After defining RST-A vs RST-B early-access expectations.
- First textual reference: `Early unauthorized DMA outcomes across independent release orders are shown in Fig.~\ref{fig:release-order}.`

## Q13

- Section: Section 5 or appendix
- Place after: After Q12, if the 200-seed campaign is cited.
- First textual reference: `The 200-seed random release-order campaign is shown in Fig.~\ref{fig:release-rand}.`

## Q14

- Section: Section 4 or 7 (evidence discipline)
- Place after: When distinguishing formal, simulation, and inconclusive layers.
- First textual reference: `The recorded reset-related evidence layers are summarized in Fig.~\ref{fig:evidence}.`

