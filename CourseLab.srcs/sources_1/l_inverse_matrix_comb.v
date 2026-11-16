`timescale 1ns / 1ps

// ќбратное преобразование L в виде матрицы 128 на 128 над GF(2).
// ћаски получены обращением пр€мой матрицы L и сверены с 16 обратными шагами R.
// —тарший байт остаЄтс€ в битах [127:120].

module l_inverse_matrix_comb (
    input  [127:0] data_input,
    output [127:0] data_output
);

    // Ѕиты результата 0Ц31.
    assign data_output[0]    = ^(data_input & 128'h94cd96e20ff2ffe033329687ffc466fb);
    assign data_output[1]    = ^(data_input & 128'hbd56bb27101701215557bb89014caa0d);
    assign data_output[2]    = ^(data_input & 128'h7bad774e202f0342aaae77120399541b);
    assign data_output[3]    = ^(data_input & 128'hf75bef9d415e0785545cef240732a937);
    assign data_output[4]    = ^(data_input & 128'heeb6de3a82bd0f0aa9b9de490f65536e);
    assign data_output[5]    = ^(data_input & 128'hdd6cbc75057b1f145373bc921fcba6dc);
    assign data_output[6]    = ^(data_input & 128'h2f15ee090405c0c895d5eea2c0532a43);
    assign data_output[7]    = ^(data_input & 128'hcae64bf107f97f7019994bc37f62337d);
    assign data_output[8]    = ^(data_input & 128'hee6aacf679be74dba6d70c068a9ad894);
    assign data_output[9]    = ^(data_input & 128'h33bef41b8ac29c6cea78140a9faf68bd);
    assign data_output[10]   = ^(data_input & 128'h667ce937158439d8d5f028143e5fd07b);
    assign data_output[11]   = ^(data_input & 128'hccf8d26e2b0972b0abe151287dbea0f7);
    assign data_output[12]   = ^(data_input & 128'h98f1a4dc5613e46057c2a251fb7c40ee);
    assign data_output[13]   = ^(data_input & 128'h31e248b8ad27c9c0ae8444a2f6f881dd);
    assign data_output[14]   = ^(data_input & 128'h8caf3d8622f0e75bfade8542676bda2f);
    assign data_output[15]   = ^(data_input & 128'hf735d6fb3c5fba6d536b0683454d6cca);
    assign data_output[16]   = ^(data_input & 128'h448368275568356f3910edd404f7baee);
    assign data_output[17]   = ^(data_input & 128'hcd85b869ffb85fb04b30377c0c19ce33);
    assign data_output[18]   = ^(data_input & 128'h9b0a70d3fe70be6096616ef818339c66);
    assign data_output[19]   = ^(data_input & 128'h3614e0a7fde07cc02dc3dcf1306639cc);
    assign data_output[20]   = ^(data_input & 128'h6d28c14ffac1f8805a87b8e261cc7298);
    assign data_output[21]   = ^(data_input & 128'hdb51839ef583f101b50e70c5c398e431);
    assign data_output[22]   = ^(data_input & 128'hf3216e1abf6ed76c520c0d5f83c6738c);
    assign data_output[23]   = ^(data_input & 128'ha2c1b4132ab49ab79c08f66a027b5df7);
    assign data_output[24]   = ^(data_input & 128'h846270410df22b2e542ab110a0b0e944);
    assign data_output[25]   = ^(data_input & 128'h8da690c316177d73fd7fd230e0d03bcd);
    assign data_output[26]   = ^(data_input & 128'h1a4c21872c2ffbe7faffa461c1a0769b);
    assign data_output[27]   = ^(data_input & 128'h3499420e595ef6cef5fe48c38340ec36);
    assign data_output[28]   = ^(data_input & 128'h6932851cb2bded9ceafd91870681d96d);
    assign data_output[29]   = ^(data_input & 128'hd3650a38647bda39d5fa220e0c02b3db);
    assign data_output[30]   = ^(data_input & 128'h23a96430c5059f5cffdff40cb8b48ef3);
    assign data_output[31]   = ^(data_input & 128'hc231b82086f91597aa955808d0d8f4a2);

    // Ѕиты результата 32Ц63.
    assign data_output[32]   = ^(data_input & 128'h14cccb75011aaa17ae80e3d83a553284);
    assign data_output[33]   = ^(data_input & 128'h3c545c9e022efe38f28125684fff578d);
    assign data_output[34]   = ^(data_input & 128'h79a9b93d045dfd71e5024ad09efeae1a);
    assign data_output[35]   = ^(data_input & 128'hf353737a08bafae3ca0495a03dfd5c34);
    assign data_output[36]   = ^(data_input & 128'he6a6e7f41074f5c694082a407afab969);
    assign data_output[37]   = ^(data_input & 128'hcd4ccee920e8ea8c29105581f4f573d3);
    assign data_output[38]   = ^(data_input & 128'h8f5557a740cb7f0efca049dad3bfd523);
    assign data_output[39]   = ^(data_input & 128'h0a66653a808d550b57c0716c9d2a99c2);
    assign data_output[40]   = ^(data_input & 128'h0c5b8020bc0603ef944f7e1ba0a24414);
    assign data_output[41]   = ^(data_input & 128'h14ed8161c40a0431bdd1822ce0e6cd3c);
    assign data_output[42]   = ^(data_input & 128'h28da02c3881408627ba30559c1cd9b79);
    assign data_output[43]   = ^(data_input & 128'h51b40487112810c4f7470bb2839b36f3);
    assign data_output[44]   = ^(data_input & 128'ha268080e23512088ee8e176406366de6);
    assign data_output[45]   = ^(data_input & 128'h44d0101c46a24111dd1d2fc80c6ddbcd);
    assign data_output[46]   = ^(data_input & 128'h85fba018314281cc2f74208bb879f38f);
    assign data_output[47]   = ^(data_input & 128'h06adc010de830177caa73f0dd051a20a);
    assign data_output[48]   = ^(data_input & 128'he4f0735c6467e3ab431a7940f134ab0c);
    assign data_output[49]   = ^(data_input & 128'h2d1194e5aca825fcc52e8ac1135dfc14);
    assign data_output[50]   = ^(data_input & 128'h5a2329ca58504af98b5d158327baf928);
    assign data_output[51]   = ^(data_input & 128'hb5465294b1a195f216ba2b064e74f251);
    assign data_output[52]   = ^(data_input & 128'h6b8da52963432ae52c74560c9de8e5a2);
    assign data_output[53]   = ^(data_input & 128'hd71a4b52c78655ca59e8ad183ad1ca44);
    assign data_output[54]   = ^(data_input & 128'h4bc4e5f9eb6a493ff1cb227084973f85);
    assign data_output[55]   = ^(data_input & 128'h7278b9aeb2b371d5a18d3ca0f81ad506);
    assign data_output[56]   = ^(data_input & 128'hbe9438aadf294faafeb3f83f504c42e4);
    assign data_output[57]   = ^(data_input & 128'hc2bd49fe607bd1fe03d40941f1d5c72d);
    assign data_output[58]   = ^(data_input & 128'h847b92fdc0f7a3fd07a81382e2ab8f5a);
    assign data_output[59]   = ^(data_input & 128'h09f725fa80ee47fa0f502705c5571eb5);
    assign data_output[60]   = ^(data_input & 128'h13ee4af501dd8ef51fa14e0b8bae3c6b);
    assign data_output[61]   = ^(data_input & 128'h27dd95ea03bb1dea3f439d17165c79d7);
    assign data_output[62]   = ^(data_input & 128'hf02f127fd85e747f8035c2107cf5b14b);
    assign data_output[63]   = ^(data_input & 128'h5fca1c556f94a755ffd97c1fa8a62172);

    // Ѕиты результата 64Ц95.
    assign data_output[64]   = ^(data_input & 128'h7d8d96b4013814610d8f173b70f70dbe);
    assign data_output[65]   = ^(data_input & 128'h8697bbdc02493ca21691384d901916c2);
    assign data_output[66]   = ^(data_input & 128'h0d2e77b8049279442c22719a21332c84);
    assign data_output[67]   = ^(data_input & 128'h1b5def700825f3895945e33542665909);
    assign data_output[68]   = ^(data_input & 128'h37badee0104ae612b28ac66a85ccb213);
    assign data_output[69]   = ^(data_input & 128'h6e74bcc12095cd2464158cd40a986427);
    assign data_output[70]   = ^(data_input & 128'ha165ee3740128f28c5a40e9364c6c5f0);
    assign data_output[71]   = ^(data_input & 128'h3e464bda801c0a3086c70b1db87b865f);
    assign data_output[72]   = ^(data_input & 128'h9925ba6633211c60f2223017f9beaa7d);
    assign data_output[73]   = ^(data_input & 128'hab6fceaa556324a0176751380bc2fe86);
    assign data_output[74]   = ^(data_input & 128'h57df9c54aac749402fcfa2711784fd0d);
    assign data_output[75]   = ^(data_input & 128'haebf39a9548f92815e9f44e32f09fa1b);
    assign data_output[76]   = ^(data_input & 128'h5c7f7253a91e2502bd3e89c65e13f537);
    assign data_output[77]   = ^(data_input & 128'hb9ffe4a6533c4a047b7d128cbd27ea6e);
    assign data_output[78]   = ^(data_input & 128'headb732a9558896805d9140e82f07fa1);
    assign data_output[79]   = ^(data_input & 128'h4c925d3319900eb0f991180bfc5f553e);
    assign data_output[80]   = ^(data_input & 128'h7fee0c9a92e3f976bbcfa450d4fe2799);
    assign data_output[81]   = ^(data_input & 128'h803314afb7250b9acc50ecf17c0369ab);
    assign data_output[82]   = ^(data_input & 128'h0166285f6f4a173598a1d9e2f807d357);
    assign data_output[83]   = ^(data_input & 128'h03cc51bedf952f6a3143b3c5f10fa7ae);
    assign data_output[84]   = ^(data_input & 128'h0798a27cbf2a5ed46286678be21f4f5c);
    assign data_output[85]   = ^(data_input & 128'h0f3144f87f55bda8c40dcf16c53f9eb9);
    assign data_output[86]   = ^(data_input & 128'h608c856b6d49822633d43b7c5f801aea);
    assign data_output[87]   = ^(data_input & 128'hbff7064d4971fc3bdd67d2a86aff134c);
    assign data_output[88]   = ^(data_input & 128'hb0d70c2507a20923b0ffb46368fcc77f);
    assign data_output[89]   = ^(data_input & 128'hd078146f08e61a65d001dca4b8054880);
    assign data_output[90]   = ^(data_input & 128'ha0f028df10cd34cba003b848700b9101);
    assign data_output[91]   = ^(data_input & 128'h40e151bf209b699740077091e0172203);
    assign data_output[92]   = ^(data_input & 128'h81c2a27f4136d32e810fe022c12f4507);
    assign data_output[93]   = ^(data_input & 128'h028444ff826da75d021fc145835e8a0f);
    assign data_output[94]   = ^(data_input & 128'hb4de85db02794699b4c037e96e41d260);
    assign data_output[95]   = ^(data_input & 128'hd86b069203518411d87fdab1b47e63bf);

    // Ѕиты результата 96Ц127.
    assign data_output[96]   = ^(data_input & 128'hcba1d25c077493e54fc9c6330b6a63b0);
    assign data_output[97]   = ^(data_input & 128'h5ce276e5089cb52fd15a4a551cbea4d0);
    assign data_output[98]   = ^(data_input & 128'hb9c5ecca10396b5ea3b595aa387c48a0);
    assign data_output[99]   = ^(data_input & 128'h738bd9942072d7bd476b2a5471f89140);
    assign data_output[100]  = ^(data_input & 128'he716b32941e4af7b8ed755a9e3f12281);
    assign data_output[101]  = ^(data_input & 128'hce2c675282c95ff71dafaa53c6e24502);
    assign data_output[102]  = ^(data_input & 128'h57f81df902e72d0b7496929587afe9b4);
    assign data_output[103]  = ^(data_input & 128'h6550e9ae03bac9f2a7e4e3190535b1d8);
    assign data_output[104]  = ^(data_input & 128'h76740c4beb692e68023cac473ac567cb);
    assign data_output[105]  = ^(data_input & 128'h9a9c14dd3dba73b80645f4c94f4ea85c);
    assign data_output[106]  = ^(data_input & 128'h353928bb7a74e7700c8ae9939e9d50b9);
    assign data_output[107]  = ^(data_input & 128'h6a725177f4e8cee01815d2263d3aa173);
    assign data_output[108]  = ^(data_input & 128'hd4e4a2efe9d19cc1302ba44d7a7543e7);
    assign data_output[109]  = ^(data_input & 128'ha8c944ded2a339836156489af4eb86ce);
    assign data_output[110]  = ^(data_input & 128'h26e785f74f2e5c6ec1913d72d3136a57);
    assign data_output[111]  = ^(data_input & 128'h3bba06a5753497b4811ed6a39de2b365);
    assign data_output[112]  = ^(data_input & 128'hc6afc8ac6b171e1c4a95457d46c47976);
    assign data_output[113]  = ^(data_input & 128'h4af058f4bc382224dfbfcf86cb4c8a9a);
    assign data_output[114]  = ^(data_input & 128'h95e1b1e978714549bf7f9f0d97991535);
    assign data_output[115]  = ^(data_input & 128'h2ac263d2f0e38a927fff3e1b2e322b6a);
    assign data_output[116]  = ^(data_input & 128'h5584c7a4e1c61525fffe7d375d6556d4);
    assign data_output[117]  = ^(data_input & 128'haa098f48c28c2b4afefdfb6ebacbada8);
    assign data_output[118]  = ^(data_input & 128'h92bcd63def0e4889b76fb3a132532226);
    assign data_output[119]  = ^(data_input & 128'he3d764d6b50b8f0e254a223e23623c3b);
    assign data_output[120]  = ^(data_input & 128'h01c6d877b05ada015301da5ab077d8c6);
    assign data_output[121]  = ^(data_input & 128'h024a6898d0ef6e02f5026eefd098684a);
    assign data_output[122]  = ^(data_input & 128'h0495d031a0dedc04ea04dcdea031d095);
    assign data_output[123]  = ^(data_input & 128'h082aa06240bcb808d508b8bc4062a02a);
    assign data_output[124]  = ^(data_input & 128'h105540c481787010ab10707881c44055);
    assign data_output[125]  = ^(data_input & 128'h20aa818802f0e0205720e0f0028881aa);
    assign data_output[126]  = ^(data_input & 128'h4092da66b4bb1b40fd401bbbb466da92);
    assign data_output[127]  = ^(data_input & 128'h80e36cbbd82ded80a980ed2dd8bb6ce3);

endmodule
