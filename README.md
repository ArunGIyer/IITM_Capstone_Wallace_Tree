# IITM_Capstone_Wallace_Tree

To Run:
cd src/rtl/
iverilog -o out/tb_wallace_mult_8bit.out tb_wallace_mult_8bit.v wallace_mult_8bit.v && vvp out/tb_wallace_mult_8bit.out 
iverilog -o out/tb_rand_wallace_mult_8bit.out tb_rand_wallace_mult_8bit.v wallace_mult_8bit.v && vvp out/tb_rand_wallace_mult_8bit.out

