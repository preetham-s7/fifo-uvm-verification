param(
    [Parameter(Mandatory=$true)][string]$QuestaHome,
    [int[]]$Seeds = @(1,7,42)
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$source = Join-Path $root '03_uvm_tb/task4_complete_env'
$build = Join-Path $root '.sim'
$uvm = Join-Path $QuestaHome 'uvm-1.2'
$include = Join-Path $QuestaHome 'verilog_src/uvm-1.2/src'
$vlib = Join-Path $QuestaHome 'win64/vlib.exe'
$vlog = Join-Path $QuestaHome 'win64/vlog.exe'
$vsim = Join-Path $QuestaHome 'win64/vsim.exe'
New-Item -ItemType Directory -Force -Path $build | Out-Null
Push-Location $build
try {
    if (!(Test-Path -LiteralPath 'work')) { & $vlib work; if($LASTEXITCODE){throw 'vlib failed'} }
    & $vlog -sv -timescale 1ns/1ns -work work -L $uvm "+incdir+$include" "+incdir+$source" (Join-Path $source 'fifo_if.sv') (Join-Path $source 'fifo.sv') (Join-Path $source 'tx_pkg.sv') (Join-Path $source 'top.sv') | Out-Null
    if($LASTEXITCODE){throw 'Compilation failed'}
    foreach($seed in $Seeds) {
        $log = "fifo-seed-$seed.log"
        & $vsim -c -lic_noqueue -L $uvm work.top -sv_seed $seed +UVM_VERBOSITY=UVM_LOW -l $log -do 'run 100 us; quit -f' | Out-Null
        if($LASTEXITCODE){throw "Simulation failed: seed $seed"}
        $text = Get-Content -Raw -LiteralPath $log
        if($text -notmatch 'TEST PASSED SUCCESSFULLY' -or $text -notmatch 'UVM_ERROR\s*:\s*0' -or $text -notmatch 'UVM_FATAL\s*:\s*0' -or $text -match '\*\* (Error|Fatal):') {throw "Result validation failed: $log"}
        $passes = [regex]::Match($text,'Total passed checks = (\d+)').Groups[1].Value
        Write-Output "PASS FIFO seed=$seed checked_transactions=$passes UVM_ERROR=0 UVM_FATAL=0"
    }
    Write-Output 'VERDICT: PASS'
} finally { Pop-Location }
