#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build tests/results
# Optional paths allow use of a locally extracted simulator installation.
iverilog_bin=${IVERILOG:-iverilog}
vvp_bin=${VVP:-vvp}
compiler_args=()
runtime_args=()
if [[ -n ${IVL_PATH:-} ]]; then
    compiler_args+=(-B "$IVL_PATH")
    runtime_args+=(-M "$IVL_PATH")
fi
for test_name in tb_pea tb_loader tb_cin2 tb_tails tb_classic tb_tiny; do
    "$iverilog_bin" "${compiler_args[@]}" -g2001 -Wall -s "$test_name" \
        -o "build/$test_name.vvp" ./*.v "tests/$test_name.v"
    "$vvp_bin" "${runtime_args[@]}" "build/$test_name.vvp" | tee "tests/results/$test_name.log"
    if grep -q FAIL "tests/results/$test_name.log" || ! grep -q PASS "tests/results/$test_name.log"; then
        exit 1
    fi
done
