param(
    [string]$VivadoBin = 'C:/Users/cosmo/Desktop/vivad/Xilinx_Windows_Unpacked_2022_2/Vivado/2022.2/bin',
    [ValidateSet('all','l','iterative','round','round_fourcycle','key_schedule','key_loader','encrypt','decrypt','kuz_top')][string]$Test = 'all'
)

$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$rtl = Join-Path $taskRoot 'CourseLab.srcs/sources_1'
$sim = Join-Path $taskRoot 'CourseLab.srcs/sim_1'

function Run-Test([string]$name, [string]$top, [string[]]$rtlNames, [string]$tb, [string]$marker, [string[]]$parameters = @()) {
    $build = [System.IO.Path]::GetFullPath((Join-Path $taskRoot ('work/sim_unit_crypto_' + $name)))
    $workRoot = [System.IO.Path]::GetFullPath((Join-Path $taskRoot 'work'))
    if (!$build.StartsWith($workRoot + [System.IO.Path]::DirectorySeparatorChar,[System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Build path outside work directory'
    }
    if (Test-Path -LiteralPath $build) { throw "Build already exists: $build" }
    New-Item -ItemType Directory -Path $build | Out-Null
    $success = $false
    Push-Location $build
    try {
        # В каждом запуске компилируется только выбранный TB и зависимости его DUT.
        $sources = @($rtlNames | ForEach-Object { [IO.Path]::GetFullPath((Join-Path $rtl $_)) })
        $sources += [IO.Path]::GetFullPath((Join-Path $sim $tb))
        & (Join-Path $VivadoBin 'xvlog.bat') @sources *> compile.log
        if ($LASTEXITCODE -ne 0) { throw "$name compilation failed: $build" }
        $elaboration = @($top, '-s', 'test_snapshot', '-debug', 'typical')
        foreach ($parameter in $parameters) { $elaboration += @('-generic_top', ('"' + $parameter + '"')) }
        & (Join-Path $VivadoBin 'xelab.bat') @elaboration *> elaborate.log
        if ($LASTEXITCODE -ne 0) { throw "$name elaboration failed: $build" }
        & (Join-Path $VivadoBin 'xsim.bat') test_snapshot -runall -log simulation.log *> runner.log
        $simExit = $LASTEXITCODE
        $logText = Get-Content -Raw -LiteralPath simulation.log
        $diagnostics = (Get-Content -Raw -LiteralPath compile.log) + (Get-Content -Raw -LiteralPath elaborate.log)
        if ($simExit -ne 0 -or $logText -match '(?m)^\s*(FAIL:|Fatal:|ERROR:)' -or !$logText.Contains($marker)) {
            throw "$name simulation failed: $build"
        }
        if ($diagnostics -match '(?m)^\s*(WARNING:|ERROR:)') { throw "$name compiler diagnostics: $build" }
        $saved = Join-Path $taskRoot ('outputs/unit_tests/' + $name)
        New-Item -ItemType Directory -Path $saved -Force | Out-Null
        foreach ($file in @('compile.log','elaborate.log','simulation.log')) {
            Copy-Item -LiteralPath $file -Destination (Join-Path $saved $file) -Force
        }
        $logText -split "`r?`n" | Where-Object { $_ -match '^(TESTS PASSED:|ALL PASS:)' } | Write-Output
        $success = $true
    } finally {
        Pop-Location
        # Удаляется только созданная этим запуском сборка после сохранения успешного журнала.
        if ($success) { Remove-Item -LiteralPath $build -Recurse -Force }
    }
}

if ($Test -in @('all','l')) {
    Run-Test 'l_onecycle' 'tb_L_function' @('l_matrix_comb.v','../experiments/l_matrix_onecycle.v') '../experiments/tb.v' 'ALL PASS: L one-cycle;'
}
if ($Test -in @('all','iterative')) {
    Run-Test 'l_iterative' 'tb_iterative' @('../experiments/l_iterative_16cycles.v') '../experiments/tb_iterative.v' 'ALL PASS: L iterative;'
}
if ($Test -in @('all','round')) {
    # Два DUT в общем TB сохранены по явному указанию пользователя.
    Run-Test 'matrix_round' 'tb_matrix_round' @('l_matrix_comb.v','kuz_lsx_matrix_comb.v','f_matrix_onecycle.v','lsx_matrix_onecycle.v') 'tb_matrix_round.v' 'ALL PASS: F and LSX;'
}
if ($Test -in @('all','round_fourcycle')) {
    $fourcycleSources = @(
        'kuz_lsx_matrix_comb.v', 'data_inverse_matrix_onecycle.v', 'kuz_r8_matrix_comb.v',
        'kuz_round_fourcycle.v', '../experiments/test_impl_round_fourcycle.v'
    )
    Run-Test 'round_fourcycle_enc' 'tb_kuz_round_fourcycle' $fourcycleSources '../experiments/tb_kuz_round_fourcycle.v' 'ALL PASS: kuz_round_fourcycle; DECRYPT=0; 3 scenarios; 5 results'
    Run-Test 'round_fourcycle_dec' 'tb_kuz_round_fourcycle' $fourcycleSources '../experiments/tb_kuz_round_fourcycle.v' 'ALL PASS: kuz_round_fourcycle; DECRYPT=1; 3 scenarios; 5 results' @('DECRYPT=1')
}
$keyScheduleSources = @(
    'l_matrix_comb.v', 'kuz_lsx_matrix_comb.v', 'f_matrix_onecycle.v', 'kuz_round_constant.v', 'kuz_key_schedule.v'
)

if ($Test -in @('all','key_schedule')) {
    Run-Test 'key_schedule' 'tb_kuz_key_schedule' $keyScheduleSources 'tb_kuz_key_schedule.v' 'ALL PASS: kuz_key_schedule; 3 scenarios; prepare=33 cycles'
}
if ($Test -in @('all','key_loader')) {
    Run-Test 'key_loader' 'tb_kuz_key_loader' ($keyScheduleSources + 'kuz_key_loader.v') 'tb_kuz_key_loader.v' 'ALL PASS: kuz_key_loader; 3 scenarios; 3 transfers'
}

$roundSources = @(
    'kuz_lsx_matrix_comb.v', 'data_inverse_matrix_onecycle.v',
    'kuz_r8_matrix_comb.v', 'kuz_round_fourcycle.v', 'kuz_round_pipeline.v'
)

if ($Test -in @('all','encrypt')) {
    Run-Test 'encrypt_top' 'tb_encrypt_top' ($roundSources + 'Encrypt_TOP.v') 'tb_encrypt_top.v' 'ALL PASS: Encrypt_TOP; 5 scenarios; 46 blocks; latency=37'
}
if ($Test -in @('all','decrypt')) {
    Run-Test 'decrypt_top' 'tb_decrypt_top' ($roundSources + 'Decrypt_TOP.v') 'tb_decrypt_top.v' 'ALL PASS: Decrypt_TOP; 5 scenarios; 46 blocks; latency=37'
}
if ($Test -in @('all','kuz_top')) {
    $topSources = $roundSources + @('Encrypt_TOP.v', 'Decrypt_TOP.v', 'new/kuz_TOP.v')
    Run-Test 'kuz_top' 'tb_kuz_top' $topSources 'tb_kuz_top.v' 'ALL PASS: kuz_TOP; 5 scenarios; 13 blocks; ENC=37 DEC=37'
}
