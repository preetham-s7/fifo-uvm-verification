# Local validation

Validation date: 17 October 2026. Tool: QuestaSim 10.7c, UVM 1.2, Windows x64.

## Reproduce

```powershell
./scripts/run-questa.ps1 -QuestaHome C:/questasim64_10.7c
```

| Seed | Non-idle transactions checked | Failed comparisons | UVM errors | UVM fatals |
| --- | ---: | ---: | ---: | ---: |
| 1 | 78 | 0 | 0 | 0 |
| 7 | 82 | 0 | 0 | 0 |
| 42 | 76 | 0 | 0 | 0 |

Each run generates 100 randomized sequence items; idle items are not sent by the monitor to the scoreboard. The final environment compiled with zero compiler errors or warnings. These are observed functional simulation results, not measured code or functional coverage percentages.

The repository also includes an open-source RTL smoke test at `tests/rtl_smoke_tb.sv`, run automatically by GitHub Actions. It checks a non-power-of-two depth, FIFO ordering, and the overflow/underflow boundary behavior without requiring a proprietary simulator.

## Changes in this fork

- Initialize FIFO inputs during reset.
- Sample the DUT one time unit after a rising clock edge, after nonblocking updates.
- Allow final monitoring before dropping the run objection and deassert controls.
- Make an empty or failing scoreboard issue a UVM error.
- Add a repeatable three-seed runner with completion and error checks.
- Register overflow/underflow from the pre-operation FIFO state.
- Use explicit pointer wrapping so non-power-of-two RTL depths are supported.
- Add an Icarus Verilog smoke test and GitHub Actions workflow.

## Limits

The final UVM environment uses an 8-bit, depth-4 configuration, and the scoreboard remains configured for that setup. The RTL pointer logic now supports non-power-of-two depths, but other widths/depths, reset during active traffic, formal verification, synthesis, and coverage closure have not been validated here. Random stimulus is not a proof that every corner case has been exercised. Earlier tutorial stages are preserved from upstream and were not rerun for this fork.

Upstream: [gitfahadahmad/sync-fifo-verification](https://github.com/gitfahadahmad/sync-fifo-verification), commit `f87ebe8a20d86ce8e06dfb5b989b62d05f0f7666`. Original author: Fahad Ahmad. Original MIT license retained.
