import argparse
import re
from pathlib import Path


RTL = Path(__file__).resolve().parent.parent / "CourseLab.srcs" / "sources_1"
COEFFICIENTS = bytes.fromhex("94208510c2c001fb01c0c21085209401")


def multiply(a, b):
    product = 0
    while b:
        if b & 1:
            product ^= a
        a = (a << 1) ^ (0x1C3 if a & 0x80 else 0)
        b >>= 1
    return product


def feedback(block):
    result = 0
    for byte, coefficient in zip(block, COEFFICIENTS):
        result ^= multiply(byte, coefficient)
    return result


def forward_r(value):
    block = value.to_bytes(16, "big")
    return (feedback(block) << 120) | (value >> 8)


def inverse_r(value):
    block = value.to_bytes(16, "big")
    last = block[0] ^ feedback(block[1:])
    return int.from_bytes(block[1:] + bytes([last]), "big")


def iterate(transform, value, steps):
    for _ in range(steps):
        value = transform(value)
    return value


def reverse_bytes(value):
    return int.from_bytes(value.to_bytes(16, "big"), "little")


def read_masks(filename):
    source = (RTL / filename).read_text(encoding="cp1251")
    return [int(mask, 16) for mask in re.findall(r"128'h([0-9a-fA-F]{32})", source)]


def matrix_rows(columns):
    return [sum(((column >> bit) & 1) << i for i, column in enumerate(columns))
            for bit in range(128)]


def checked_r8_rows():
    basis = [1 << i for i in range(128)]
    r8 = [iterate(forward_r, value, 8) for value in basis]
    r16 = [iterate(forward_r, value, 8) for value in r8]
    if matrix_rows(r16) != read_masks("l_matrix_comb.v"):
        raise ValueError("Two R8 stages do not match the forward L matrix")

    inverse_r8 = [iterate(inverse_r, value, 8) for value in basis]
    reflected_r8 = [reverse_bytes(iterate(forward_r, reverse_bytes(value), 8))
                    for value in basis]
    if reflected_r8 != inverse_r8:
        raise ValueError("Byte reversal does not reproduce inverse R8")

    inverse_r16 = [iterate(inverse_r, value, 8) for value in inverse_r8]
    if matrix_rows(inverse_r16) != read_masks("l_inverse_matrix_comb.v"):
        raise ValueError("Two inverse R8 stages do not match the inverse L matrix")
    return matrix_rows(r8)


def render(masks):
    header = """`timescale 1ns / 1ps

// Матрица восьми шагов R. Маски формирует work/generate_kuz_r8_matrix.py.
// Для обратного хода разворачиваем порядок байтов до и после прямой матрицы.

module kuz_r8_matrix_comb #(
    parameter INVERSE = 1'b0
) (
    input  [127:0] data_input,
    output [127:0] data_output
);

    wire [127:0] direct_input;
    wire [127:0] direct_output;

    genvar byte_index;
    generate
        if (INVERSE) begin : reverse_order
            for (byte_index = 0; byte_index < 16; byte_index = byte_index + 1) begin : bytes
                assign direct_input[8*byte_index +: 8] = data_input[127-8*byte_index -: 8];
                assign data_output[8*byte_index +: 8] = direct_output[127-8*byte_index -: 8];
            end
        end else begin : direct_order
            assign direct_input = data_input;
            assign data_output = direct_output;
        end
    endgenerate

"""
    rows = []
    for index, mask in enumerate(masks):
        if mask.bit_count() == 1:
            value = f"direct_input[{mask.bit_length() - 1}]"
        else:
            value = f"^(direct_input & 128'h{mask:032x})"
        rows.append(f"    assign direct_output[{index}] = {value};")
    return header + "\n".join(rows) + "\n\nendmodule\n"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    path = RTL / "kuz_r8_matrix_comb.v"
    source = render(checked_r8_rows())
    if args.check:
        if path.read_text(encoding="cp1251") != source:
            raise SystemExit("R8 RTL differs from the generated matrix")
    else:
        path.write_text(source, encoding="cp1251")
    print("ALL PASS: R8 and inverse R8 composition on 128 basis vectors per direction")


if __name__ == "__main__":
    main()
