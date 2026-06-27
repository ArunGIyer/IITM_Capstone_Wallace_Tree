// Simple testbench for the 8x8 Wallace tree multiplier
// Just applies some test values and prints the result
// We check the answer by looking at the printed numbers

module tb_wallace_mult_8bit;

    reg clk;
    reg rst_n;
    reg valid_in;
    reg [7:0] a;
    reg [7:0] b;
    wire valid_out;
    wire [15:0] product;

    // connect the multiplier
    wallace_mult_8bit dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .a(a),
        .b(b),
        .valid_out(valid_out),
        .product(product)
    );

    // Toggle every 10 ns for a 20 ns total period = 50 MHz
    initial clk = 0;
    always #10 clk = ~clk;

    // print the answer every time valid_out goes high
    always @(posedge clk) begin
        if (valid_out == 1) begin
            $display("Time=%0t  ->  product = %0d", $time, product);
        end
    end

    initial begin
        // Specifies the name of the output VCD file
        $dumpfile("waveform.vcd"); 
        // 0 means dump all signals in the testbench and submodules
        $dumpvars(0, tb_wallace_mult_8bit); 
        
        // start with reset on
        rst_n = 0;
        valid_in = 0;
        a = 0;
        b = 0;

        // hold reset for a few clocks
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        // release reset
        rst_n = 1;
        @(posedge clk);

        $display("Starting tests...");

        // Test 1: 3 x 5 = 15
        a = 3; b = 5; valid_in = 1;
        @(posedge clk);
        valid_in = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        // Test 2: 10 x 10 = 100
        a = 10; b = 10; valid_in = 1;
        @(posedge clk);
        valid_in = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        // Test 3: 255 x 255 = 65025 (biggest possible answer)
        a = 255; b = 255; valid_in = 1;
        @(posedge clk);
        valid_in = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        // Test 4: 0 x 200 = 0
        a = 0; b = 200; valid_in = 1;
        @(posedge clk);
        valid_in = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        // Test 5: 128 x 2 = 256
        a = 128; b = 2; valid_in = 1;
        @(posedge clk);
        valid_in = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        // Test 6: send a few values back to back, no gaps
        a = 4; b = 4; valid_in = 1;     // 16
        @(posedge clk);
        a = 6; b = 7;                  // 42
        @(posedge clk);
        a = 9; b = 9;                  // 81
        @(posedge clk);
        valid_in = 0;
        a = 0;
        b = 0;

        // wait a bit for the last answers to come out
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        $display("Tests done. Check the printed products above against:");
        $display("Expected: 15, 100, 65025, 0, 256, then 16, 42, 81");

        $finish;
    end

endmodule
