## Controller Data:
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/f198b6dd-639b-42c0-bdf5-53c3e74523d8" />

### Transcribt:

vsim -c controller_test 

Start time: 05:12:08 on Sep 09,2026

Loading work.controller_test

Loading work.controller

Testing opcode HLT phase 0 1 2 3 4 5 6 7

Testing opcode SKZ phase 0 1 2 3 4 5 6 7

Testing opcode ADD phase 0 1 2 3 4 5 6 7

Testing opcode AND phase 0 1 2 3 4 5 6 7

Testing opcode XOR phase 0 1 2 3 4 5 6 7

Testing opcode LDA phase 0 1 2 3 4 5 6 7

Testing opcode STO phase 0 1 2 3 4 5 6 7

Testing opcode JMP phase 0 1 2 3 4 5 6 7

TEST PASSED

** Note: $finish    : ./controller.v(197)

Time: 65 ps  Iteration: 0  Instance: /controller_test

End time: 05:12:10 on Sep 09,2026, Elapsed time: 0:00:02

Errors: 0, Warnings: 0



## Driver:

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/d51b3067-f905-4e33-a55c-b808c2a5799c" />


### Transcribt:
vsim -c driver_test 

Start time: 05:22:53 on Sep 09,2026

Loading work.driver_test

Loading work.driver

At time 1 data_en=0 data_in=xxxxxxxx data_out=zzzzzzzz

At time 2 data_en=1 data_in=01010101 data_out=01010101

At time 3 data_en=1 data_in=10101010 data_out=10101010

TEST PASSED

** Note: $finish    : ./driver.v(68)

   Time: 3 ps  Iteration: 0  Instance: /driver_test

End time: 05:22:56 on Sep 09,2026, Elapsed time: 0:00:03

Errors: 0, Warnings: 0



## ALU:

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/992039a7-caaf-4134-bc0c-4846bccfcaac" />

### Transcribt:

vsim -c alu_test 

Start time: 05:28:19 on Sep 09,2026

Loading work.alu_test

Loading work.alu

At time 1 opcode=000 in_a=01000010 in_b=10000110 a_is_zero=0 alu_out=01000010

At time 2 opcode=001 in_a=01000010 in_b=10000110 a_is_zero=0 alu_out=01000010

At time 3 opcode=010 in_a=01000010 in_b=10000110 a_is_zero=0 alu_out=11001000

At time 4 opcode=011 in_a=01000010 in_b=10000110 a_is_zero=0 alu_out=00000010

At time 5 opcode=100 in_a=01000010 in_b=10000110 a_is_zero=0 alu_out=11000100

At time 6 opcode=101 in_a=01000010 in_b=10000110 a_is_zero=0 alu_out=10000110

At time 7 opcode=110 in_a=01000010 in_b=10000110 a_is_zero=0 alu_out=01000010

At time 8 opcode=111 in_a=01000010 in_b=10000110 a_is_zero=0 alu_out=01000010

At time 9 opcode=111 in_a=00000000 in_b=10000110 a_is_zero=1 alu_out=00000000

TEST PASSED

** Note: $finish    : ./alu.v(88)

   Time: 9 ps  Iteration: 0  Instance: /alu_test
   
End time: 05:28:21 on Sep 09,2026, Elapsed time: 0:00:02

Errors: 0, Warnings: 0



## Multiplexor

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/719d956a-ff20-495c-b065-2d7d660aa7a6" />



### Transcribt:

vsim -c multiplexor_test 

Start time: 05:30:02 on Sep 09,2026

Loading work.multiplexor_test

Loading work.multiplexor

At time 1 sel=0 in0=10101 in1=00000, mux_out=10101

At time 2 sel=0 in0=01010 in1=00000, mux_out=01010

At time 3 sel=1 in0=00000 in1=10101, mux_out=10101

At time 4 sel=1 in0=00000 in1=01010, mux_out=01010

TEST PASSED

** Note: $finish    : ./multiplexor.v(68)

   Time: 4 ps  Iteration: 0  Instance: /multiplexor_test
   
End time: 05:30:04 on Sep 09,2026, Elapsed time: 0:00:02

Errors: 0, Warnings: 0



