# 1 "Firmware/start.S"
# 1 "<built-in>"
# 1 "<command-line>"
# 31 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 32 "<command-line>" 2
# 1 "Firmware/start.S"

##############################################################################
# RESET & IRQ
##############################################################################

 .global main, irq1_handler, irq2_handler, irq3_handler, test_mult

 .section .boot
reset_vec:
 j start
.section .text

######################################
### Main program
######################################

start:
 li sp,8192

# copy data section
 la a0, _sdata
 la a1, _sdata_values
 la a2, _edata
 bge a0, a2, end_init_data
loop_init_data:
 lw a3,0(a1)
 sw a3,0(a0)
 addi a0,a0,4
 addi a1,a1,4
 blt a0, a2, loop_init_data
end_init_data:
# zero-init bss section
 la a0, _sbss
 la a1, _ebss
 bge a0, a1, end_init_bss
loop_init_bss:
 sw zero, 0(a0)
 addi a0, a0, 4
 blt a0, a1, loop_init_bss
end_init_bss:

######################################
### Test multiplication instructions
######################################


######################################
### Test multiplication instructions
######################################

call test_mult
# call main
 call main
loop:
 j loop


 .globl delay_loop
delay_loop:
 addi a0,a0,-1
 bnez a0, delay_loop
 ret
 
 
