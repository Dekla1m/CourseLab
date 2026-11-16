`timescale 1ns / 1ps

// Один обратный раунд. Сначала XOR с Ki, затем L в обратном направлении и S-1.
// Разрешение фиксирует результат на фронте. Между запусками результат удерживается.

module data_inverse_matrix_onecycle (
    input               clk,
    input               rst,
    input               data_round_enable,

    input       [127:0] data_input,
    input       [127:0] key_input,

    output reg  [127:0] data_output,
    output reg          data_round_done
);

    wire [127:0] data_after_key_xor = data_input ^ key_input;
    wire [127:0] data_after_inverse_l;
    wire [127:0] data_after_inverse_s;

    // ========== Комбинационный обратный раунд ==========

    l_inverse_matrix_comb inverse_linear_transform (
        .data_input(data_after_key_xor),
        .data_output(data_after_inverse_l)
    );

    kuz_inverse_sbox_comb substitution (
        .data_input(data_after_inverse_l),
        .data_output(data_after_inverse_s)
    );


    always @(posedge clk) begin
        if (rst) begin
            data_output     <= 128'b0;
            data_round_done <= 1'b0;
        end else begin
            data_round_done <= data_round_enable;

            if (data_round_enable)
                data_output <= data_after_inverse_s;
        end
    end

endmodule


// Обратная подстановка S-1. Фиксированные срезы сохраняют порядок байтов.

module kuz_inverse_sbox_comb (
    input  [127:0] data_input,
    output [127:0] data_output
);

    // Неопределённое значение байта распространяет X в симуляции.
    function automatic [7:0] inverse_substitute_byte;
        input [7:0] byte_input;
        begin
            case (byte_input)
                8'h00: inverse_substitute_byte = 8'ha5;
                8'h01: inverse_substitute_byte = 8'h2d;
                8'h02: inverse_substitute_byte = 8'h32;
                8'h03: inverse_substitute_byte = 8'h8f;
                8'h04: inverse_substitute_byte = 8'h0e;
                8'h05: inverse_substitute_byte = 8'h30;
                8'h06: inverse_substitute_byte = 8'h38;
                8'h07: inverse_substitute_byte = 8'hc0;
                8'h08: inverse_substitute_byte = 8'h54;
                8'h09: inverse_substitute_byte = 8'he6;
                8'h0a: inverse_substitute_byte = 8'h9e;
                8'h0b: inverse_substitute_byte = 8'h39;
                8'h0c: inverse_substitute_byte = 8'h55;
                8'h0d: inverse_substitute_byte = 8'h7e;
                8'h0e: inverse_substitute_byte = 8'h52;
                8'h0f: inverse_substitute_byte = 8'h91;
                8'h10: inverse_substitute_byte = 8'h64;
                8'h11: inverse_substitute_byte = 8'h03;
                8'h12: inverse_substitute_byte = 8'h57;
                8'h13: inverse_substitute_byte = 8'h5a;
                8'h14: inverse_substitute_byte = 8'h1c;
                8'h15: inverse_substitute_byte = 8'h60;
                8'h16: inverse_substitute_byte = 8'h07;
                8'h17: inverse_substitute_byte = 8'h18;
                8'h18: inverse_substitute_byte = 8'h21;
                8'h19: inverse_substitute_byte = 8'h72;
                8'h1a: inverse_substitute_byte = 8'ha8;
                8'h1b: inverse_substitute_byte = 8'hd1;
                8'h1c: inverse_substitute_byte = 8'h29;
                8'h1d: inverse_substitute_byte = 8'hc6;
                8'h1e: inverse_substitute_byte = 8'ha4;
                8'h1f: inverse_substitute_byte = 8'h3f;
                8'h20: inverse_substitute_byte = 8'he0;
                8'h21: inverse_substitute_byte = 8'h27;
                8'h22: inverse_substitute_byte = 8'h8d;
                8'h23: inverse_substitute_byte = 8'h0c;
                8'h24: inverse_substitute_byte = 8'h82;
                8'h25: inverse_substitute_byte = 8'hea;
                8'h26: inverse_substitute_byte = 8'hae;
                8'h27: inverse_substitute_byte = 8'hb4;
                8'h28: inverse_substitute_byte = 8'h9a;
                8'h29: inverse_substitute_byte = 8'h63;
                8'h2a: inverse_substitute_byte = 8'h49;
                8'h2b: inverse_substitute_byte = 8'he5;
                8'h2c: inverse_substitute_byte = 8'h42;
                8'h2d: inverse_substitute_byte = 8'he4;
                8'h2e: inverse_substitute_byte = 8'h15;
                8'h2f: inverse_substitute_byte = 8'hb7;
                8'h30: inverse_substitute_byte = 8'hc8;
                8'h31: inverse_substitute_byte = 8'h06;
                8'h32: inverse_substitute_byte = 8'h70;
                8'h33: inverse_substitute_byte = 8'h9d;
                8'h34: inverse_substitute_byte = 8'h41;
                8'h35: inverse_substitute_byte = 8'h75;
                8'h36: inverse_substitute_byte = 8'h19;
                8'h37: inverse_substitute_byte = 8'hc9;
                8'h38: inverse_substitute_byte = 8'haa;
                8'h39: inverse_substitute_byte = 8'hfc;
                8'h3a: inverse_substitute_byte = 8'h4d;
                8'h3b: inverse_substitute_byte = 8'hbf;
                8'h3c: inverse_substitute_byte = 8'h2a;
                8'h3d: inverse_substitute_byte = 8'h73;
                8'h3e: inverse_substitute_byte = 8'h84;
                8'h3f: inverse_substitute_byte = 8'hd5;
                8'h40: inverse_substitute_byte = 8'hc3;
                8'h41: inverse_substitute_byte = 8'haf;
                8'h42: inverse_substitute_byte = 8'h2b;
                8'h43: inverse_substitute_byte = 8'h86;
                8'h44: inverse_substitute_byte = 8'ha7;
                8'h45: inverse_substitute_byte = 8'hb1;
                8'h46: inverse_substitute_byte = 8'hb2;
                8'h47: inverse_substitute_byte = 8'h5b;
                8'h48: inverse_substitute_byte = 8'h46;
                8'h49: inverse_substitute_byte = 8'hd3;
                8'h4a: inverse_substitute_byte = 8'h9f;
                8'h4b: inverse_substitute_byte = 8'hfd;
                8'h4c: inverse_substitute_byte = 8'hd4;
                8'h4d: inverse_substitute_byte = 8'h0f;
                8'h4e: inverse_substitute_byte = 8'h9c;
                8'h4f: inverse_substitute_byte = 8'h2f;
                8'h50: inverse_substitute_byte = 8'h9b;
                8'h51: inverse_substitute_byte = 8'h43;
                8'h52: inverse_substitute_byte = 8'hef;
                8'h53: inverse_substitute_byte = 8'hd9;
                8'h54: inverse_substitute_byte = 8'h79;
                8'h55: inverse_substitute_byte = 8'hb6;
                8'h56: inverse_substitute_byte = 8'h53;
                8'h57: inverse_substitute_byte = 8'h7f;
                8'h58: inverse_substitute_byte = 8'hc1;
                8'h59: inverse_substitute_byte = 8'hf0;
                8'h5a: inverse_substitute_byte = 8'h23;
                8'h5b: inverse_substitute_byte = 8'he7;
                8'h5c: inverse_substitute_byte = 8'h25;
                8'h5d: inverse_substitute_byte = 8'h5e;
                8'h5e: inverse_substitute_byte = 8'hb5;
                8'h5f: inverse_substitute_byte = 8'h1e;
                8'h60: inverse_substitute_byte = 8'ha2;
                8'h61: inverse_substitute_byte = 8'hdf;
                8'h62: inverse_substitute_byte = 8'ha6;
                8'h63: inverse_substitute_byte = 8'hfe;
                8'h64: inverse_substitute_byte = 8'hac;
                8'h65: inverse_substitute_byte = 8'h22;
                8'h66: inverse_substitute_byte = 8'hf9;
                8'h67: inverse_substitute_byte = 8'he2;
                8'h68: inverse_substitute_byte = 8'h4a;
                8'h69: inverse_substitute_byte = 8'hbc;
                8'h6a: inverse_substitute_byte = 8'h35;
                8'h6b: inverse_substitute_byte = 8'hca;
                8'h6c: inverse_substitute_byte = 8'hee;
                8'h6d: inverse_substitute_byte = 8'h78;
                8'h6e: inverse_substitute_byte = 8'h05;
                8'h6f: inverse_substitute_byte = 8'h6b;
                8'h70: inverse_substitute_byte = 8'h51;
                8'h71: inverse_substitute_byte = 8'he1;
                8'h72: inverse_substitute_byte = 8'h59;
                8'h73: inverse_substitute_byte = 8'ha3;
                8'h74: inverse_substitute_byte = 8'hf2;
                8'h75: inverse_substitute_byte = 8'h71;
                8'h76: inverse_substitute_byte = 8'h56;
                8'h77: inverse_substitute_byte = 8'h11;
                8'h78: inverse_substitute_byte = 8'h6a;
                8'h79: inverse_substitute_byte = 8'h89;
                8'h7a: inverse_substitute_byte = 8'h94;
                8'h7b: inverse_substitute_byte = 8'h65;
                8'h7c: inverse_substitute_byte = 8'h8c;
                8'h7d: inverse_substitute_byte = 8'hbb;
                8'h7e: inverse_substitute_byte = 8'h77;
                8'h7f: inverse_substitute_byte = 8'h3c;
                8'h80: inverse_substitute_byte = 8'h7b;
                8'h81: inverse_substitute_byte = 8'h28;
                8'h82: inverse_substitute_byte = 8'hab;
                8'h83: inverse_substitute_byte = 8'hd2;
                8'h84: inverse_substitute_byte = 8'h31;
                8'h85: inverse_substitute_byte = 8'hde;
                8'h86: inverse_substitute_byte = 8'hc4;
                8'h87: inverse_substitute_byte = 8'h5f;
                8'h88: inverse_substitute_byte = 8'hcc;
                8'h89: inverse_substitute_byte = 8'hcf;
                8'h8a: inverse_substitute_byte = 8'h76;
                8'h8b: inverse_substitute_byte = 8'h2c;
                8'h8c: inverse_substitute_byte = 8'hb8;
                8'h8d: inverse_substitute_byte = 8'hd8;
                8'h8e: inverse_substitute_byte = 8'h2e;
                8'h8f: inverse_substitute_byte = 8'h36;
                8'h90: inverse_substitute_byte = 8'hdb;
                8'h91: inverse_substitute_byte = 8'h69;
                8'h92: inverse_substitute_byte = 8'hb3;
                8'h93: inverse_substitute_byte = 8'h14;
                8'h94: inverse_substitute_byte = 8'h95;
                8'h95: inverse_substitute_byte = 8'hbe;
                8'h96: inverse_substitute_byte = 8'h62;
                8'h97: inverse_substitute_byte = 8'ha1;
                8'h98: inverse_substitute_byte = 8'h3b;
                8'h99: inverse_substitute_byte = 8'h16;
                8'h9a: inverse_substitute_byte = 8'h66;
                8'h9b: inverse_substitute_byte = 8'he9;
                8'h9c: inverse_substitute_byte = 8'h5c;
                8'h9d: inverse_substitute_byte = 8'h6c;
                8'h9e: inverse_substitute_byte = 8'h6d;
                8'h9f: inverse_substitute_byte = 8'had;
                8'ha0: inverse_substitute_byte = 8'h37;
                8'ha1: inverse_substitute_byte = 8'h61;
                8'ha2: inverse_substitute_byte = 8'h4b;
                8'ha3: inverse_substitute_byte = 8'hb9;
                8'ha4: inverse_substitute_byte = 8'he3;
                8'ha5: inverse_substitute_byte = 8'hba;
                8'ha6: inverse_substitute_byte = 8'hf1;
                8'ha7: inverse_substitute_byte = 8'ha0;
                8'ha8: inverse_substitute_byte = 8'h85;
                8'ha9: inverse_substitute_byte = 8'h83;
                8'haa: inverse_substitute_byte = 8'hda;
                8'hab: inverse_substitute_byte = 8'h47;
                8'hac: inverse_substitute_byte = 8'hc5;
                8'had: inverse_substitute_byte = 8'hb0;
                8'hae: inverse_substitute_byte = 8'h33;
                8'haf: inverse_substitute_byte = 8'hfa;
                8'hb0: inverse_substitute_byte = 8'h96;
                8'hb1: inverse_substitute_byte = 8'h6f;
                8'hb2: inverse_substitute_byte = 8'h6e;
                8'hb3: inverse_substitute_byte = 8'hc2;
                8'hb4: inverse_substitute_byte = 8'hf6;
                8'hb5: inverse_substitute_byte = 8'h50;
                8'hb6: inverse_substitute_byte = 8'hff;
                8'hb7: inverse_substitute_byte = 8'h5d;
                8'hb8: inverse_substitute_byte = 8'ha9;
                8'hb9: inverse_substitute_byte = 8'h8e;
                8'hba: inverse_substitute_byte = 8'h17;
                8'hbb: inverse_substitute_byte = 8'h1b;
                8'hbc: inverse_substitute_byte = 8'h97;
                8'hbd: inverse_substitute_byte = 8'h7d;
                8'hbe: inverse_substitute_byte = 8'hec;
                8'hbf: inverse_substitute_byte = 8'h58;
                8'hc0: inverse_substitute_byte = 8'hf7;
                8'hc1: inverse_substitute_byte = 8'h1f;
                8'hc2: inverse_substitute_byte = 8'hfb;
                8'hc3: inverse_substitute_byte = 8'h7c;
                8'hc4: inverse_substitute_byte = 8'h09;
                8'hc5: inverse_substitute_byte = 8'h0d;
                8'hc6: inverse_substitute_byte = 8'h7a;
                8'hc7: inverse_substitute_byte = 8'h67;
                8'hc8: inverse_substitute_byte = 8'h45;
                8'hc9: inverse_substitute_byte = 8'h87;
                8'hca: inverse_substitute_byte = 8'hdc;
                8'hcb: inverse_substitute_byte = 8'he8;
                8'hcc: inverse_substitute_byte = 8'h4f;
                8'hcd: inverse_substitute_byte = 8'h1d;
                8'hce: inverse_substitute_byte = 8'h4e;
                8'hcf: inverse_substitute_byte = 8'h04;
                8'hd0: inverse_substitute_byte = 8'heb;
                8'hd1: inverse_substitute_byte = 8'hf8;
                8'hd2: inverse_substitute_byte = 8'hf3;
                8'hd3: inverse_substitute_byte = 8'h3e;
                8'hd4: inverse_substitute_byte = 8'h3d;
                8'hd5: inverse_substitute_byte = 8'hbd;
                8'hd6: inverse_substitute_byte = 8'h8a;
                8'hd7: inverse_substitute_byte = 8'h88;
                8'hd8: inverse_substitute_byte = 8'hdd;
                8'hd9: inverse_substitute_byte = 8'hcd;
                8'hda: inverse_substitute_byte = 8'h0b;
                8'hdb: inverse_substitute_byte = 8'h13;
                8'hdc: inverse_substitute_byte = 8'h98;
                8'hdd: inverse_substitute_byte = 8'h02;
                8'hde: inverse_substitute_byte = 8'h93;
                8'hdf: inverse_substitute_byte = 8'h80;
                8'he0: inverse_substitute_byte = 8'h90;
                8'he1: inverse_substitute_byte = 8'hd0;
                8'he2: inverse_substitute_byte = 8'h24;
                8'he3: inverse_substitute_byte = 8'h34;
                8'he4: inverse_substitute_byte = 8'hcb;
                8'he5: inverse_substitute_byte = 8'hed;
                8'he6: inverse_substitute_byte = 8'hf4;
                8'he7: inverse_substitute_byte = 8'hce;
                8'he8: inverse_substitute_byte = 8'h99;
                8'he9: inverse_substitute_byte = 8'h10;
                8'hea: inverse_substitute_byte = 8'h44;
                8'heb: inverse_substitute_byte = 8'h40;
                8'hec: inverse_substitute_byte = 8'h92;
                8'hed: inverse_substitute_byte = 8'h3a;
                8'hee: inverse_substitute_byte = 8'h01;
                8'hef: inverse_substitute_byte = 8'h26;
                8'hf0: inverse_substitute_byte = 8'h12;
                8'hf1: inverse_substitute_byte = 8'h1a;
                8'hf2: inverse_substitute_byte = 8'h48;
                8'hf3: inverse_substitute_byte = 8'h68;
                8'hf4: inverse_substitute_byte = 8'hf5;
                8'hf5: inverse_substitute_byte = 8'h81;
                8'hf6: inverse_substitute_byte = 8'h8b;
                8'hf7: inverse_substitute_byte = 8'hc7;
                8'hf8: inverse_substitute_byte = 8'hd6;
                8'hf9: inverse_substitute_byte = 8'h20;
                8'hfa: inverse_substitute_byte = 8'h0a;
                8'hfb: inverse_substitute_byte = 8'h08;
                8'hfc: inverse_substitute_byte = 8'h00;
                8'hfd: inverse_substitute_byte = 8'h4c;
                8'hfe: inverse_substitute_byte = 8'hd7;
                8'hff: inverse_substitute_byte = 8'h74;
                default: inverse_substitute_byte = 8'hxx;
            endcase
        end
    endfunction

    genvar byte_index;
    generate
        for (byte_index = 0; byte_index < 16; byte_index = byte_index + 1) begin : bytes
            assign data_output[8*byte_index +: 8] = inverse_substitute_byte(data_input[8*byte_index +: 8]);
        end
    endgenerate

endmodule
