// Simple 8x8 Wallace Tree Multiplier
// Pipelined into 3 stages using registers
// Written in a simple/behavioral style (easy to read, not gate level)

module wallace_mult_8bit(
    input clk,
    input rst_n,        // reset, active low
    input valid_in,
    input [7:0] a,
    input [7:0] b,
    output reg valid_out,
    output reg [15:0] product
);

    // ---------------------------------------------------------
    // STAGE 1
    // Make all 8 partial products and add some of them together
    // ---------------------------------------------------------

    reg [15:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7;

    // these will hold the result after stage 1
    reg [15:0] row1_0, row1_1, row1_2, row1_3, row1_4, row1_5;
    reg stage1_valid;

    // temporary variables used to add 3 rows together
    reg [15:0] sum_temp, carry_temp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row1_0 <= 0;
            row1_1 <= 0;
            row1_2 <= 0;
            row1_3 <= 0;
            row1_4 <= 0;
            row1_5 <= 0;
            stage1_valid <= 0;
        end else begin

            // make the 8 partial products
            // if bit i of b is 1, shift a left by i, else 0
            if (b[0] == 1) pp0 = a; else pp0 = 0;
            if (b[1] == 1) pp1 = a << 1; else pp1 = 0;
            if (b[2] == 1) pp2 = a << 2; else pp2 = 0;
            if (b[3] == 1) pp3 = a << 3; else pp3 = 0;
            if (b[4] == 1) pp4 = a << 4; else pp4 = 0;
            if (b[5] == 1) pp5 = a << 5; else pp5 = 0;
            if (b[6] == 1) pp6 = a << 6; else pp6 = 0;
            if (b[7] == 1) pp7 = a << 7; else pp7 = 0;

            // add the first 3 partial products together (like a full adder)
            sum_temp   = pp0 ^ pp1 ^ pp2;
            carry_temp = (pp0 & pp1) | (pp1 & pp2) | (pp0 & pp2);
            carry_temp = carry_temp << 1;
            row1_0 <= sum_temp;
            row1_1 <= carry_temp;

            // add the next 3 partial products together
            sum_temp   = pp3 ^ pp4 ^ pp5;
            carry_temp = (pp3 & pp4) | (pp4 & pp5) | (pp3 & pp5);
            carry_temp = carry_temp << 1;
            row1_2 <= sum_temp;
            row1_3 <= carry_temp;

            // last 2 partial products just pass through to next stage
            row1_4 <= pp6;
            row1_5 <= pp7;

            stage1_valid <= valid_in;
        end
    end


    // ---------------------------------------------------------
    // STAGE 2
    // Keep adding the 6 rows from stage 1 down to just 2 rows
    // ---------------------------------------------------------

    reg [15:0] row2_sum, row2_carry;
    reg stage2_valid;

    reg [15:0] sumA, carryA;
    reg [15:0] sumB, carryB;
    reg [15:0] sumC, carryC;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row2_sum   <= 0;
            row2_carry <= 0;
            stage2_valid <= 0;
        end else begin

            // add rows 0,1,2 from stage 1
            sumA   = row1_0 ^ row1_1 ^ row1_2;
            carryA = (row1_0 & row1_1) | (row1_1 & row1_2) | (row1_0 & row1_2);
            carryA = carryA << 1;

            // add rows 3,4,5 from stage 1
            sumB   = row1_3 ^ row1_4 ^ row1_5;
            carryB = (row1_3 & row1_4) | (row1_4 & row1_5) | (row1_3 & row1_5);
            carryB = carryB << 1;

            // now we have 4 rows: sumA, carryA, sumB, carryB
            // add 3 of them together
            sumC   = sumA ^ carryA ^ sumB;
            carryC = (sumA & carryA) | (carryA & sumB) | (sumA & sumB);
            carryC = carryC << 1;

            // now combine sumC with the leftover row (carryB)
            // this is just like a half adder (only 2 inputs left)
            row2_sum   <= sumC ^ carryB;
            row2_carry <= carryC + ((sumC & carryB) << 1);

            stage2_valid <= stage1_valid;
        end
    end


    // ---------------------------------------------------------
    // STAGE 3
    // Final addition of the last 2 rows to get the answer
    // ---------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product   <= 0;
            valid_out <= 0;
        end else begin
            product   <= row2_sum + row2_carry;  // regular addition
            valid_out <= stage2_valid;
        end
    end

endmodule