test_mult:
 # Test MUL, MULH, MULHSU, MULHU with various operand pairs
 # We'll use registers t0-t1 for operands and t2 for results
 
 # Test case 1: Positive × Positive
 # 5 × 7 = 35 (0x23)
 li t0, 5      # rs1 = 5 b 
 li t1, 7      # rs2 = 7 a
 mul t2, t0, t1    # MUL: t2 = 35 (low 32 bits)
 mulh a0, t0, t1   # MULH: t3 = 0 (high 32 bits, signed×signed)
 mulhsu a1, t0, t1 # MULHSU: t4 = 0 (high 32 bits, signed×unsigned)
 mulhu a2, t0, t1  # MULHU: t5 = 0 (high 32 bits, unsigned×unsigned)
 
 # Test case 2: Negative × Positive
 # -5 × 7 = -35 (0xFFFFFFDD in 32-bit, 0xFFFFFFFFFFFFFFDD in 64-bit)
 li t0, -5     # rs1 = -5 (0xFFFFFFFB) b
 li t1, 7      # rs2 = 7 a 
 mul t2, t0, t1    # MUL: t2 = -35 (0xFFFFFFDD)
 mulh a0, t0, t1   # MULH: t3 = -1 (0xFFFFFFFF, sign extension)
 mulhsu a1, t0, t1 # MULHSU: t4 = -1 (signed(-5) × unsigned(7) = -35, high=-1)
 mulhu a2, t0, t1  # MULHU: t5 = 7 (unsigned(0xFFFFFFFB=4294967291) × 7 = 0x70000001D, high=7)
 
 # Test case 3: Positive × Negative
 # 5 × -7 = -35
 li t0, 5      # rs1 = 5
 li t1, -7     # rs2 = -7 (0xFFFFFFF9)
 mul t2, t0, t1    # MUL: t2 = -35 (0xFFFFFFDD)
 mulh a0, t0, t1   # MULH: t3 = -1 (0xFFFFFFFF)
 mulhsu a1, t0, t1 # MULHSU: t4 = 4 (signed(5) × unsigned(0xFFFFFFF9) = 0x4FFFFFFF5 >> 32)
 mulhu a2, t0, t1  # MULHU: t5 = 4 (unsigned(5) × unsigned(0xFFFFFFF9) = 0x4FFFFFFF5 >> 32)
 
 # Test case 4: Negative × Negative
 # -5 × -7 = 35
 li t0, -5     # rs1 = -5
 li t1, -7     # rs2 = -7
 mul t2, t0, t1    # MUL: t2 = 35 (0x23)
 mulh a0, t0, t1   # MULH: t3 = 0 (negative × negative = positive)
 mulhsu a1, t0, t1 # MULHSU: t4 = -5 (signed(-5) × unsigned(0xFFFFFFF9=4294967289) = -21474836445, high=-5)
 mulhu a2, t0, t1  # MULHU: t5 = 0xFFFFFFF6 (unsigned(0xFFFFFFFB) × unsigned(0xFFFFFFF9) = large, high bits)
 
 # Test case 5: Large numbers (to test high bits)
 # 0x12345678 × 0x87654321
 li t0, 0x12345678
 li t1, 0x87654321
 mul t2, t0, t1    # MUL: low 32 bits
 mulh a0, t0, t1   # MULH: high 32 bits (signed×signed)
 mulhsu a1, t0, t1 # MULHSU: high 32 bits (signed×unsigned)
 mulhu a2, t0, t1  # MULHU: high 32 bits (unsigned×unsigned)
 
 # Test case 6: Edge case - Maximum positive
 # 0x7FFFFFFF × 2 = 0xFFFFFFFE (overflow in 32-bit, but correct in 64-bit)
 li t0, 0x7FFFFFFF  # rs1 = 2147483647 (max positive signed)
 li t1, 2            # rs2 = 2
 mul t2, t0, t1      # MUL: t2 = 0xFFFFFFFE (-2 in signed, but 4294967294 unsigned)
 mulh a0, t0, t1     # MULH: t3 = 0 (signed: 2147483647 × 2 = 4294967294, high=0)
 mulhsu a1, t0, t1   # MULHSU: t4 = 0
 mulhu a2, t0, t1    # MULHU: t5 = 0
 
 # Test case 7: Edge case - Maximum negative
 # 0x80000000 × 2 = 0x00000000 (overflow)
 li t0, 0x80000000  # rs1 = -2147483648 (min signed)
 li t1, 2           # rs2 = 2
 mul t2, t0, t1     # MUL: t2 = 0 (overflow, wraps around)
 mulh a0, t0, t1    # MULH: t3 = -1 (signed: -2147483648 × 2 = -4294967296, high=-1)
 mulhsu a1, t0, t1  # MULHSU: t4 = -1 (signed(-2147483648) × unsigned(2) = -4294967296, high=-1)
 mulhu a2, t0, t1   # MULHU: t5 = 1 (unsigned(0x80000000=2147483648) × 2 = 0x100000000, high=1)
 
 # Test case 8: Small numbers
 # 1 × 1 = 1
 li t0, 1
 li t1, 1
 mul t2, t0, t1     # MUL: t2 = 1
 mulh a0, t0, t1    # MULH: t3 = 0
 mulhsu a1, t0, t1  # MULHSU: t4 = 0
 mulhu a2, t0, t1   # MULHU: t5 = 0
 
 # Test case 9: Zero
 # 0 × any = 0
 li t0, 0
 li t1, 42
 mul t2, t0, t1     # MUL: t2 = 0
 mulh a0, t0, t1    # MULH: t3 = 0
 mulhsu a1, t0, t1  # MULHSU: t4 = 0
 mulhu a2, t0, t1   # MULHU: t5 = 0
 
 # Test case 10: Large unsigned values
 # 0xFFFFFFFF × 2 = 0x1FFFFFFFE
 li t0, -1          # rs1 = 0xFFFFFFFF (unsigned: 4294967295)
 li t1, 2           # rs2 = 2
 mul t2, t0, t1     # MUL: t2 = 0xFFFFFFFE (-1 signed x 2 signed)
 mulh a0, t0, t1    # MULH: t3 = -1 (signed: -1 × 2 = -2, high=-1)
 mulhsu a1, t0, t1  # MULHSU: t4 = -1 (signed(-1) × unsigned(2) = -2, high=-1)
 mulhu a2, t0, t1   # MULHU: t5 = 1 (unsigned(0xFFFFFFFF) × unsigned(2) = 0x1FFFFFFFE, high=1)

# All tests completed
# Results are in registers t2-t5 for the last test case
# In a real scenario, you might want to store these to memory
# or use breakpoints to inspect the results

ret