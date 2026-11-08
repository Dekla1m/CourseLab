`timescale 1ns / 1ps

// Комбинационный раунд: XOR с ключом, 16 параллельных подстановок S и матрица L.
// Старший байт расположен в битах [127:120]. Каждый байт остаётся на своей позиции.

module kuz_lsx_matrix_comb (
    input wire [127:0] data_input,
                       key_input,

    output wire [127:0] data_output
);

    wire [127:0] data_after_key_xor = data_input ^ key_input;
    wire [127:0] data_after_substitution;

    // Таблица подстановки одного байта. Неопределённый вход распространяет X в симуляции.
    function automatic [7:0] substitute_byte(input [7:0] byte_input);
        begin
            case (byte_input)
                8'h00: substitute_byte = 8'hfc;
                8'h01: substitute_byte = 8'hee;
                8'h02: substitute_byte = 8'hdd;
                8'h03: substitute_byte = 8'h11;
                8'h04: substitute_byte = 8'hcf;
                8'h05: substitute_byte = 8'h6e;
                8'h06: substitute_byte = 8'h31;
                8'h07: substitute_byte = 8'h16;
                8'h08: substitute_byte = 8'hfb;
                8'h09: substitute_byte = 8'hc4;
                8'h0a: substitute_byte = 8'hfa;
                8'h0b: substitute_byte = 8'hda;
                8'h0c: substitute_byte = 8'h23;
                8'h0d: substitute_byte = 8'hc5;
                8'h0e: substitute_byte = 8'h04;
                8'h0f: substitute_byte = 8'h4d;
                8'h10: substitute_byte = 8'he9;
                8'h11: substitute_byte = 8'h77;
                8'h12: substitute_byte = 8'hf0;
                8'h13: substitute_byte = 8'hdb;
                8'h14: substitute_byte = 8'h93;
                8'h15: substitute_byte = 8'h2e;
                8'h16: substitute_byte = 8'h99;
                8'h17: substitute_byte = 8'hba;
                8'h18: substitute_byte = 8'h17;
                8'h19: substitute_byte = 8'h36;
                8'h1a: substitute_byte = 8'hf1;
                8'h1b: substitute_byte = 8'hbb;
                8'h1c: substitute_byte = 8'h14;
                8'h1d: substitute_byte = 8'hcd;
                8'h1e: substitute_byte = 8'h5f;
                8'h1f: substitute_byte = 8'hc1;
                8'h20: substitute_byte = 8'hf9;
                8'h21: substitute_byte = 8'h18;
                8'h22: substitute_byte = 8'h65;
                8'h23: substitute_byte = 8'h5a;
                8'h24: substitute_byte = 8'he2;
                8'h25: substitute_byte = 8'h5c;
                8'h26: substitute_byte = 8'hef;
                8'h27: substitute_byte = 8'h21;
                8'h28: substitute_byte = 8'h81;
                8'h29: substitute_byte = 8'h1c;
                8'h2a: substitute_byte = 8'h3c;
                8'h2b: substitute_byte = 8'h42;
                8'h2c: substitute_byte = 8'h8b;
                8'h2d: substitute_byte = 8'h01;
                8'h2e: substitute_byte = 8'h8e;
                8'h2f: substitute_byte = 8'h4f;
                8'h30: substitute_byte = 8'h05;
                8'h31: substitute_byte = 8'h84;
                8'h32: substitute_byte = 8'h02;
                8'h33: substitute_byte = 8'hae;
                8'h34: substitute_byte = 8'he3;
                8'h35: substitute_byte = 8'h6a;
                8'h36: substitute_byte = 8'h8f;
                8'h37: substitute_byte = 8'ha0;
                8'h38: substitute_byte = 8'h06;
                8'h39: substitute_byte = 8'h0b;
                8'h3a: substitute_byte = 8'hed;
                8'h3b: substitute_byte = 8'h98;
                8'h3c: substitute_byte = 8'h7f;
                8'h3d: substitute_byte = 8'hd4;
                8'h3e: substitute_byte = 8'hd3;
                8'h3f: substitute_byte = 8'h1f;
                8'h40: substitute_byte = 8'heb;
                8'h41: substitute_byte = 8'h34;
                8'h42: substitute_byte = 8'h2c;
                8'h43: substitute_byte = 8'h51;
                8'h44: substitute_byte = 8'hea;
                8'h45: substitute_byte = 8'hc8;
                8'h46: substitute_byte = 8'h48;
                8'h47: substitute_byte = 8'hab;
                8'h48: substitute_byte = 8'hf2;
                8'h49: substitute_byte = 8'h2a;
                8'h4a: substitute_byte = 8'h68;
                8'h4b: substitute_byte = 8'ha2;
                8'h4c: substitute_byte = 8'hfd;
                8'h4d: substitute_byte = 8'h3a;
                8'h4e: substitute_byte = 8'hce;
                8'h4f: substitute_byte = 8'hcc;
                8'h50: substitute_byte = 8'hb5;
                8'h51: substitute_byte = 8'h70;
                8'h52: substitute_byte = 8'h0e;
                8'h53: substitute_byte = 8'h56;
                8'h54: substitute_byte = 8'h08;
                8'h55: substitute_byte = 8'h0c;
                8'h56: substitute_byte = 8'h76;
                8'h57: substitute_byte = 8'h12;
                8'h58: substitute_byte = 8'hbf;
                8'h59: substitute_byte = 8'h72;
                8'h5a: substitute_byte = 8'h13;
                8'h5b: substitute_byte = 8'h47;
                8'h5c: substitute_byte = 8'h9c;
                8'h5d: substitute_byte = 8'hb7;
                8'h5e: substitute_byte = 8'h5d;
                8'h5f: substitute_byte = 8'h87;
                8'h60: substitute_byte = 8'h15;
                8'h61: substitute_byte = 8'ha1;
                8'h62: substitute_byte = 8'h96;
                8'h63: substitute_byte = 8'h29;
                8'h64: substitute_byte = 8'h10;
                8'h65: substitute_byte = 8'h7b;
                8'h66: substitute_byte = 8'h9a;
                8'h67: substitute_byte = 8'hc7;
                8'h68: substitute_byte = 8'hf3;
                8'h69: substitute_byte = 8'h91;
                8'h6a: substitute_byte = 8'h78;
                8'h6b: substitute_byte = 8'h6f;
                8'h6c: substitute_byte = 8'h9d;
                8'h6d: substitute_byte = 8'h9e;
                8'h6e: substitute_byte = 8'hb2;
                8'h6f: substitute_byte = 8'hb1;
                8'h70: substitute_byte = 8'h32;
                8'h71: substitute_byte = 8'h75;
                8'h72: substitute_byte = 8'h19;
                8'h73: substitute_byte = 8'h3d;
                8'h74: substitute_byte = 8'hff;
                8'h75: substitute_byte = 8'h35;
                8'h76: substitute_byte = 8'h8a;
                8'h77: substitute_byte = 8'h7e;
                8'h78: substitute_byte = 8'h6d;
                8'h79: substitute_byte = 8'h54;
                8'h7a: substitute_byte = 8'hc6;
                8'h7b: substitute_byte = 8'h80;
                8'h7c: substitute_byte = 8'hc3;
                8'h7d: substitute_byte = 8'hbd;
                8'h7e: substitute_byte = 8'h0d;
                8'h7f: substitute_byte = 8'h57;
                8'h80: substitute_byte = 8'hdf;
                8'h81: substitute_byte = 8'hf5;
                8'h82: substitute_byte = 8'h24;
                8'h83: substitute_byte = 8'ha9;
                8'h84: substitute_byte = 8'h3e;
                8'h85: substitute_byte = 8'ha8;
                8'h86: substitute_byte = 8'h43;
                8'h87: substitute_byte = 8'hc9;
                8'h88: substitute_byte = 8'hd7;
                8'h89: substitute_byte = 8'h79;
                8'h8a: substitute_byte = 8'hd6;
                8'h8b: substitute_byte = 8'hf6;
                8'h8c: substitute_byte = 8'h7c;
                8'h8d: substitute_byte = 8'h22;
                8'h8e: substitute_byte = 8'hb9;
                8'h8f: substitute_byte = 8'h03;
                8'h90: substitute_byte = 8'he0;
                8'h91: substitute_byte = 8'h0f;
                8'h92: substitute_byte = 8'hec;
                8'h93: substitute_byte = 8'hde;
                8'h94: substitute_byte = 8'h7a;
                8'h95: substitute_byte = 8'h94;
                8'h96: substitute_byte = 8'hb0;
                8'h97: substitute_byte = 8'hbc;
                8'h98: substitute_byte = 8'hdc;
                8'h99: substitute_byte = 8'he8;
                8'h9a: substitute_byte = 8'h28;
                8'h9b: substitute_byte = 8'h50;
                8'h9c: substitute_byte = 8'h4e;
                8'h9d: substitute_byte = 8'h33;
                8'h9e: substitute_byte = 8'h0a;
                8'h9f: substitute_byte = 8'h4a;
                8'ha0: substitute_byte = 8'ha7;
                8'ha1: substitute_byte = 8'h97;
                8'ha2: substitute_byte = 8'h60;
                8'ha3: substitute_byte = 8'h73;
                8'ha4: substitute_byte = 8'h1e;
                8'ha5: substitute_byte = 8'h00;
                8'ha6: substitute_byte = 8'h62;
                8'ha7: substitute_byte = 8'h44;
                8'ha8: substitute_byte = 8'h1a;
                8'ha9: substitute_byte = 8'hb8;
                8'haa: substitute_byte = 8'h38;
                8'hab: substitute_byte = 8'h82;
                8'hac: substitute_byte = 8'h64;
                8'had: substitute_byte = 8'h9f;
                8'hae: substitute_byte = 8'h26;
                8'haf: substitute_byte = 8'h41;
                8'hb0: substitute_byte = 8'had;
                8'hb1: substitute_byte = 8'h45;
                8'hb2: substitute_byte = 8'h46;
                8'hb3: substitute_byte = 8'h92;
                8'hb4: substitute_byte = 8'h27;
                8'hb5: substitute_byte = 8'h5e;
                8'hb6: substitute_byte = 8'h55;
                8'hb7: substitute_byte = 8'h2f;
                8'hb8: substitute_byte = 8'h8c;
                8'hb9: substitute_byte = 8'ha3;
                8'hba: substitute_byte = 8'ha5;
                8'hbb: substitute_byte = 8'h7d;
                8'hbc: substitute_byte = 8'h69;
                8'hbd: substitute_byte = 8'hd5;
                8'hbe: substitute_byte = 8'h95;
                8'hbf: substitute_byte = 8'h3b;
                8'hc0: substitute_byte = 8'h07;
                8'hc1: substitute_byte = 8'h58;
                8'hc2: substitute_byte = 8'hb3;
                8'hc3: substitute_byte = 8'h40;
                8'hc4: substitute_byte = 8'h86;
                8'hc5: substitute_byte = 8'hac;
                8'hc6: substitute_byte = 8'h1d;
                8'hc7: substitute_byte = 8'hf7;
                8'hc8: substitute_byte = 8'h30;
                8'hc9: substitute_byte = 8'h37;
                8'hca: substitute_byte = 8'h6b;
                8'hcb: substitute_byte = 8'he4;
                8'hcc: substitute_byte = 8'h88;
                8'hcd: substitute_byte = 8'hd9;
                8'hce: substitute_byte = 8'he7;
                8'hcf: substitute_byte = 8'h89;
                8'hd0: substitute_byte = 8'he1;
                8'hd1: substitute_byte = 8'h1b;
                8'hd2: substitute_byte = 8'h83;
                8'hd3: substitute_byte = 8'h49;
                8'hd4: substitute_byte = 8'h4c;
                8'hd5: substitute_byte = 8'h3f;
                8'hd6: substitute_byte = 8'hf8;
                8'hd7: substitute_byte = 8'hfe;
                8'hd8: substitute_byte = 8'h8d;
                8'hd9: substitute_byte = 8'h53;
                8'hda: substitute_byte = 8'haa;
                8'hdb: substitute_byte = 8'h90;
                8'hdc: substitute_byte = 8'hca;
                8'hdd: substitute_byte = 8'hd8;
                8'hde: substitute_byte = 8'h85;
                8'hdf: substitute_byte = 8'h61;
                8'he0: substitute_byte = 8'h20;
                8'he1: substitute_byte = 8'h71;
                8'he2: substitute_byte = 8'h67;
                8'he3: substitute_byte = 8'ha4;
                8'he4: substitute_byte = 8'h2d;
                8'he5: substitute_byte = 8'h2b;
                8'he6: substitute_byte = 8'h09;
                8'he7: substitute_byte = 8'h5b;
                8'he8: substitute_byte = 8'hcb;
                8'he9: substitute_byte = 8'h9b;
                8'hea: substitute_byte = 8'h25;
                8'heb: substitute_byte = 8'hd0;
                8'hec: substitute_byte = 8'hbe;
                8'hed: substitute_byte = 8'he5;
                8'hee: substitute_byte = 8'h6c;
                8'hef: substitute_byte = 8'h52;
                8'hf0: substitute_byte = 8'h59;
                8'hf1: substitute_byte = 8'ha6;
                8'hf2: substitute_byte = 8'h74;
                8'hf3: substitute_byte = 8'hd2;
                8'hf4: substitute_byte = 8'he6;
                8'hf5: substitute_byte = 8'hf4;
                8'hf6: substitute_byte = 8'hb4;
                8'hf7: substitute_byte = 8'hc0;
                8'hf8: substitute_byte = 8'hd1;
                8'hf9: substitute_byte = 8'h66;
                8'hfa: substitute_byte = 8'haf;
                8'hfb: substitute_byte = 8'hc2;
                8'hfc: substitute_byte = 8'h39;
                8'hfd: substitute_byte = 8'h4b;
                8'hfe: substitute_byte = 8'h63;
                8'hff: substitute_byte = 8'hb6;
                default: substitute_byte = 8'hxx;
            endcase
        end
    endfunction


    // Фиксированный срез каждого экземпляра сохраняет порядок байтов.
    genvar byte_index;
    generate
        for (byte_index = 0; byte_index < 16; byte_index = byte_index + 1) begin : byte_substitutions
            assign data_after_substitution[8 * byte_index +: 8] =
                substitute_byte(data_after_key_xor[8 * byte_index +: 8]);
        end
    endgenerate


    l_matrix_comb l_transform (
        .data_input(data_after_substitution),
        .data_output(data_output)
    );

endmodule
