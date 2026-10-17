# FIFO UVM Verification

Parameterized synchronous FIFO implemented in SystemVerilog and verified with:

- Directed testbench
- Mailbox-based layered testbench
- UVM testbench with constrained-random stimulus and scoreboard

The RTL supports configurable data width and FIFO depth, explicit pointer wrapping, simultaneous read/write, and correctly timed overflow/underflow flags.

## Repository layout

```text
01_rtl_and_directed_tb/       Directed testbench
02_layered_tb/                 Mailbox-based layered testbench
03_uvm_tb/                     Incremental UVM environments
  task4_complete_env/          Complete UVM environment
tests/                         Open-source RTL smoke test
scripts/run-questa.ps1         Questa multi-seed regression
.github/workflows/             GitHub Actions smoke test
```

## Run the RTL smoke test

Requires Icarus Verilog:

```bash
iverilog -g2012 -s rtl_smoke_tb -o rtl-smoke.vvp \
  01_rtl_and_directed_tb/fifo.sv tests/rtl_smoke_tb.sv
vvp rtl-smoke.vvp
```

## Run the UVM regression

Requires QuestaSim 10.7c and UVM 1.2:

```powershell
./scripts/run-questa.ps1 -QuestaHome C:/questasim64_10.7c
```

The runner executes seeds `1`, `7`, and `42`, then checks completion, scoreboard results, and UVM errors/fatals. Logs are written to `.sim/`.

## Validation

See [VALIDATION.md](VALIDATION.md) for recorded results and limitations.

The final UVM environment is currently configured for 8-bit data and depth 4. Other configurations, formal verification, synthesis, and coverage closure are not yet validated.

## License

MIT. See [LICENSE](LICENSE).
