# Figure captions (IEEE)

## Q1

Post-route standard-cell area of the real-Ibex variants J0--J3 after a common-target sky130hd RTL-to-GDS flow at 20\,ns. Values are open-source physical-design results, not fabricated-silicon measurements.

## Q2

Mapped cell count of J0--J3 from the same 20\,ns common-target netlists used for Fig.~\ref{fig:ppa-area}. The J3 versus J2 difference is a mapping/optimization variation, not a claim that fail-closed reset reduces hardware.

## Q3

Incremental post-route standard-cell area relative to the indicated baseline, all at the common 20\,ns comparison point. Architectural PMP (J1 versus J0) accounts for most of the added implementation cost; composition adds a further increment; RST-B versus RST-A is near area-neutral after route.

## Q4

Demonstrated post-route $F_{\mathrm{max}}$ from the shortest clock period at which each variant completed GDS with DRC$=$0 and setup WNS$\,\ge\,$0. Markers at left note the separate 10\,ns high-frequency stress outcome and are not the main area comparison.

## Q5

Setup WNS versus requested clock period for every full post-route sweep point. Filled markers meet the pass criterion; open markers are timed failures; crosses mark global-route congestion failures with no post-route WNS. Segments connect tested numeric points only; untested periods are not interpolated.

## Q6

Category of the worst setup path at each variant's demonstrated near-limit pass (J0 at 9.5\,ns, J1 at 16.5\,ns, J2 at 12.75\,ns, J3 at 13.0\,ns). None of these limiting paths names PMP. The J1 timing anomaly remains classified as cause not definitively established.

## Q7

Simulation-measured CPU latency on the real-Ibex platform: authorized protected load/store (mcycle before/after) and U-mode protected load/store faults. Fault bars are annotated with the observed \texttt{mcause}.

## Q8

Simulation-measured DMA landmarks after admission on a single-outstanding research DMA: first protected commit, completion response, last commit strobe, and deny-to-response. These are distinct endpoints and are not a single DMA latency.

## Q9

Measured sequential DMA cycles per transfer for $N\in\{16,64,256\}$ on the single-outstanding research DMA, including harness/service gaps. The transfer-count axis is logarithmic so the three measured $N$ values are readable; the vertical axis starts at 0. This is simulation throughput, not measured silicon bandwidth.

## Q10

Random DMA campaign: 500 authorized completions at 7 cycles and 500 denied responses at 0 cycles. Every sample is identical within each class; no distributional spread is present.

## Q11

RST-B directed reset-recovery latency from raw samples: min--max range, median (dot), and mean (cross), with a rug of observed values. Metrics are CPU release to PMP\_READY, IOPMP release to IOPMP\_READY, reset epoch to \texttt{secure\_ready}, and \texttt{secure\_ready} to the first DMA request. RST-A is omitted because that table contains only a single CPU-release sample.

## Q12

Deterministic independent-release schedules ORD-A--H under RST-A and RST-B. A denotes early unauthorized DMA access reachable (RST-A, recorded as reset-assumption dependency); D denotes early access denied (RST-B, simulation evidence). All 16 cells are PASS relative to the model-specific expected behavior.

## Q13

Two-hundred-seed random release-order campaign (100 RST-A, 100 RST-B). Open circles: early unauthorized access reachable (expected under RST-A). Crosses: early access denied (RST-B). All seeds PASS; RST-A reachability is not scored as failure.

## Q14

Recorded evidence layers for reset-related claims, with the claim class stored in the frozen evidence table. Mixed cells keep both labels (simulation evidence with reset-assumption dependency, or with inconclusive in-flight cases). This is not a claim-by-claim coverage matrix.

