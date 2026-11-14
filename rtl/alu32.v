`timescale 1ns/1ps

module alu32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  op,
    output reg  [31:0] y,
    output reg         zero,
    output reg         carry,
    output reg         overflow,
    output reg         negative
);

    localparam OP_ADD  = 4'd0;
    localparam OP_SUB  = 4'd1;
    localparam OP_AND  = 4'd2;
    localparam OP_OR   = 4'd3;
    localparam OP_XOR  = 4'd4;
    localparam OP_NOR  = 4'd5;
    localparam OP_SLL  = 4'd6;
    localparam OP_SRL  = 4'd7;
    localparam OP_SRA  = 4'd8;
    localparam OP_SLT  = 4'd9;
    localparam OP_SLTU = 4'd10;
    localparam OP_XNOR = 4'd11;

    wire [4:0] shamt = b[4:0];

    reg [31:0] result;
    reg [32:0] wide_sum;
    reg        cout;
    reg        ovf;

    always @* begin
        result   = 32'd0;
        wide_sum = 33'd0;
        cout     = 1'b0;
        ovf      = 1'b0;

        case (op)
            OP_ADD: begin
                wide_sum = {1'b0, a} + {1'b0, b};
                result   = wide_sum[31:0];
                cout     = wide_sum[32];
                ovf      = (a[31] == b[31]) && (result[31] != a[31]);
            end

            OP_SUB: begin
                wide_sum = {1'b0, a} + {1'b0, ~b} + 33'd1;
                result   = wide_sum[31:0];
                cout     = wide_sum[32];
                ovf      = (a[31] != b[31]) && (result[31] != a[31]);
            end

            OP_AND:  result = a & b;
            OP_OR:   result = a | b;
            OP_XOR:  result = a ^ b;
            OP_NOR:  result = ~(a | b);
            OP_XNOR: result = ~(a ^ b);
            OP_SLL:  result = a << shamt;
            OP_SRL:  result = a >> shamt;
            OP_SRA:  result = $signed(a) >>> shamt;
            OP_SLT:  result = {31'd0, $signed(a) < $signed(b)};
            OP_SLTU: result = {31'd0, a < b};

            default: result = 32'd0;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y        <= 32'd0;
            zero     <= 1'b0;
            carry    <= 1'b0;
            overflow <= 1'b0;
            negative <= 1'b0;
        end else begin
            y        <= result;
            zero     <= (result == 32'd0);
            carry    <= cout;
            overflow <= ovf;
            negative <= result[31];
        end
    end

endmodule
