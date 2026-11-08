param(
    [string]$VivadoBin = 'C:/Users/cosmo/Desktop/vivad/Xilinx_Windows_Unpacked_2022_2/Vivado/2022.2/bin',
    [ValidateSet('all','fifo','key')][string]$Test = 'all'
)

$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent

function Run-Test([string]$name, [string]$top, [string[]]$sources, [string]$marker, [string[]]$parameters = @()) {
    $build = Join-Path $taskRoot ('work/sim_unit_' + $name)
    New-Item -ItemType Directory -Path $build -Force | Out-Null
    Push-Location $build

    try {
        # Компиляция только в режиме Verilog. Список содержит DUT, его зависимости и один TB.
        & (Join-Path $VivadoBin 'xvlog.bat') @sources *> compile.log
        if ($LASTEXITCODE -ne 0) { throw "$name compilation failed" }

        $elaboration = @($top, '-s', 'test_snapshot', '-debug', 'typical')
        # Windows .bat должен получить NAME=VALUE в кавычках, иначе разделяет знак '='.
        foreach ($parameter in $parameters) { $elaboration += @('-generic_top', ('"' + $parameter + '"')) }
        & (Join-Path $VivadoBin 'xelab.bat') @elaboration *> elaborate.log
        if ($LASTEXITCODE -ne 0) { throw "$name elaboration failed" }

        & (Join-Path $VivadoBin 'xsim.bat') test_snapshot -runall -log simulation.log *> runner.log
        $simExit = $LASTEXITCODE
        $logText = Get-Content -Raw -LiteralPath simulation.log

        if ($simExit -ne 0 -or $logText -match '(?m)^\s*(FAIL:|Fatal:|ERROR:|TEST [0-9]+: FAIL)' -or -not $logText.Contains($marker)) {
            throw "$name simulation failed: inspect $build/simulation.log"
        }

        $diagnostics = (Get-Content -Raw compile.log) + (Get-Content -Raw elaborate.log)
        if ($diagnostics -match '(?m)^(WARNING:|ERROR:)') { throw "$name unexpected compiler diagnostics" }

        $logText -split "`r?`n" | Where-Object { $_ -match '^(TESTS PASSED:|ALL PASS:)' } | Write-Output

        $saved = Join-Path $taskRoot ('outputs/unit_tests/' + $name)
        New-Item -ItemType Directory -Path $saved -Force | Out-Null
        foreach ($file in @('compile.log','elaborate.log','simulation.log')) {
            Copy-Item -LiteralPath $file -Destination (Join-Path $saved $file) -Force
        }
    } finally { Pop-Location }
}

if ($Test -in @('all','fifo')) {
    $sources = @(
        (Join-Path $taskRoot 'CourseLab.srcs/sources_1/FIFO.v'),
        (Join-Path $taskRoot 'CourseLab.srcs/sim_1/tb_fifo.v')
    )

    # Один параметризованный TB и один DUT на запуск: обычная конфигурация и границы параметров.
    Run-Test 'fifo_default' 'tb_fifo' $sources 'ALL PASS: FIFO unit test;' @('WIDTH=8','DEPTH=64','WR_HALF=5','RD_HALF=7','ID=0')
    Run-Test 'fifo_rx' 'tb_fifo' $sources 'ALL PASS: FIFO unit test;' @('WIDTH=10','DEPTH=16','WR_HALF=7','RD_HALF=3','ID=1')
    Run-Test 'fifo_minimum' 'tb_fifo' $sources 'ALL PASS: FIFO unit test;' @('WIDTH=1','DEPTH=2','WR_HALF=5','RD_HALF=5','ID=2')
    Run-Test 'fifo_result' 'tb_fifo' $sources 'ALL PASS: FIFO unit test;' @('WIDTH=129','DEPTH=4','WR_HALF=5','SAME_CLOCK=1','ID=3')
}

if ($Test -in @('all','key')) {
    Run-Test 'key_input_order' 'tb_key_input_order' @(
        (Join-Path $taskRoot 'CourseLab.srcs/sources_1/KM_ASCII_TO_HEX.v'),
        (Join-Path $taskRoot 'CourseLab.srcs/sources_1/Key_input_order.v'),
        (Join-Path $taskRoot 'CourseLab.srcs/sim_1/tb_key_input_order.v')
    ) 'ALL PASS: Key_input_order unit test;'
}
