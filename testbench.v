`timescale 1ns / 1ps

module tb_pipelined_wallace;

    reg clk;
    reg reset;
    reg [7:0] A;
    reg [7:0] B;
    wire [15:0] Product;

    // Instantiate UUT
    pipelined_wallace_8x8 uut (
        .clk(clk),
        .reset(reset),
        .A(A),
        .B(B),
        .Product(Product)
    );

    // Clock generation (50MHz)
    always #10 clk = ~clk;

    // Pipeline scoreboard delay elements
    reg [7:0] A_d1, A_d2, A_d3;
    reg [7:0] B_d1, B_d2, B_d3;

    always @(posedge clk) begin
        A_d1 <= A; A_d2 <= A_d1; A_d3 <= A_d2;
        B_d1 <= B; B_d2 <= B_d1; B_d3 <= B_d2;
    end

    initial begin
        clk = 0;
        reset = 1;
        A = 0;
        B = 0;
        #25;
        reset = 0;

        // Apply random test vectors
        repeat (20) begin
            @(posedge clk);
            #1;
            A = $random % 256;
            B = $random % 256;
        end

        // Edge Cases
        @(posedge clk); #1; A = 8'hFF; B = 8'hFF; // Max values
        @(posedge clk); #1; A = 8'h00; B = 8'h7F; // Zero case
        
        #100;
        $finish;
    end

    // Continuous Assertion verification checking after 3 pipeline delays
    always @(posedge clk) begin
        #2;
        if (!reset && (A_d3 !== 0 || B_d3 !== 0)) begin
            if (Product === (A_d3 * B_d3)) begin
                $display("PASS: %d * %d = %d", A_d3, B_d3, Product);
            end else begin
                $display("FAIL!!! Error: %d * %d Expected: %d, Got: %d", A_d3, B_d3, (A_d3 * B_d3), Product);
            end
        end
    end

endmodule
