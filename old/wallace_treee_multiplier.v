// Module: wallace_tree_8bit
// Style: Behavioral representation of the multi-stage compression reduction
module wallace_tree_8bit ( input  [7:0] A, input  [7:0] B, output [15:0] Product);

    // Stage 1: Generate 8 rows of 8-bit partial products
    reg [7:0] p [0:7];
    integer i;
    
    always @(*) begin
        for (i = 0; i < 8; i = i + 1) begin
            p[i] = B[i] ? A : 8'b00000000;
    end

    // Internal wires for tracking column matrices across compression stages
    // 16 columns total (0 to 15) to hold maximum bit growth
    
    // --- STAGE 1 REDUCTION (Compress rows 8 -> 6) ---
    // Group rows in sets of 3: (p0, p1, p2) and (p3, p4, p5). Keep p6, p7 as is.
    wire [15:0] s1_0, c1_0; // From p0, p1, p2
    wire [15:0] s1_1, c1_1; // From p3, p4, p5
    
    // Behavioral 3:2 Compressor Macro functions using Full Adders
    function [1:0] fa (input x, input y, input z);
        begin
            fa[0] = x ^ y ^ z;        // Sum
            fa[1] = (x & y) | (y & z) | (z & x); // Carry
        end
    endfunction

    function [1:0] ha (input x, input y);
        begin
            ha[0] = x ^ y;   // Sum
            ha[1] = x & y;   // Carry
        end
    endfunction

    // Unroll columns and explicitly assign step 1 reductions
    reg [15:0] sum1_0, cry1_0;
    reg [15:0] sum1_1, cry1_1;
    
    always @(*) begin
        sum1_0 = 0; cry1_0 = 0;
        sum1_1 = 0; cry1_1 = 0;
        
        // Compress Set 1 (p0, p1, p2 shifted accordingly)
        for(i=0; i<16; i=i+1) begin : compress_loop
            // Align bit arrays by column index
            automatic bit b0 = (i >= 0 && i < 8) ? p[0][i]   : 0;
            automatic bit b1 = (i >= 1 && i < 9) ? p[1][i-1] : 0;
            automatic bit b2 = (i >= 2 && i < 10) ? p[2][i-2] : 0;
            {cry1_0[i], sum1_0[i]} = fa(b0, b1, b2);
            
            // Compress Set 2 (p3, p4, p5 shifted accordingly)
            automatic bit b3 = (i >= 3 && i < 11) ? p[3][i-3] : 0;
            automatic bit b4 = (i >= 4 && i < 12) ? p[4][i-4] : 0;
            automatic bit b5 = (i >= 5 && i < 13) ? p[5][i-5] : 0;
            {cry1_1[i], sum1_1[i]} = fa(b3, b4, b5);
        end
    end
    
    // Shift the intermediate carries to line up by weight
    wire [15:0] c1_0_shifted = {cry1_0[14:0], 1'b0};
    wire [15:0] c1_1_shifted = {cry1_1[14:0], 1'b0};

    // --- STAGE 2 REDUCTION (Compress rows 6 -> 4) ---
    // Inputs: sum1_0, c1_0_shifted, sum1_1, c1_1_shifted, p6 (shifted), p7 (shifted)
    reg [15:0] sum2_0, cry2_0;
    reg [15:0] sum2_1, cry2_1;
    
    always @(*) begin
        sum2_0 = 0; cry2_0 = 0;
        sum2_1 = 0; cry2_1 = 0;
        for(i=0; i<16; i=i+1) begin
            automatic bit b6 = (i >= 6 && i < 14) ? p[6][i-6] : 0;
            automatic bit b7 = (i >= 7 && i < 15) ? p[7][i-7] : 0;
            
            // Group first 3 vectors
            {cry2_0[i], sum2_0[i]} = fa(sum1_0[i], c1_0_shifted[i], sum1_1[i]);
            // Group remaining 3 vectors
            {cry2_1[i], sum2_1[i]} = fa(c1_1_shifted[i], b6, b7);
        end
    end
    
    wire [15:0] c2_0_shifted = {cry2_0[14:0], 1'b0};
    wire [15:0] c2_1_shifted = {cry2_1[14:0], 1'b0};

    // --- STAGE 3 REDUCTION (Compress rows 4 -> 3 -> 2) ---
    reg [15:0] sum3_0, cry3_0;
    reg [15:0] final_row1, final_row2_cry;
    
    always @(*) begin
        sum3_0 = 0; cry3_0 = 0;
        final_row1 = 0; final_row2_cry = 0;
        
        for(i=0; i<16; i=i+1) begin
            // Compress 4 rows down to 3
            {cry3_0[i], sum3_0[i]} = fa(sum2_0[i], c2_0_shifted[i], sum2_1[i]);
        end
    end
    
    wire [15:0] c3_0_shifted = {cry3_0[14:0], 1'b0};
    
    // Final reduction to get exactly 2 vectors for a standard vector addition
    always @(*) begin
        for(i=0; i<16; i=i+1) begin
            {final_row2_cry[i], final_row1[i]} = fa(sum3_0[i], c3_0_shifted[i], c2_1_shifted[i]);
        end
    end
    
    wire [15:0] final_row2 = {final_row2_cry[14:0], 1'b0};

    // --- STAGE 4: Final Vector Addition ---
    // The final two remaining vector rows are merged with a simple CPA/RCA adder.
    assign Product = final_row1 + final_row2;

endmodule
