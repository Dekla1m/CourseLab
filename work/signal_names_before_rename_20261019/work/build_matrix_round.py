"""Generate the S-box case and polynomial-reference test vectors for matrix rounds."""
from pathlib import Path
import random
import re

ROOT = Path(__file__).resolve().parents[1]
RTL = ROOT / 'CourseLab.srcs/sources_1/new'
PI = bytes.fromhex('''
FC EE DD 11 CF 6E 31 16 FB C4 FA DA 23 C5 04 4D
E9 77 F0 DB 93 2E 99 BA 17 36 F1 BB 14 CD 5F C1
F9 18 65 5A E2 5C EF 21 81 1C 3C 42 8B 01 8E 4F
05 84 02 AE E3 6A 8F A0 06 0B ED 98 7F D4 D3 1F
EB 34 2C 51 EA C8 48 AB F2 2A 68 A2 FD 3A CE CC
B5 70 0E 56 08 0C 76 12 BF 72 13 47 9C B7 5D 87
15 A1 96 29 10 7B 9A C7 F3 91 78 6F 9D 9E B2 B1
32 75 19 3D FF 35 8A 7E 6D 54 C6 80 C3 BD 0D 57
DF F5 24 A9 3E A8 43 C9 D7 79 D6 F6 7C 22 B9 03
E0 0F EC DE 7A 94 B0 BC DC E8 28 50 4E 33 0A 4A
A7 97 60 73 1E 00 62 44 1A B8 38 82 64 9F 26 41
AD 45 46 92 27 5E 55 2F 8C A3 A5 7D 69 D5 95 3B
07 58 B3 40 86 AC 1D F7 30 37 6B E4 88 D9 E7 89
E1 1B 83 49 4C 3F F8 FE 8D 53 AA 90 CA D8 85 61
20 71 67 A4 2D 2B 09 5B CB 9B 25 D0 BE E5 6C 52
59 A6 74 D2 E6 F4 B4 C0 D1 66 AF C2 39 4B 63 B6
''')
assert len(PI) == len(set(PI)) == 256
COEFF = [148,32,133,16,194,192,1,251,1,192,194,16,133,32,148,1]

def mul(a, b):
    result = 0
    for _ in range(8):
        if b & 1:
            result ^= a
        a = ((a << 1) & 255) ^ (0xC3 if a & 128 else 0)
        b >>= 1
    return result

def linear(a):
    for _ in range(16):
        r = 0
        for value, coefficient in zip(a, COEFF):
            r ^= mul(value, coefficient)
        a = bytes([r]) + a[:15]
    return a

def xor(a, b):
    return bytes(x ^ y for x, y in zip(a, b))

def lsx(a, c):
    return linear(bytes(PI[x] for x in xor(a, c)))

# L is generated separately by create_l_benchmark.py: one module per file.
source = (RTL / 'l_matrix_comb.v').read_text()
assert len(re.findall(r'^    assign product\[\d+\].*?;$', source, re.M)) == 128

