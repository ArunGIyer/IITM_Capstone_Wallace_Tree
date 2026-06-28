# IITM_Capstone_Wallace_Tree

Pre Requisites:
Install iverilog and GTKWave

To Run:
cd src/rtl/
iverilog -o out/tb_wallace_mult_8bit.out tb_wallace_mult_8bit.v wallace_mult_8bit.v && vvp out/tb_wallace_mult_8bit.out 
iverilog -o out/tb_rand_wallace_mult_8bit.out tb_rand_wallace_mult_8bit.v wallace_mult_8bit.v && vvp out/tb_rand_wallace_mult_8bit.out

Documentation:
In doc folder
IITM Pravartak_VSLI_Capston Project-1.pdf => project requirement
Capstone_Project_Report.pdf => Project report

