param(
    [string]$VivadoBin='C:/Xilinx/Vivado/2022.2/bin',
    [string[]]$Tests=@('tb_pea','tb_loader','tb_cin2','tb_tails','tb_classic','tb_tiny')
)
$ErrorActionPreference='Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    $rtlFiles=Get-ChildItem -File -Filter *.v | Select-Object -ExpandProperty Name
    $testFiles=$Tests | ForEach-Object { "tests/$_.v" }
    & (Join-Path $VivadoBin 'xvlog.bat') @rtlFiles @testFiles
    if($LASTEXITCODE -ne 0) { throw 'Verilog compilation failed' }
    foreach($testName in $Tests) {
        & (Join-Path $VivadoBin 'xelab.bat') $testName -s $testName
        if($LASTEXITCODE -ne 0) { throw "Elaboration failed: $testName" }
        & (Join-Path $VivadoBin 'xsim.bat') $testName -runall -log "tests/$testName.log"
        if($LASTEXITCODE -ne 0) { throw "Simulation failed: $testName" }
        $log=Get-Content -LiteralPath "tests/$testName.log" -Raw
        if($log -match 'FAIL' -or $log -notmatch 'PASS') { throw "Test failed: $testName" }
    }
} finally { Pop-Location }
