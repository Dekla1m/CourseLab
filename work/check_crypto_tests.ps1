param(
    [string]$VivadoBin = 'C:/Users/cosmo/Desktop/vivad/Xilinx_Windows_Unpacked_2022_2/Vivado/2022.2/bin',
    [ValidateSet('all','l','iterative','round','encrypt','decrypt','kuz_top')][string]$Test = 'all'
)

$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$rtl = Join-Path $taskRoot 'CourseLab.srcs/sources_1'
$sim = Join-Path $taskRoot 'CourseLab.srcs/sim_1'

function Run-Test([string]$name, [string]$top, [string[]]$rtlNames, [string]$tb, [string]$marker) {
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
        $sources = @($rtlNames | ForEach-Object { Join-Path $rtl $_ })
        $sources += Join-Path $sim $tb
        & (Join-Path $VivadoBin 'xvlog.bat') @sources *> compile.log
        if ($LASTEXITCODE -ne 0) { throw "$name compilation failed: $build" }
        & (Join-Path $VivadoBin 'xelab.bat') $top -s test_snapshot -debug typical *> elaborate.log
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
    Run-Test 'l_onecycle' 'tb_L_function' @('l_matrix_comb.v','l_matrix_onecycle.v') 'tb.v' 'ALL PASS: L one-cycle;'
}
if ($Test -in @('all','iterative')) {
    Run-Test 'l_iterative' 'tb_iterative' @('l_iterative_16cycles.v') 'tb_iterative.v' 'ALL PASS: L iterative;'
}
if ($Test -in @('all','round')) {
    # Два DUT в общем TB сохранены по явному указанию пользователя.
    Run-Test 'matrix_round' 'tb_matrix_round' @('l_matrix_comb.v','kuz_lsx_matrix_comb.v','f_matrix_onecycle.v','lsx_matrix_onecycle.v') 'tb_matrix_round.v' 'ALL PASS: F and LSX;'
}
if ($Test -in @('all','encrypt')) {
    Run-Test 'encrypt_top' 'tb_encrypt_top' @('l_matrix_comb.v','kuz_lsx_matrix_comb.v','f_matrix_onecycle.v','lsx_matrix_onecycle.v','kuz_round_constant.v','Encrypt_TOP.v') 'tb_encrypt_top.v' 'ALL PASS: Encrypt_TOP;'
}
if ($Test -in @('all','decrypt')) {
    Run-Test 'decrypt_top' 'tb_decrypt_top' @(
        'l_matrix_comb.v', 'kuz_lsx_matrix_comb.v', 'f_matrix_onecycle.v', 'kuz_round_constant.v',
        'l_inverse_matrix_comb.v', 'data_inverse_matrix_onecycle.v', 'Decrypt_TOP.v'
    ) 'tb_decrypt_top.v' 'ALL PASS: Decrypt_TOP; 10 scenarios; 8 blocks; latency=43'
}
if ($Test -in @('all','kuz_top')) {
    Run-Test 'kuz_top' 'tb_kuz_top' @(
        'l_matrix_comb.v', 'kuz_lsx_matrix_comb.v', 'f_matrix_onecycle.v', 'kuz_round_constant.v',
        'lsx_matrix_onecycle.v', 'Encrypt_TOP.v', 'l_inverse_matrix_comb.v',
        'data_inverse_matrix_onecycle.v', 'Decrypt_TOP.v', 'new/kuz_TOP.v'
    ) 'tb_kuz_top.v' 'ALL PASS: kuz_TOP; 4 scenarios; 10 blocks; ENC=35 DEC=43'
}