header = '''// Complete Kuznyechik round building blocks. Byte order: MSB on the left.
// F[k](a,b) = (L(S(a XOR k)) XOR b, a): one registered Feistel step.
// LSX[k](a) = L(S(a XOR k)): one registered data-encryption round.
// start is sampled with a/b/k; done marks the matching registered outputs.
// With start=1 continuously, accept a new independent operation every cycle.
// Architectural latency is one cycle; 200 MHz requires post-route validation.
`timescale 1ns/1ps
module f_matrix_onecycle (
    input wire clk, rst, start,
    input wire [127:0] a, b, k,
    output reg [127:0] a_next, b_next,
    output reg done
);
    wire [127:0] lsx;
    kuz_lsx_matrix_comb datapath (.a(a), .k(k), .y(lsx));
    always @(posedge clk) begin
        if (rst) begin
            a_next <= 128'b0;
            b_next <= 128'b0;
            done <= 1'b0;
        end else begin
            done <= start;
            if (start) begin
                a_next <= lsx ^ b;
                b_next <= a;
            end
        end
    end
endmodule

module lsx_matrix_onecycle (
    input wire clk, rst, start,
    input wire [127:0] a, k,
    output reg [127:0] y,
    output reg done
);
    wire [127:0] lsx;
    kuz_lsx_matrix_comb datapath (.a(a), .k(k), .y(lsx));
    always @(posedge clk) begin
        if (rst) begin
            y <= 128'b0;
            done <= 1'b0;
        end else begin
            done <= start;
            if (start) y <= lsx;
        end
    end
endmodule

// No intermediate registers: XOR -> 16 parallel S-boxes -> full L matrix.
module kuz_lsx_matrix_comb (
    input wire [127:0] a, k,
    output wire [127:0] y
);
    wire [127:0] mixed = a ^ k;
    wire [127:0] substituted;
    // pi from RFC 7801 section 4.1. case describes a combinational truth table.
    function automatic [7:0] pi(input [7:0] value);
        begin
            case (value)
'''
cases = ''.join(f"                8'h{i:02x}: pi = 8'h{v:02x};\n" for i,v in enumerate(PI))
footer = '''                default: pi = 8'hxx;
            endcase
        end
    endfunction
    genvar byte_index;
    generate
        for (byte_index=0; byte_index<16; byte_index=byte_index+1) begin: sboxes
            assign substituted[8*byte_index +: 8] = pi(mixed[8*byte_index +: 8]);
        end
    endgenerate
    l_matrix_comb linear (.a(substituted), .product(y));
endmodule
'''
module_comments = {
    'f_matrix_onecycle': '// Registered Feistel step: (L(S(a XOR k)) XOR b, a).\n',
    'lsx_matrix_onecycle': '// Registered encryption round: L(S(a XOR k)).\n',
    'kuz_lsx_matrix_comb': '// Combinational XOR -> 16 S-boxes -> L. No registers.\n',
}
for match in re.finditer(r'^module\s+(\w+)\b.*?^endmodule\b', header + cases + footer, re.M | re.S):
    name = match.group(1)
    text = module_comments[name] + '// Byte order: MSB on the left.\n`timescale 1ns/1ps\n'
    (RTL / f'{name}.v').write_text(text + match.group(0) + '\n', encoding='utf-8')

# The reference evaluates 16 polynomial R steps, independently of HDL masks.
vectors = []
def add(a,b,c):
    fa = xor(lsx(a,c),b)
    vectors.append((a,b,c,fa))
    return fa,a

master = bytes.fromhex('8899aabbccddeeff0011223344556677fedcba98765432100123456789abcdef')
a,b = master[:16], master[16:]
keys = [a,b]
for i in range(1,33):
    a,b = add(a,b,linear(i.to_bytes(16,'big')))
    if i == 1:
        assert a.hex() == 'c3d5fa01ebe36f7a9374427ad7ca8949'
    if i == 2:
        assert a.hex() == '37777748e56453377d5e262d90903f87'
    if i % 8 == 0:
        keys += [a,b]
expected_keys = '''8899aabbccddeeff0011223344556677 fedcba98765432100123456789abcdef
db31485315694343228d6aef8cc78c44 3d4553d8e9cfec6815ebadc40a9ffd04
57646468c44a5e28d3e59246f429f1ac bd079435165c6432b532e82834da581b
51e640757e8745de705727265a0098b1 5a7925017b9fdd3ed72a91a22286f984
bb44e25378c73123a5f32f73cdb6e517 72e9dd7416bcf45b755dbaa88e4a4043'''.split()
assert [k.hex() for k in keys] == expected_keys
state = bytes.fromhex('1122334455667700ffeeddccbbaa9988')
for key in keys[:9]:
    state,_ = add(state,bytes(16),key)
assert xor(state,keys[9]).hex() == '7f679d90bebc24305a468d42b9d4edcd'
# All 256 S inputs are exercised simultaneously at every byte position.
for value in range(256):
    add(bytes([value])*16,bytes(16),bytes(16))
rng = random.Random(34122015)
for _ in range(256):
    add(*(rng.getrandbits(128).to_bytes(16,'big') for _ in range(3)))
out = ROOT / 'work/matrix_round_vectors.mem'
out.write_text(''.join(''.join(x.hex() for x in row)+'\n' for row in vectors))
print(f'Generated F/LSX and {len(vectors)} polynomial-reference vectors; all 10 keys and ciphertext match RFC.')
