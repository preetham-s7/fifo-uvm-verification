

```powershell
./scripts/run-questa.ps1 -QuestaHome C:/questasim64_10.7c
```

The runner checks completion, a nonempty scoreboard, zero UVM errors/fatals, and simulator errors. Logs are local under `.sim/`. See [VALIDATION.md](VALIDATION.md) for locally observed results and limitations. The upstream project's results below are attributed historical results, not new coverage measurements by this fork.

---

# Upstream: Synchronous FIFO — RTL Design & Progressive Verification

A synchronous FIFO designed in SystemVerilog and verified three times over with increasingly rigorous methodologies — from a hand-written directed testbench, to a mailbox-based layered testbench with a scoreboard and reference model, to a complete UVM environment with constrained-random stimulus. All stages pass with zero scoreboard mismatches.

Verification performed using Cadence Xcelium (`xrun`).

## Why three testbenches for one FIFO?

Each stage builds on the last, intentionally, as a way to learn each methodology on a small, well-understood DUT before applying it to larger designs:

| Stage | Methodology | Stimulus | Checking |
|---|---|---|---|
| [`01_rtl_and_directed_tb`](01_rtl_and_directed_tb) | Directed testbench | Hand-written sequences (reset, write, read, overflow, underflow, simultaneous R/W) | Visual inspection via `$monitor` |
| [`02_layered_tb`](02_layered_tb) | Layered testbench (generator/driver/monitor/scoreboard, mailboxes) | Constrained-random transactions | Self-checking scoreboard with a queue-based reference model |
| [`03_uvm_tb`](03_uvm_tb) | UVM (4-part incremental build) | Constrained-random sequences via a UVM sequencer | Self-checking `uvm_component` scoreboard with an analysis port |

## DUT: Synchronous FIFO

A parameterized synchronous FIFO (`sync_fifo`) with:
- Configurable `depth` and `data_width`
- Full/empty flags, and overflow/underflow error flags
- A `count` output tracking current occupancy
- Support for simultaneous read and write in the same cycle

Two structurally-equivalent versions of the DUT appear across the stages: an early version with flat ports (stage 1 and 2), and a later version wrapped in a SystemVerilog `interface` with driver/monitor clocking blocks (stage 2's `fifo_if.sv`, and all of stage 3). This mirrors the real progression of the project as the verification environment matured.

## Stage 1 — Directed Testbench

`01_rtl_and_directed_tb/fifo_tb.sv` manually drives the DUT through a fixed sequence: reset, a single write, a single read, filling the FIFO to trigger `full`/`overflow`, draining it to trigger `empty`/`underflow`, and a simultaneous read/write. Pass/fail is judged by reading the `$monitor` output.

## Stage 2 — Layered Testbench

A classic mailbox-connected verification environment in `02_layered_tb`:

- **`fifo_transaction.sv`** — randomizable transaction class (`wr_en`, `rd_en`, `data_in`), with constraints ensuring `wr_en != rd_en` and `data_in` biased to even values in `[0:100]`
- **`generator.sv`** — generates a configurable number of random transactions onto a mailbox
- **`driver.sv`** — drives transactions onto the `fifo_if` virtual interface
- **`monitor.sv`** — samples the interface every cycle and forwards observed transactions to the scoreboard
- **`scoreboard.sv`** — maintains a queue-based reference model, predicts `full`/`empty`/`overflow`/`underflow`/`count`/`data_out`, and checks every field against the DUT
- **`environment.sv`** — wires the above together and runs all phases concurrently (`fork...join_none`)

**Result:** 51/51 checks passed, 0 failures (50 generated transactions).

## Stage 3 — UVM Testbench

A 4-step incremental build of a full UVM environment under `03_uvm_tb`, each folder a complete, runnable testbench in its own right:

1. **`task1_basic_env`** — minimal `uvm_test` + `top` skeleton to bring up the UVM phasing
2. **`task2_sequence_item`** — introduces `uvm_sequence_item` and a `uvm_sequence` generating randomized items
3. **`task3_agent_driver_monitor`** — full `uvm_agent` with driver, monitor, sequencer, and `uvm_config_db`-based virtual interface handoff (no scoreboard yet)
4. **`task4_complete_env`** — the complete environment: agent + self-checking scoreboard (`uvm_analysis_imp`) wired through `tx_env`, running a 100-item constrained-random sequence

**Result (`task4_complete_env`):** 68/68 checks passed, 0 failures, 0 UVM errors/fatals across 338 logged `UVM_INFO` messages.

## Running the Simulations

All stages were run with Cadence Xcelium. From inside a stage's directory:

```bash
# Stage 1 — directed TB (single compile unit)
xrun -access +rwc fifo.sv fifo_tb.sv

# Stage 2 — layered TB (package-based)
xrun -access +rwc -f filelist.f

# Stage 3 — UVM TB (any task folder, e.g. task4_complete_env)
xrun -access +rwc -uvm fifo_if.sv fifo.sv tx_pkg.sv top.sv
```

Adjust include/library flags as needed for your Xcelium install (e.g. `-incdir` if your UVM library path isn't on the default search path). The same sources should compile under other SystemVerilog/UVM simulators (Questa, VCS) with minor command-line differences.

## Repository Structure

```
.
├── 01_rtl_and_directed_tb/
│   ├── fifo.sv            # DUT (depth=16, flat ports)
│   └── fifo_tb.sv         # Directed testbench
├── 02_layered_tb/
│   ├── fifo.sv             # DUT (flat ports)
│   ├── fifo_if.sv          # Interface with driver/monitor clocking blocks
│   ├── fifo_pkg.sv         # Package tying the layered env together
│   ├── fifo_transaction.sv
│   ├── generator.sv
│   ├── driver.sv
│   ├── monitor.sv
│   ├── scoreboard.sv
│   ├── environment.sv
│   ├── test.sv
│   ├── top.sv
│   └── filelist.f
└── 03_uvm_tb/
    ├── task1_basic_env/
    ├── task2_sequence_item/
    ├── task3_agent_driver_monitor/
    └── task4_complete_env/     # Final, fully self-checking UVM environment
```

## Author

**Fahad Ahmad**
Digital IC Design & Verification
GIKI / Chip-DV

## License

MIT — see [LICENSE](LICENSE).
