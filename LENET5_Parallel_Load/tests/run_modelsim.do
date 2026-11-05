onerror {quit -code 1}
if {![file exists work]} {vlib work}
vlog -vlog01compat {*}[glob *.v] tests/tb_loader.v tests/tb_pea.v tests/tb_cin2.v tests/tb_tails.v tests/tb_classic.v tests/tb_tiny.v
foreach test_name {tb_pea tb_loader tb_cin2 tb_tails tb_classic tb_tiny} {
    vsim -onfinish stop work.$test_name
    run -all
    set failures [examine -radix unsigned /$test_name/errors_r]
    if {$failures != 0} {error "Test failed: $test_name errors=$failures"}
    quit -sim
}
puts "All PEA and LeNet tests passed."
