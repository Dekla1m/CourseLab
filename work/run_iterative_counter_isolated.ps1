param([string]$VivadoBin = 'C:/Users/cosmo/Desktop/vivad/Xilinx_Windows_Unpacked_2022_2/Vivado/2022.2/bin')
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'check_crypto_tests.ps1') -VivadoBin $VivadoBin -Test iterative
