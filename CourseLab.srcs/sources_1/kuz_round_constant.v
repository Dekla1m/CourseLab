`timescale 1ns / 1ps

// Комбинационная таблица констант Ci = L(Vec128(i)) для шагов F с 1 по 32.
// Значения вычислены скриптом work/generate_kuz_round_constants.py.
// Индекс вне диапазона даёт ноль.

module kuz_round_constant (
    input       [5:0]   iteration_index,
    output reg  [127:0] iteration_constant
);

    always @(*) begin
        case (iteration_index)
            6'd1:  iteration_constant = 128'h6ea276726c487ab85d27bd10dd849401;
            6'd2:  iteration_constant = 128'hdc87ece4d890f4b3ba4eb92079cbeb02;
            6'd3:  iteration_constant = 128'hb2259a96b4d88e0be7690430a44f7f03;
            6'd4:  iteration_constant = 128'h7bcd1b0b73e32ba5b79cb140f2551504;
            6'd5:  iteration_constant = 128'h156f6d791fab511deabb0c502fd18105;
            6'd6:  iteration_constant = 128'ha74af7efab73df160dd208608b9efe06;
            6'd7:  iteration_constant = 128'hc9e8819dc73ba5ae50f5b570561a6a07;
            6'd8:  iteration_constant = 128'hf6593616e6055689adfba18027aa2a08;

            6'd9:  iteration_constant = 128'h98fb40648a4d2c31f0dc1c90fa2ebe09;
            6'd10: iteration_constant = 128'h2adedaf23e95a23a17b518a05e61c10a;
            6'd11: iteration_constant = 128'h447cac8052ddd8824a92a5b083e5550b;
            6'd12: iteration_constant = 128'h8d942d1d95e67d2c1a6710c0d5ff3f0c;
            6'd13: iteration_constant = 128'he3365b6ff9ae07944740add0087bab0d;
            6'd14: iteration_constant = 128'h5113c1f94d76899fa029a9e0ac34d40e;
            6'd15: iteration_constant = 128'h3fb1b78b213ef327fd0e14f071b0400f;
            6'd16: iteration_constant = 128'h2fb26c2c0f0aacd1993581c34e975410;

            6'd17: iteration_constant = 128'h41101a5e6342d669c4123cd39313c011;
            6'd18: iteration_constant = 128'hf33580c8d79a5862237b38e3375cbf12;
            6'd19: iteration_constant = 128'h9d97f6babbd222da7e5c85f3ead82b13;
            6'd20: iteration_constant = 128'h547f77277ce987742ea93083bcc24114;
            6'd21: iteration_constant = 128'h3add015510a1fdcc738e8d936146d515;
            6'd22: iteration_constant = 128'h88f89bc3a47973c794e789a3c509aa16;
            6'd23: iteration_constant = 128'he65aedb1c831097fc9c034b3188d3e17;
            6'd24: iteration_constant = 128'hd9eb5a3ae90ffa5834ce2043693d7e18;

            6'd25: iteration_constant = 128'hb7492c48854780e069e99d53b4b9ea19;
            6'd26: iteration_constant = 128'h056cb6de319f0eeb8e80996310f6951a;
            6'd27: iteration_constant = 128'h6bcec0ac5dd77453d3a72473cd72011b;
            6'd28: iteration_constant = 128'ha22641319aecd1fd835291039b686b1c;
            6'd29: iteration_constant = 128'hcc843743f6a4ab45de752c1346ecff1d;
            6'd30: iteration_constant = 128'h7ea1add5427c254e391c2823e2a3801e;
            6'd31: iteration_constant = 128'h1003dba72e345ff6643b95333f27141f;
            6'd32: iteration_constant = 128'h5ea7d8581e149b61f16ac1459ceda820;

            default: iteration_constant = 128'b0;
        endcase
    end

endmodule