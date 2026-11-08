`timescale 1ns/1ps
// Functional test only: one processing edge does not establish timing closure.
module tb_matrix_round;
    reg clk=0, rst=1, start=0;
    always #2.5 clk=~clk;
    reg [127:0] a=0,b=0,k=0;
    wire [127:0] a_next,b_next,lsx;
    wire f_done,lsx_done;
    key_matrix_onecycle f_dut (
        .clk(clk),.rst(rst),.start(start),.a(a),.b(b),.k(k),
        .a_next(a_next),.b_next(b_next),.done(f_done)
    );
    data_matrix_onecycle lsx_dut (
        .clk(clk),.rst(rst),.start(start),.a(a),.k(k),.y(lsx),.done(lsx_done)
    );
    reg [511:0] vectors [0:552];
    reg [127:0] expected_a,expected_b,expected_f;
    reg [127:0] hold_a,hold_b,hold_lsx;
    integer i,cycle_count=0,launch_cycle,passed=0;
    always @(posedge clk) cycle_count=cycle_count+1;

    task idle_cycle;
        begin
            @(negedge clk);
            start=0;
            a=~a; b=~b; k=~k;
            hold_a=a_next; hold_b=b_next; hold_lsx=lsx;
            @(posedge clk); #0.1;
            if(f_done !== 0 || lsx_done !== 0 ||
               a_next !== hold_a || b_next !== hold_b || lsx !== hold_lsx)
                $fatal(1,"Idle cycle changed outputs or retained done");
        end
    endtask

    initial begin
        $readmemh("matrix_round_vectors.mem",vectors);
        repeat(2) @(posedge clk);
        #0.1;
        if(a_next !== 0 || b_next !== 0 || lsx !== 0 || f_done !== 0 || lsx_done !== 0)
            $fatal(1,"Initial reset failed");
        rst=0;
        for(i=0;i<553;i=i+1) begin
            @(negedge clk);
            {expected_a,expected_b,k,expected_f}=vectors[i];
            // First 32 vectors exercise actual output feedback through key expansion.
            if(i>0 && i<32) begin
                a=a_next; b=b_next;
                if(a !== expected_a || b !== expected_b)
                    $fatal(1,"Key schedule feedback mismatch at step %0d",i+1);
            end else begin a=expected_a; b=expected_b; end
            start=1;
            launch_cycle=cycle_count;
            hold_a=a_next; hold_b=b_next; hold_lsx=lsx;
            #0.1;
            if(a_next !== hold_a || b_next !== hold_b || lsx !== hold_lsx)
                $fatal(1,"Registered outputs changed before clock edge");
            @(posedge clk); #0.1;
            if(cycle_count-launch_cycle != 1 || f_done !== 1 || lsx_done !== 1)
                $fatal(1,"Expected a result on the next processing edge");
            if(a_next !== expected_f || b_next !== expected_a || lsx !== (expected_f ^ expected_b))
                $fatal(1,"Vector %0d mismatch: F=%032h,%032h LSX=%032h expected F.a=%032h",
                    i,a_next,b_next,lsx,expected_f);
            passed=passed+1;
            if(i==0) $display("RFC FIRST F: A=%032h B=%032h cycles=1",a_next,b_next);
            if(i==7 || i==15 || i==23 || i==31)
                $display("RFC KEYS after step %0d: %032h %032h",i+1,a_next,b_next);
            if(i==32) $display("RFC FIRST ENCRYPTION ROUND: %032h cycles=1",lsx);
            if(i==40 && (lsx ^ 128'h72e9dd7416bcf45b755dbaa88e4a4043) !==
                          128'h7f679d90bebc24305a468d42b9d4edcd)
                $fatal(1,"Full encryption round sequence mismatch");
            if(i%17==16) idle_cycle;
        end
        idle_cycle;
        // Reset must override start and clear the outputs after activity.
        @(negedge clk); start=1; rst=1;
        @(posedge clk); #0.1;
        if(a_next !== 0 || b_next !== 0 || lsx !== 0 || f_done !== 0 || lsx_done !== 0)
            $fatal(1,"Reset priority failed");
        @(negedge clk); rst=0; start=0;
        idle_cycle;
        $display("ALL PASS: %0d F and LSX vectors; one cycle; key feedback, full encryption, all S inputs, stalls and reset",passed);
        $finish;
    end
    initial begin #100000; $fatal(1,"Matrix round test timeout"); end
endmodule
