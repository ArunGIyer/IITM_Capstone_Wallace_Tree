// Randomized testbench for the 8x8 Wallace tree multiplier
// Generates 1000 random input pairs and checks each output
// against a simple reference multiply.

module tb_wallace_mult_8bit;

    reg clk;
    reg rst_n;
    reg valid_in;
    reg [7:0] a;
    reg [7:0] b;
    wire valid_out;
    wire [15:0] product;

    integer i;
    integer j;
    integer seed;
    integer failures;
    time start_time;
    time end_time;
    real elapsed_ns;
    real throughput_mops;
    real throughput_bytes_per_sec;
    reg got_valid;
    reg [15:0] expected;
    reg [15:0] observed;

    // Connect the multiplier
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

    initial begin
        // Write VCD waveform for debugging
        // $dumpfile("waveform.vcd");
        // $dumpvars(0, tb_wallace_mult_8bit);

        start_time = $time;

        // Start in reset
        rst_n = 0;
        valid_in = 0;
        a = 0;
        b = 0;
        failures = 0;
        seed = 12345;

        repeat (3) @(posedge clk);

        // Release reset
        rst_n = 1;
        @(posedge clk);

        $display("Starting 1000 random tests...");

        for (i = 0; i < 1000; i = i + 1) begin
            // Generate random 8-bit operands
            seed = seed + 1;
            a = $random(seed) & 8'hff;
            b = $random(seed) & 8'hff;

            expected = a * b;
            valid_in = 1;

            @(posedge clk);
            valid_in = 0;

            // The design is pipelined, so wait until a valid output appears
            observed = 0;
            got_valid = 0;
            for (j = 0; j < 10; j = j + 1) begin
                if (valid_out === 1'b1) begin
                    observed = product;
                    got_valid = 1;
                    j = 10;
                end else begin
                    @(posedge clk);
                end
            end

            if (!got_valid) begin
                $display("ERROR: case %0d - missing valid_out for a=%0d b=%0d", i, a, b);
                failures = failures + 1;
                $finish;
            end

            if (observed !== expected) begin
                $display("ERROR: case %0d - a=%0d b=%0d expected=%0d got=%0d", i, a, b, expected, observed);
                failures = failures + 1;
                $finish;
            end
        end

        end_time = $time;
        elapsed_ns = (end_time - start_time);
        if (elapsed_ns > 0.0) begin
            throughput_mops = (1000.0 * 1.0e9) / elapsed_ns;
            throughput_bytes_per_sec = (1000.0 * 2.0 * 1.0e9) / elapsed_ns;
        end else begin
            throughput_mops = 0.0;
            throughput_bytes_per_sec = 0.0;
        end

        $display("All 1000 random cases passed.");
        $display("Execution finished at time %0t ns", $time);
        $display("Completed 1000 cases in %0.3f ns", elapsed_ns);
        $display("Throughput = %0.3f MOPS/s", throughput_mops / 1.0e6);
        $display("Throughput = %0.3f MB/s", throughput_bytes_per_sec / 1.0e6);
        $finish;
    end

endmodule
