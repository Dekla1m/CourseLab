`timescale 1ns / 1ps

// ѕолное преобразование L в виде матрицы 128 на 128 над GF(2).
// —трока матрицы задаЄт маску входных битов дл€ одного выходного бита.
// ћаска выбирает слагаемые, а XOR-редукци€ складывает их по модулю 2.

module l_matrix_comb (
    input  wire [127:0] data_input,
    output wire [127:0] data_output
);

    // Ѕиты результата 0Ц31.
    assign data_output[0]    = ^(data_input & 128'hc6d877b05ada015301da5ab077d8c601);
    assign data_output[1]    = ^(data_input & 128'h4a6898d0ef6e02f5026eefd098684a02);
    assign data_output[2]    = ^(data_input & 128'h95d031a0dedc04ea04dcdea031d09504);
    assign data_output[3]    = ^(data_input & 128'h2aa06240bcb808d508b8bc4062a02a08);
    assign data_output[4]    = ^(data_input & 128'h5540c481787010ab10707881c4405510);
    assign data_output[5]    = ^(data_input & 128'haa818802f0e0205720e0f0028881aa20);
    assign data_output[6]    = ^(data_input & 128'h92da66b4bb1b40fd401bbbb466da9240);
    assign data_output[7]    = ^(data_input & 128'he36cbbd82ded80a980ed2dd8bb6ce380);
    assign data_output[8]    = ^(data_input & 128'h7679c4467d45954a1c1e176bacc8afc6);
    assign data_output[9]    = ^(data_input & 128'h9a8a4ccb86cfbfdf242238bcf458f04a);
    assign data_output[10]   = ^(data_input & 128'h351599970d9f7fbf49457178e9b1e195);
    assign data_output[11]   = ^(data_input & 128'h6a2b322e1b3eff7f928ae3f0d263c22a);
    assign data_output[12]   = ^(data_input & 128'hd456655d377dfeff2515c6e1a4c78455);
    assign data_output[13]   = ^(data_input & 128'ha8adcbba6efbfdfe4a2b8cc2488f09aa);
    assign data_output[14]   = ^(data_input & 128'h26225332a1b36fb789480eef3dd6bc92);
    assign data_output[15]   = ^(data_input & 128'h3b3c62233e224a250e8f0bb5d664d7e3);
    assign data_output[16]   = ^(data_input & 128'hcb67c53a47ac3c02682e69eb4b0c7476);
    assign data_output[17]   = ^(data_input & 128'h5ca84e4fc9f44506b873ba3ddd149c9a);
    assign data_output[18]   = ^(data_input & 128'hb9509d9e93e98a0c70e7747abb283935);
    assign data_output[19]   = ^(data_input & 128'h73a13a3d26d21518e0cee8f47751726a);
    assign data_output[20]   = ^(data_input & 128'he743757a4da42b30c19cd1e9efa2e4d4);
    assign data_output[21]   = ^(data_input & 128'hce86ebf49a4856618339a3d2de44c9a8);
    assign data_output[22]   = ^(data_input & 128'h576a13d3723d91c16e5c2e4ff785e726);
    assign data_output[23]   = ^(data_input & 128'h65b3e29da3d61e81b4973475a506ba3b);
    assign data_output[24]   = ^(data_input & 128'hb0636a0b33c6c94fe59374075cd2a1cb);
    assign data_output[25]   = ^(data_input & 128'hd0a4be1c554a5ad12fb59c08e576e25c);
    assign data_output[26]   = ^(data_input & 128'ha0487c38aa95b5a35e6b3910caecc5b9);
    assign data_output[27]   = ^(data_input & 128'h4091f871542a6b47bdd7722094d98b73);
    assign data_output[28]   = ^(data_input & 128'h8122f1e3a955d78e7bafe44129b316e7);
    assign data_output[29]   = ^(data_input & 128'h0245e2c653aaaf1df75fc98252672cce);
    assign data_output[30]   = ^(data_input & 128'hb4e9af87959296740b2de702f91df857);
    assign data_output[31]   = ^(data_input & 128'hd8b1350519e3e4a7f2c9ba03aee95065);

    // Ѕиты результата 32Ц63.
    assign data_output[32]   = ^(data_input & 128'h7fc7fc6863b4ffb02309a207250cd7b0);
    assign data_output[33]   = ^(data_input & 128'h804805b8a4dc01d0651ae6086f1478d0);
    assign data_output[34]   = ^(data_input & 128'h01910b7048b803a0cb34cd10df28f0a0);
    assign data_output[35]   = ^(data_input & 128'h032217e09170074097699b20bf51e140);
    assign data_output[36]   = ^(data_input & 128'h07452fc122e00f812ed336417fa2c281);
    assign data_output[37]   = ^(data_input & 128'h0f8a5e8345c11f025da76d82ff448402);
    assign data_output[38]   = ^(data_input & 128'h60d2416ee937c0b499467902db85deb4);
    assign data_output[39]   = ^(data_input & 128'hbf637eb4b1da7fd81184510392066bd8);
    assign data_output[40]   = ^(data_input & 128'h9927fed450a4cfbb76f9e3929a0cee7f);
    assign data_output[41]   = ^(data_input & 128'hab69037cf1ec50cc9a0b25b7af143380);
    assign data_output[42]   = ^(data_input & 128'h57d307f8e2d9a19835174a6f5f286601);
    assign data_output[43]   = ^(data_input & 128'haea70ff1c5b343316a2f95dfbe51cc03);
    assign data_output[44]   = ^(data_input & 128'h5c4f1fe28b678662d45e2abf7ca29807);
    assign data_output[45]   = ^(data_input & 128'hb99e3fc516cf0dc4a8bd557ff844310f);
    assign data_output[46]   = ^(data_input & 128'hea1a805f7c3bd4332682496d6b858c60);
    assign data_output[47]   = ^(data_input & 128'h4c13ff6aa8d267dd3bfc71494d06f7bf);
    assign data_output[48]   = ^(data_input & 128'h7daabef9173022f2601c213366ba2599);
    assign data_output[49]   = ^(data_input & 128'h86fec20b38516717a0246355aace6fab);
    assign data_output[50]   = ^(data_input & 128'h0dfd841771a2cf2f4049c7aa549cdf57);
    assign data_output[51]   = ^(data_input & 128'h1bfa092fe3449f5e81928f54a939bfae);
    assign data_output[52]   = ^(data_input & 128'h37f5135ec6893ebd02251ea953727f5c);
    assign data_output[53]   = ^(data_input & 128'h6eea27bd8c127d7b044a3c53a6e4ffb9);
    assign data_output[54]   = ^(data_input & 128'ha17ff0820e14d905688958952a73dbea);
    assign data_output[55]   = ^(data_input & 128'h3e555ffc0b1891f9b00e9019335d924c);
    assign data_output[56]   = ^(data_input & 128'hbe0df7703b178f0d61143801b4968d7d);
    assign data_output[57]   = ^(data_input & 128'hc21619904d389116a23c4902dcbb9786);
    assign data_output[58]   = ^(data_input & 128'h842c33219a71222c44799204b8772e0d);
    assign data_output[59]   = ^(data_input & 128'h0959664235e3455989f3250870ef5d1b);
    assign data_output[60]   = ^(data_input & 128'h13b2cc856ac68ab212e64a10e0deba37);
    assign data_output[61]   = ^(data_input & 128'h2764980ad48c156424cd9520c1bc746e);
    assign data_output[62]   = ^(data_input & 128'hf0c5c664930ea4c5288f124037ee65a1);
    assign data_output[63]   = ^(data_input & 128'h5f867bb81d0bc786300a1c80da4b463e);

    // Ѕиты результата 64Ц95.
    assign data_output[64]   = ^(data_input & 128'he4424c503ff8b3feaa4f29dfaa3894be);
    assign data_output[65]   = ^(data_input & 128'h2dc7d5f14109d403fed17b60fe49bdc2);
    assign data_output[66]   = ^(data_input & 128'h5a8fabe28213a807fda3f7c0fd927b84);
    assign data_output[67]   = ^(data_input & 128'hb51e57c50527500ffa47ee80fa25f709);
    assign data_output[68]   = ^(data_input & 128'h6b3cae8b0b4ea11ff58edd01f54aee13);
    assign data_output[69]   = ^(data_input & 128'hd7795c16179d433fea1dbb03ea95dd27);
    assign data_output[70]   = ^(data_input & 128'h4bb1f57c10c235807f745ed87f122ff0);
    assign data_output[71]   = ^(data_input & 128'h7221a6a81f7cd9ff55a7946f551cca5f);
    assign data_output[72]   = ^(data_input & 128'h0cab34f140791a43abe367645c73f0e4);
    assign data_output[73]   = ^(data_input & 128'h14fc5d13c18a2ec5fc25a8ace594112d);
    assign data_output[74]   = ^(data_input & 128'h28f9ba2783155d8bf94a5058ca29235a);
    assign data_output[75]   = ^(data_input & 128'h51f2744e062bba16f295a1b1945246b5);
    assign data_output[76]   = ^(data_input & 128'ha2e5e89d0c56742ce52a436329a58d6b);
    assign data_output[77]   = ^(data_input & 128'h44cad13a18ade859ca5586c7524b1ad7);
    assign data_output[78]   = ^(data_input & 128'h853f97847022cbf13f496aebf9e5c44b);
    assign data_output[79]   = ^(data_input & 128'h06d51af8a03c8da1d571b3b2aeb97872);
    assign data_output[80]   = ^(data_input & 128'h1444a2a01b7e4f94ef0306bc20805b0c);
    assign data_output[81]   = ^(data_input & 128'h3ccde6e02c82d1bd31040ac46181ed14);
    assign data_output[82]   = ^(data_input & 128'h799bcdc15905a37b62081488c302da28);
    assign data_output[83]   = ^(data_input & 128'hf3369b83b20b47f7c41028118704b451);
    assign data_output[84]   = ^(data_input & 128'he66d360664178eee882051230e0868a2);
    assign data_output[85]   = ^(data_input & 128'hcddb6d0cc82f1ddd1141a2461c10d044);
    assign data_output[86]   = ^(data_input & 128'h8ff379b88b20742fcc81423118a0fb85);
    assign data_output[87]   = ^(data_input & 128'h0aa251d00d3fa7ca770183de10c0ad06);
    assign data_output[88]   = ^(data_input & 128'h8432553ad8e380ae17aa1a0175cbcc14);
    assign data_output[89]   = ^(data_input & 128'h8d57ff4f682581f238fe2e029e5c543c);
    assign data_output[90]   = ^(data_input & 128'h1aaefe9ed04a02e571fd5d043db9a979);
    assign data_output[91]   = ^(data_input & 128'h345cfd3da09504cae3faba087a7353f3);
    assign data_output[92]   = ^(data_input & 128'h69b9fa7a402a0894c6f57410f4e7a6e6);
    assign data_output[93]   = ^(data_input & 128'hd373f5f4815510298ceae820e9ce4ccd);
    assign data_output[94]   = ^(data_input & 128'h23d5bfd3da49a0fc0e7fcb40a757558f);
    assign data_output[95]   = ^(data_input & 128'hc2992a9d6c71c0570b558d803a65660a);

    // Ѕиты результата 96Ц127.
    assign data_output[96]   = ^(data_input & 128'h44e9b0a010b12a542e2bf20d41706284);
    assign data_output[97]   = ^(data_input & 128'hcd3bd0e030d27ffd737d1716c390a68d);
    assign data_output[98]   = ^(data_input & 128'h9b76a0c161a4fffae7fb2f2c87214c1a);
    assign data_output[99]   = ^(data_input & 128'h36ec4083c348fef5cef65e590e429934);
    assign data_output[100]  = ^(data_input & 128'h6dd981068791fdea9cedbdb21c853269);
    assign data_output[101]  = ^(data_input & 128'hdbb3020c0e22fad539da7b64380a65d3);
    assign data_output[102]  = ^(data_input & 128'hf38eb4b80cf4dfff5c9f05c53064a923);
    assign data_output[103]  = ^(data_input & 128'ha2f4d8d0085895aa9715f98620b831c2);
    assign data_output[104]  = ^(data_input & 128'heebaf704d4ed10396f35685527688344);
    assign data_output[105]  = ^(data_input & 128'h33ce190c7c37304bb05fb8ff69b885cd);
    assign data_output[106]  = ^(data_input & 128'h669c3318f86e619660be70fed3700a9b);
    assign data_output[107]  = ^(data_input & 128'hcc396630f1dcc32dc07ce0fda7e01436);
    assign data_output[108]  = ^(data_input & 128'h9872cc61e2b8875a80f8c1fa4fc1286d);
    assign data_output[109]  = ^(data_input & 128'h31e498c3c5700eb501f183f59e8351db);
    assign data_output[110]  = ^(data_input & 128'h8c73c6835f0d0c526cd76ebf1a6e21f3);
    assign data_output[111]  = ^(data_input & 128'hf75d7b026af6089cb79ab42a13b4c1a2);
    assign data_output[112]  = ^(data_input & 128'h94d89a8a060cd7a6db74be79f6ac6aee);
    assign data_output[113]  = ^(data_input & 128'hbd68af9f0a1478ea6c9cc28a1bf4be33);
    assign data_output[114]  = ^(data_input & 128'h7bd05f3e1428f0d5d839841537e97c66);
    assign data_output[115]  = ^(data_input & 128'hf7a0be7d2851e1abb072092b6ed2f8cc);
    assign data_output[116]  = ^(data_input & 128'hee407cfb51a2c25760e41356dca4f198);
    assign data_output[117]  = ^(data_input & 128'hdd81f8f6a24484aec0c927adb848e231);
    assign data_output[118]  = ^(data_input & 128'h2fda6b674285defa5be7f022863daf8c);
    assign data_output[119]  = ^(data_input & 128'hca6c4d4583066b536dba5f3cfbd635f7);
    assign data_output[120]  = ^(data_input & 128'hfb66c4ff87963233e0fff20fe296cd94);
    assign data_output[121]  = ^(data_input & 128'h0daa4c0189bb57552101171027bb56bd);
    assign data_output[122]  = ^(data_input & 128'h1b5499031277aeaa42032f204e77ad7b);
    assign data_output[123]  = ^(data_input & 128'h37a9320724ef5c5485075e419def5bf7);
    assign data_output[124]  = ^(data_input & 128'h6e53650f49deb9a90a0fbd823adeb6ee);
    assign data_output[125]  = ^(data_input & 128'hdca6cb1f92bc7353141f7b0575bc6cdd);
    assign data_output[126]  = ^(data_input & 128'h432a53c0a2eed595c8c0050409ee152f);
    assign data_output[127]  = ^(data_input & 128'h7d33627fc34b9919707ff907f14be6ca);

endmodule
