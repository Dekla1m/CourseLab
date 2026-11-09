`timescale 1ns / 1ps

// ћатрица восьми шагов R. ћаски формирует work/generate_kuz_r8_matrix.py.
// ƒл€ обратного хода разворачиваем пор€док байтов до и после пр€мой матрицы.

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

    assign direct_output[0] = direct_input[64];
    assign direct_output[1] = direct_input[65];
    assign direct_output[2] = direct_input[66];
    assign direct_output[3] = direct_input[67];
    assign direct_output[4] = direct_input[68];
    assign direct_output[5] = direct_input[69];
    assign direct_output[6] = direct_input[70];
    assign direct_output[7] = direct_input[71];
    assign direct_output[8] = direct_input[72];
    assign direct_output[9] = direct_input[73];
    assign direct_output[10] = direct_input[74];
    assign direct_output[11] = direct_input[75];
    assign direct_output[12] = direct_input[76];
    assign direct_output[13] = direct_input[77];
    assign direct_output[14] = direct_input[78];
    assign direct_output[15] = direct_input[79];
    assign direct_output[16] = direct_input[80];
    assign direct_output[17] = direct_input[81];
    assign direct_output[18] = direct_input[82];
    assign direct_output[19] = direct_input[83];
    assign direct_output[20] = direct_input[84];
    assign direct_output[21] = direct_input[85];
    assign direct_output[22] = direct_input[86];
    assign direct_output[23] = direct_input[87];
    assign direct_output[24] = direct_input[88];
    assign direct_output[25] = direct_input[89];
    assign direct_output[26] = direct_input[90];
    assign direct_output[27] = direct_input[91];
    assign direct_output[28] = direct_input[92];
    assign direct_output[29] = direct_input[93];
    assign direct_output[30] = direct_input[94];
    assign direct_output[31] = direct_input[95];
    assign direct_output[32] = direct_input[96];
    assign direct_output[33] = direct_input[97];
    assign direct_output[34] = direct_input[98];
    assign direct_output[35] = direct_input[99];
    assign direct_output[36] = direct_input[100];
    assign direct_output[37] = direct_input[101];
    assign direct_output[38] = direct_input[102];
    assign direct_output[39] = direct_input[103];
    assign direct_output[40] = direct_input[104];
    assign direct_output[41] = direct_input[105];
    assign direct_output[42] = direct_input[106];
    assign direct_output[43] = direct_input[107];
    assign direct_output[44] = direct_input[108];
    assign direct_output[45] = direct_input[109];
    assign direct_output[46] = direct_input[110];
    assign direct_output[47] = direct_input[111];
    assign direct_output[48] = direct_input[112];
    assign direct_output[49] = direct_input[113];
    assign direct_output[50] = direct_input[114];
    assign direct_output[51] = direct_input[115];
    assign direct_output[52] = direct_input[116];
    assign direct_output[53] = direct_input[117];
    assign direct_output[54] = direct_input[118];
    assign direct_output[55] = direct_input[119];
    assign direct_output[56] = direct_input[120];
    assign direct_output[57] = direct_input[121];
    assign direct_output[58] = direct_input[122];
    assign direct_output[59] = direct_input[123];
    assign direct_output[60] = direct_input[124];
    assign direct_output[61] = direct_input[125];
    assign direct_output[62] = direct_input[126];
    assign direct_output[63] = direct_input[127];
    assign direct_output[64] = ^(direct_input & 128'hc6d877b05ada015301da5ab077d8c601);
    assign direct_output[65] = ^(direct_input & 128'h4a6898d0ef6e02f5026eefd098684a02);
    assign direct_output[66] = ^(direct_input & 128'h95d031a0dedc04ea04dcdea031d09504);
    assign direct_output[67] = ^(direct_input & 128'h2aa06240bcb808d508b8bc4062a02a08);
    assign direct_output[68] = ^(direct_input & 128'h5540c481787010ab10707881c4405510);
    assign direct_output[69] = ^(direct_input & 128'haa818802f0e0205720e0f0028881aa20);
    assign direct_output[70] = ^(direct_input & 128'h92da66b4bb1b40fd401bbbb466da9240);
    assign direct_output[71] = ^(direct_input & 128'he36cbbd82ded80a980ed2dd8bb6ce380);
    assign direct_output[72] = ^(direct_input & 128'h7679c4467d45954a1c1e176bacc8afc6);
    assign direct_output[73] = ^(direct_input & 128'h9a8a4ccb86cfbfdf242238bcf458f04a);
    assign direct_output[74] = ^(direct_input & 128'h351599970d9f7fbf49457178e9b1e195);
    assign direct_output[75] = ^(direct_input & 128'h6a2b322e1b3eff7f928ae3f0d263c22a);
    assign direct_output[76] = ^(direct_input & 128'hd456655d377dfeff2515c6e1a4c78455);
    assign direct_output[77] = ^(direct_input & 128'ha8adcbba6efbfdfe4a2b8cc2488f09aa);
    assign direct_output[78] = ^(direct_input & 128'h26225332a1b36fb789480eef3dd6bc92);
    assign direct_output[79] = ^(direct_input & 128'h3b3c62233e224a250e8f0bb5d664d7e3);
    assign direct_output[80] = ^(direct_input & 128'hcb67c53a47ac3c02682e69eb4b0c7476);
    assign direct_output[81] = ^(direct_input & 128'h5ca84e4fc9f44506b873ba3ddd149c9a);
    assign direct_output[82] = ^(direct_input & 128'hb9509d9e93e98a0c70e7747abb283935);
    assign direct_output[83] = ^(direct_input & 128'h73a13a3d26d21518e0cee8f47751726a);
    assign direct_output[84] = ^(direct_input & 128'he743757a4da42b30c19cd1e9efa2e4d4);
    assign direct_output[85] = ^(direct_input & 128'hce86ebf49a4856618339a3d2de44c9a8);
    assign direct_output[86] = ^(direct_input & 128'h576a13d3723d91c16e5c2e4ff785e726);
    assign direct_output[87] = ^(direct_input & 128'h65b3e29da3d61e81b4973475a506ba3b);
    assign direct_output[88] = ^(direct_input & 128'hb0636a0b33c6c94fe59374075cd2a1cb);
    assign direct_output[89] = ^(direct_input & 128'hd0a4be1c554a5ad12fb59c08e576e25c);
    assign direct_output[90] = ^(direct_input & 128'ha0487c38aa95b5a35e6b3910caecc5b9);
    assign direct_output[91] = ^(direct_input & 128'h4091f871542a6b47bdd7722094d98b73);
    assign direct_output[92] = ^(direct_input & 128'h8122f1e3a955d78e7bafe44129b316e7);
    assign direct_output[93] = ^(direct_input & 128'h0245e2c653aaaf1df75fc98252672cce);
    assign direct_output[94] = ^(direct_input & 128'hb4e9af87959296740b2de702f91df857);
    assign direct_output[95] = ^(direct_input & 128'hd8b1350519e3e4a7f2c9ba03aee95065);
    assign direct_output[96] = ^(direct_input & 128'h7fc7fc6863b4ffb02309a207250cd7b0);
    assign direct_output[97] = ^(direct_input & 128'h804805b8a4dc01d0651ae6086f1478d0);
    assign direct_output[98] = ^(direct_input & 128'h01910b7048b803a0cb34cd10df28f0a0);
    assign direct_output[99] = ^(direct_input & 128'h032217e09170074097699b20bf51e140);
    assign direct_output[100] = ^(direct_input & 128'h07452fc122e00f812ed336417fa2c281);
    assign direct_output[101] = ^(direct_input & 128'h0f8a5e8345c11f025da76d82ff448402);
    assign direct_output[102] = ^(direct_input & 128'h60d2416ee937c0b499467902db85deb4);
    assign direct_output[103] = ^(direct_input & 128'hbf637eb4b1da7fd81184510392066bd8);
    assign direct_output[104] = ^(direct_input & 128'h9927fed450a4cfbb76f9e3929a0cee7f);
    assign direct_output[105] = ^(direct_input & 128'hab69037cf1ec50cc9a0b25b7af143380);
    assign direct_output[106] = ^(direct_input & 128'h57d307f8e2d9a19835174a6f5f286601);
    assign direct_output[107] = ^(direct_input & 128'haea70ff1c5b343316a2f95dfbe51cc03);
    assign direct_output[108] = ^(direct_input & 128'h5c4f1fe28b678662d45e2abf7ca29807);
    assign direct_output[109] = ^(direct_input & 128'hb99e3fc516cf0dc4a8bd557ff844310f);
    assign direct_output[110] = ^(direct_input & 128'hea1a805f7c3bd4332682496d6b858c60);
    assign direct_output[111] = ^(direct_input & 128'h4c13ff6aa8d267dd3bfc71494d06f7bf);
    assign direct_output[112] = ^(direct_input & 128'h7daabef9173022f2601c213366ba2599);
    assign direct_output[113] = ^(direct_input & 128'h86fec20b38516717a0246355aace6fab);
    assign direct_output[114] = ^(direct_input & 128'h0dfd841771a2cf2f4049c7aa549cdf57);
    assign direct_output[115] = ^(direct_input & 128'h1bfa092fe3449f5e81928f54a939bfae);
    assign direct_output[116] = ^(direct_input & 128'h37f5135ec6893ebd02251ea953727f5c);
    assign direct_output[117] = ^(direct_input & 128'h6eea27bd8c127d7b044a3c53a6e4ffb9);
    assign direct_output[118] = ^(direct_input & 128'ha17ff0820e14d905688958952a73dbea);
    assign direct_output[119] = ^(direct_input & 128'h3e555ffc0b1891f9b00e9019335d924c);
    assign direct_output[120] = ^(direct_input & 128'hbe0df7703b178f0d61143801b4968d7d);
    assign direct_output[121] = ^(direct_input & 128'hc21619904d389116a23c4902dcbb9786);
    assign direct_output[122] = ^(direct_input & 128'h842c33219a71222c44799204b8772e0d);
    assign direct_output[123] = ^(direct_input & 128'h0959664235e3455989f3250870ef5d1b);
    assign direct_output[124] = ^(direct_input & 128'h13b2cc856ac68ab212e64a10e0deba37);
    assign direct_output[125] = ^(direct_input & 128'h2764980ad48c156424cd9520c1bc746e);
    assign direct_output[126] = ^(direct_input & 128'hf0c5c664930ea4c5288f124037ee65a1);
    assign direct_output[127] = ^(direct_input & 128'h5f867bb81d0bc786300a1c80da4b463e);

endmodule
