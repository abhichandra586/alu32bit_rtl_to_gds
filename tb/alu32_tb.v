`timescale 1ns/1ps

module alu32_tb;

    reg         clk;
    reg         rst_n;
    reg  [31:0] a;
    reg  [31:0] b;
    reg  [3:0]  op;
    wire [31:0] y;
    wire        zero;
    wire        carry;
    wire        overflow;
    wire        negative;

    integer tests;
    integer errors;
    integer i, j, k, o;

    reg [31:0] exp_y;
    reg        exp_c;
    reg        exp_v;
    reg [31:0] corners [0:7];

    alu32 dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .a        (a),
        .b        (b),
        .op       (op),
        .y        (y),
        .zero     (zero),
        .carry    (carry),
        .overflow (overflow),
        .negative (negative)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task calc_expected;
        input  [31:0] xa;
        input  [31:0] xb;
        input  [3:0]  xop;
        output [31:0] ry;
        output        rc;
        output        rv;
        reg    [32:0] s;
        begin
            ry = 32'd0;
            rc = 1'b0;
            rv = 1'b0;
            s  = 33'd0;
            case (xop)
                4'd0: begin
                    s  = {1'b0, xa} + {1'b0, xb};
                    ry = s[31:0];
                    rc = s[32];
                    rv = (~(xa[31] ^ xb[31])) & (ry[31] ^ xa[31]);
                end
                4'd1: begin
                    s  = {1'b0, xa} + {1'b0, ~xb} + 33'd1;
                    ry = s[31:0];
                    rc = s[32];
                    rv = (xa[31] ^ xb[31]) & (ry[31] ^ xa[31]);
                end
                4'd2:  ry = xa & xb;
                4'd3:  ry = xa | xb;
                4'd4:  ry = xa ^ xb;
                4'd5:  ry = ~(xa | xb);
                4'd6:  ry = xa << xb[4:0];
                4'd7:  ry = xa >> xb[4:0];
                4'd8:  ry = $signed(xa) >>> xb[4:0];
                4'd9:  ry = ($signed(xa) < $signed(xb)) ? 32'd1 : 32'd0;
                4'd10: ry = (xa < xb) ? 32'd1 : 32'd0;
                4'd11: ry = ~(xa ^ xb);
                default: ry = 32'd0;
            endcase
        end
    endtask

    task run_vector;
        input [31:0] va;
        input [31:0] vb;
        input [3:0]  vop;
        begin
            @(negedge clk);
            a  = va;
            b  = vb;
            op = vop;
            @(posedge clk);
            #3;
            calc_expected(va, vb, vop, exp_y, exp_c, exp_v);
            tests = tests + 1;
            if (y !== exp_y || zero !== (exp_y == 32'd0) || carry !== exp_c ||
                overflow !== exp_v || negative !== exp_y[31]) begin
                errors = errors + 1;
                $display("FAIL t=%0t op=%0d a=%h b=%h y=%h exp=%h z=%b c=%b v=%b n=%b exp_c=%b exp_v=%b",
                         $time, vop, va, vb, y, exp_y, zero, carry, overflow, negative, exp_c, exp_v);
            end
        end
    endtask

    initial begin
        $dumpfile("alu32_tb.vcd");
        $dumpvars(0, alu32_tb);

        tests  = 0;
        errors = 0;
        rst_n  = 1'b0;
        a      = 32'd0;
        b      = 32'd0;
        op     = 4'd0;

        corners[0] = 32'h00000000;
        corners[1] = 32'hFFFFFFFF;
        corners[2] = 32'h7FFFFFFF;
        corners[3] = 32'h80000000;
        corners[4] = 32'h00000001;
        corners[5] = 32'hAAAAAAAA;
        corners[6] = 32'h55555555;
        corners[7] = 32'h0000001F;

        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        for (o = 0; o < 12; o = o + 1)
            for (j = 0; j < 8; j = j + 1)
                for (k = 0; k < 8; k = k + 1)
                    run_vector(corners[j], corners[k], o[3:0]);

        for (i = 0; i < 32; i = i + 1) begin
            run_vector(32'h80000001, i, 4'd6);
            run_vector(32'h80000001, i, 4'd7);
            run_vector(32'h80000001, i, 4'd8);
        end

        for (i = 0; i < 20000; i = i + 1)
            run_vector($urandom, $urandom, $urandom % 12);

        @(negedge clk);
        rst_n = 1'b0;
        #1;
        if (y !== 32'd0) begin
            errors = errors + 1;
            $display("FAIL: output not cleared by asynchronous reset");
        end

        $display("-----------------------------------------");
        $display("TESTS: %0d   ERRORS: %0d   => %s", tests, errors, (errors == 0) ? "PASS" : "FAIL");
        $display("-----------------------------------------");
        $finish;
    end

endmodule
