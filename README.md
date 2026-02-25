# AXI4-Lite Slave Design & Debugging Project
## Tools Used
- EDA Playground
- SystemVerilog
- Icarus Verilog / ModelSim
- GTKWave
## Overview
...

## Key Debugging Issues
1. Incorrect Same-Cycle Write Condition
   
  Initial Implementation:
    if (AWVALID && AWREADY && WVALID && WREADY)
    This assumed that address and data handshakes occur in the same clock cycle.
  
  Problem:
    AXI write address and write data channels are independent.
    They may complete handshakes in different cycles.
  
  As a result:
    Write operation was never triggered
    BVALID was not asserted
    Protocol behavior was incorrect
  
  Fix:
    Implemented independent capture logic:
    Latch AW transaction on AW handshake
    Latch W transaction on W handshake
    Perform write only after both are received
    This ensures protocol-compliant behavior regardless of timing alignment.
