# APB-Controlled-I2C

An FPGA-oriented **APB-controlled I²C peripheral** implemented using synthesizable Verilog/SystemVerilog RTL.

The design combines an **AMBA APB register interface** with an **I²C Master controller**, allowing a processor or APB bus master to configure and initiate I²C transactions through memory-mapped registers. A dedicated I²C Slave is included in the project primarily for simulation and functional verification.

The project was developed as part of the **National Telecommunication Institute (NTI) Digital Design / FPGA training**.

---

## Table of Contents

* [1. Project Overview](#1-project-overview)
* [2. Project Objectives](#2-project-objectives)
* [3. System Architecture](#3-system-architecture)
* [4. Main Components](#4-main-components)
* [5. APB Interface](#5-apb-interface)
* [6. APB Register Map](#6-apb-register-map)
* [7. I²C Interface](#7-i2c-interface)
* [8. I²C Transaction Format](#8-i2c-transaction-format)
* [9. I²C Write Transaction](#9-i2c-write-transaction)
* [10. I²C Read Transaction](#10-i2c-read-transaction)
* [11. Open-Drain Bus](#11-open-drain-bus)
* [12. Clocking](#12-clocking)
* [13. Reset](#13-reset)
* [14. I²C Master](#14-i2c-master)
* [15. I²C Slave](#15-i2c-slave)
* [16. Master FSM](#16-master-fsm)
* [17. Slave FSM](#17-slave-fsm)
* [18. Internal Control Flow](#18-internal-control-flow)
* [19. Verification](#19-verification)
* [20. Verification Test Cases](#20-verification-test-cases)
* [21. Waveform Verification](#21-waveform-verification)
* [22. RTL and Design Methodology](#22-rtl-and-design-methodology)
* [23. FPGA Design Flow](#23-fpga-design-flow)
* [24. Repository Structure](#24-repository-structure)
* [25. Project Limitations](#25-project-limitations)
* [26. Future Improvements](#26-future-improvements)
* [27. Team](#27-team)
* [28. References](#28-references)

---

# 1. Project Overview

Modern digital systems frequently contain multiple peripherals that need to exchange configuration and data. Rather than exposing the I²C protocol directly to a processor, this project places an **APB register interface** in front of an I²C Master.

The resulting architecture allows software or an APB testbench to control the I²C peripheral using ordinary register accesses:

```text
                 APB Bus Master
                      |
                      | APB
                      v
             +-------------------+
             |   APB REGISTER    |
             |      BLOCK        |
             +---------+---------+
                       |
                       | Control / Configuration
                       v
             +-------------------+
             |    I²C MASTER      |
             |                    |
             | START              |
             | ADDRESS            |
             | ACK/NACK            |
             | WRITE / READ        |
             | STOP               |
             +---------+----------+
                       |
                 SDA / SCL
                       |
              +--------+--------+
              |                 |
              v                 v
        +-----------+     +-----------+
        | I²C BUS   |     | I²C SLAVE |
        | Open Drain|     |    FSM    |
        +-----------+     +-----------+
              |
              v
       Verification Monitor
       / Scoreboard / TB
```

The APB side configures the transaction, while the I²C Master independently performs the serial protocol. This separation keeps the bus protocol logic independent from the processor-facing register interface. 

The included I²C Slave provides a controlled endpoint for simulation, allowing complete Master-to-Slave and Slave-to-Master transactions to be verified.

---

# 2. Project Objectives

The main objectives of the project are:

* Implement a **synthesizable APB-controlled peripheral**.
* Implement an **I²C Master controller**.
* Implement an I²C Slave for functional verification.
* Provide memory-mapped configuration and status registers.
* Support standard I²C:

  * START
  * STOP
  * 7-bit addressing
  * Read/Write bit
  * ACK/NACK
  * 8-bit data
  * MSB-first transmission
* Implement shared **open-drain SDA and SCL behavior**.
* Generate a nominal **100 kHz I²C clock** from a **50 MHz system clock**.
* Develop a self-checking simulation environment.
* Verify normal and error transactions.
* Perform RTL compilation, linting, synthesis, and FPGA-oriented implementation where available.

The project specification intentionally keeps the implementation focused on a small, reusable RTL IP block rather than implementing advanced I²C features. 

---

# 3. System Architecture

The complete system is divided into several independent RTL blocks.

```text
                        APB MASTER
                       / TESTBENCH
                            |
                            | PCLK
                            | APB Transactions
                            v
                  +---------------------+
                  |   APB I²C REGISTERS |
                  |                     |
                  | CTRL                |
                  | STATUS              |
                  | SLAVE_ADDR          |
                  | TX_DATA             |
                  | RX_DATA             |
                  | CLK_DIV             |
                  | INT_STATUS          |
                  | VERSION             |
                  +----------+----------+
                             |
                     Control / Status
                             |
                             v
                  +---------------------+
                  |      I²C MASTER     |
                  |                     |
                  | Master FSM          |
                  | Address Generator   |
                  | TX/RX Shift Logic   |
                  | ACK Detection       |
                  +----------+----------+
                             |
                       Drive Low / Release
                             |
                       +-----+-----+
                       |           |
                      SDA         SCL
                       |           |
                       +-----+-----+
                             |
                       Shared I²C Bus
                             |
                             v
                  +---------------------+
                  |      I²C SLAVE      |
                  |                     |
                  | Slave FSM           |
                  | Address Detection   |
                  | RX/TX Logic         |
                  | ACK Generation      |
                  +---------------------+
```

The APB register block does **not** directly control individual I²C FSM states. Instead, it provides configuration and generates a transaction-start command. The I²C Master then executes the transaction independently. 

---

# 4. Main Components

The project is organized around the following components.

| Module          | Purpose                                         |
| --------------- | ----------------------------------------------- |
| `apb_i2c_regs`  | APB interface and memory-mapped register bank   |
| `i2c_master`    | Generates and controls I²C transactions         |
| `i2c_slave`     | Simulated I²C Slave used for verification       |
| `i2c_clock_gen` | Generates the I²C timing from the system clock  |
| `i2c_bus`       | Models the shared open-drain I²C bus            |
| `apb_i2c_top`   | Integrates the complete peripheral              |
| Testbench       | Drives APB transactions and verifies the design |
| I²C monitor     | Observes bus-level protocol activity            |
| Scoreboard      | Compares expected and received transaction data |

The exact implementation may combine or separate some of these responsibilities depending on the final RTL structure.

---

# 5. APB Interface

The peripheral uses an **APB4-style synchronous interface**.

APB is a simple, non-pipelined peripheral interface intended for accessing programmable control registers. An APB transfer consists of a **SETUP phase** followed by an **ACCESS phase**, with `PREADY` controlling completion. 

### APB interface

```systemverilog
input         PCLK;
input         PRESETn;
input  [11:0] PADDR;
input         PSEL;
input         PENABLE;
input         PWRITE;
input  [31:0] PWDATA;

output [31:0] PRDATA;
output        PREADY;
output        PSLVERR;
```

### APB transfer

A typical write transaction is:

```text
             SETUP             ACCESS
              |                  |
PCLK       __/‾\__/‾\__/‾\__/‾\__/‾\__
PSEL       ____/‾‾‾‾‾‾‾‾‾‾‾‾\________
PENABLE    ________/‾‾‾‾‾‾‾‾‾\________
PWRITE     ____/‾‾‾‾‾‾‾‾‾‾‾‾\________
PADDR      ==== ADDRESS =================
PWDATA     ==== DATA ====================
PREADY     ________/‾‾‾‾‾‾‾‾‾\________
```

During the SETUP phase:

```text
PSEL    = 1
PENABLE = 0
```

During the ACCESS phase:

```text
PSEL    = 1
PENABLE = 1
```

The peripheral normally completes register accesses without inserting wait states by asserting `PREADY`. APB requires address, direction, and write data to remain stable throughout an extended ACCESS phase if `PREADY` is low. 

---

# 6. APB Register Map

The peripheral uses the following memory-mapped register layout.

| Address | Register     | Access                     | Description                     |
| ------: | ------------ | -------------------------- | ------------------------------- |
|  `0x00` | `CTRL`       | R/W                        | I²C transaction control         |
|  `0x04` | `STATUS`     | R                          | I²C status                      |
|  `0x08` | `SLAVE_ADDR` | R/W                        | 7-bit I²C slave address         |
|  `0x0C` | `TX_DATA`    | R/W                        | Data transmitted during write   |
|  `0x10` | `RX_DATA`    | R                          | Data received during read       |
|  `0x14` | `CLK_DIV`    | R/W                        | I²C clock divider configuration |
|  `0x18` | `INT_STATUS` | R/W/implementation-defined | Simple event/status register    |
|  `0x1C` | `VERSION`    | R                          | Constant version identifier     |

This register map is defined by the project specification. 

---

## CTRL — `0x00`

Controls the next I²C transaction.

|      Bit | Name     | Description                 |
| -------: | -------- | --------------------------- |
|    `[0]` | `START`  | Launches an I²C transaction |
|    `[1]` | `RW`     | `0 = WRITE`, `1 = READ`     |
| `[31:2]` | Reserved | Reserved                    |

`START` is treated as a **command**, not as a persistent state. An APB write with `START = 1` generates a one-cycle internal start pulse.

---

## STATUS — `0x04`

Provides the current I²C controller status.

|      Bit | Name           | Description                       |
| -------: | -------------- | --------------------------------- |
|    `[0]` | `BUSY`         | I²C transaction currently active  |
|    `[1]` | `DONE`         | Transaction completion indication |
|    `[2]` | `ACK_ERROR`    | ACK was not received              |
|    `[3]` | `BUS_ERROR`    | I²C bus error indication          |
|    `[4]` | `I2C_BUS_BUSY` | Indicates I²C master bus activity |
| `[31:5]` | Reserved       | Reserved                          |

The APB interface allows software or a testbench to poll `BUSY` and `DONE` rather than holding an APB transaction open for the entire I²C transfer. 

---

## SLAVE_ADDR — `0x08`

Contains the 7-bit I²C address.

```text
31                       7 6       0
+-------------------------+---------+
|        Reserved         |  Address |
+-------------------------+---------+
```

```text
SLAVE_ADDR[6:0] = I²C 7-bit address
```

---

## TX_DATA — `0x0C`

Contains the byte transmitted by the I²C Master during a write transaction.

```text
TX_DATA[7:0] = transmitted byte
```

---

## RX_DATA — `0x10`

Contains the byte received by the I²C Master during a read transaction.

```text
RX_DATA[7:0] = received byte
```

The CPU/APB master can read this register after the I²C transaction has completed.

---

## CLK_DIV — `0x14`

Controls the I²C clock generation.

The default configuration targets:

```text
System clock = 50 MHz
I²C clock    = 100 kHz
```

---

## VERSION — `0x1C`

A read-only constant identifying the RTL version.

The project specification gives:

```text
32'h0001_0000
```

---

# 7. I²C Interface

The I²C bus uses two shared signals:

### SDA — Serial Data

Carries:

* slave address
* Read/Write bit
* data
* ACK/NACK

### SCL — Serial Clock

Synchronizes the transfer.

The supplied I²C project specifies a **50 MHz FPGA system clock** and a nominal **100 kHz I²C clock**, with the Slave observing the generated SCL rather than generating its own clock. 

---

# 8. I²C Transaction Format

The implemented controller supports:

* 7-bit addressing
* 8-bit data
* MSB-first transmission
* single Master
* single verification Slave
* write transactions
* read transactions
* ACK/NACK
* START
* STOP

The basic transaction format is:

### Write

```text
START
  |
  v
7-bit Address + WRITE
  |
  v
ACK
  |
  v
8-bit Data
  |
  v
ACK
  |
  v
STOP
```

### Read

```text
START
  |
  v
7-bit Address + READ
  |
  v
ACK
  |
  v
8-bit Data from Slave
  |
  v
Master NACK
  |
  v
STOP
```

For this project, one data byte per transaction is sufficient. Multi-byte transfers and FIFO-based buffering are outside the frozen project scope. 

---

# 9. I²C Write Transaction

A write operation proceeds as follows:

1. The APB master configures `SLAVE_ADDR`.
2. The APB master writes the data to `TX_DATA`.
3. The APB master writes `CTRL` with:

   ```text
   RW    = 0
   START = 1
   ```
4. The register block generates a one-cycle `master_start` pulse.
5. The I²C Master generates a START condition.
6. The Master transmits:

   ```text
   [7-bit slave address] + [R/W = 0]
   ```
7. The Slave acknowledges the address.
8. The Master transmits the 8-bit data.
9. The Slave acknowledges the data.
10. The Master generates STOP.
11. `DONE` is asserted.
12. `BUSY` returns low.
13. The Slave's received-data register contains the transmitted byte.

Example:

```text
APB:
    SLAVE_ADDR = 0x50
    TX_DATA    = 0xA5
    RW         = WRITE
    START      = 1

I²C:
    START
    0x50 + W
    ACK
    0xA5
    ACK
    STOP

STATUS:
    BUSY       = 0
    DONE       = 1
    ACK_ERROR  = 0
```

This flow is explicitly defined in the project specification. 

---

# 10. I²C Read Transaction

A read operation reverses the direction of the data phase.

1. The Slave contains a known data byte.
2. The APB master configures the Slave address.
3. The APB master sets:

   ```text
   RW = 1
   START = 1
   ```
4. The I²C Master generates START.
5. The Master transmits:

   ```text
   slave address + READ
   ```
6. The Slave acknowledges.
7. The Slave transmits its stored byte.
8. The Master samples the data.
9. The Master generates a NACK because only one byte is requested.
10. The Master generates STOP.
11. The received byte is stored in `RX_DATA`.
12. `DONE` is asserted.

Example:

```text
I²C:
    START
    0x50 + R
    ACK
    0xA5
    NACK
    STOP

APB:
    RX_DATA = 0xA5
```

---

# 11. Open-Drain Bus

I²C uses shared open-drain signaling.

Neither Master nor Slave actively drives a logic HIGH onto SDA. Instead, each device can either:

```text
Drive LOW
    or
Release the line
```

A pull-up resistor causes the bus to become HIGH when no device is pulling it LOW.

Conceptually:

```text
drive_low = 1  ->  Bus = 0
drive_low = 0  ->  Bus = Z / pulled HIGH
```

The simulated bus therefore combines the Master and Slave drive signals:

```systemverilog
tri1 SDA;
tri1 SCL;

assign SDA = master_sda_drive_low ? 1'b0 : 1'bz;
assign SDA = slave_sda_drive_low  ? 1'b0 : 1'bz;

assign SCL = master_scl_drive_low ? 1'b0 : 1'bz;
assign SCL = slave_scl_drive_low  ? 1'b0 : 1'bz;
```

This models the shared nature of the I²C bus and allows multiple devices to pull the bus LOW without creating push-pull contention.

The open-drain behavior and bus model are part of the project specification. 

---

# 12. Clocking

The main system clock is:

```text
PCLK = 50 MHz
```

The target I²C clock is:

```text
SCL = 100 kHz
```

The I²C clock generation is therefore derived from the system clock using a configurable divider/clock-generation mechanism.

The preferred design approach is to use a clock-enable/timing mechanism rather than unnecessarily creating additional internal clock domains. The I²C Slave does not require an independent clock generator; it observes the SCL bus generated by the Master. 

---

# 13. Reset

The APB interface uses the standard active-low APB reset:

```text
PRESETn
```

On reset:

* APB interface returns to its idle condition.
* APB registers are initialized.
* I²C Master returns to `IDLE`.
* I²C Slave returns to `IDLE`.
* `BUSY` is cleared.
* `DONE` is cleared.
* Error status is cleared.
* SDA is released.
* SCL is released.

The APB specification defines `PRESETn` as an active-low reset signal. 

---

# 14. I²C Master

The I²C Master is responsible for controlling all bus transactions.

Its primary responsibilities are:

* Generate START.
* Generate STOP.
* Transmit the slave address.
* Transmit the R/W bit.
* Detect address ACK/NACK.
* Transmit write data.
* Detect data ACK/NACK.
* Receive read data.
* Generate Master ACK/NACK.
* Report transaction completion.
* Report ACK errors.
* Control the open-drain SDA/SCL outputs.

Conceptual interface:

```systemverilog
module i2c_master (
    input        clk,
    input        rst,
    input        start,
    input        rw,
    input  [6:0] slave_addr,
    input  [7:0] tx_data,

    output [7:0] rx_data,
    output       busy,
    output       done,
    output       ack_error,

    input        scl_in,
    input        sda_in,

    output       scl_drive_low,
    output       sda_drive_low
);
```

The Master operates independently once the APB register block launches a transaction.

---

# 15. I²C Slave

The I²C Slave is included to provide a real protocol endpoint for simulation.

Its responsibilities include:

* Detect START.
* Receive the slave address.
* Compare the address with its configured address.
* Generate address ACK.
* Receive write data.
* Generate data ACK.
* Transmit stored data during read transactions.
* Detect Master ACK/NACK.
* Detect STOP.
* Detect repeated START.
* Maintain the received data register.

Conceptual interface:

```systemverilog
module i2c_slave (
    input        clk,
    input        rst,
    input        scl_in,
    input        sda_in,

    output       sda_drive_low,
    output [7:0] rx_data
);
```

The supplied I²C project describes the Slave as a bus-monitoring FSM that only responds after detecting its assigned address. 

---

# 16. Master FSM

The Master is implemented as a finite state machine.

A possible state organization is:

```text
                    +------+
                    | IDLE |
                    +--+---+
                       |
                     START
                       |
                       v
                +-------------+
                | SEND_ADDR   |
                +------+------+
                       |
                       v
                +-------------+
                |  ADDR_ACK   |
                +------+------+
                       |
             +---------+---------+
             |                   |
           WRITE                READ
             |                   |
             v                   v
       +-----------+       +-----------+
       |WRITE_DATA |       | READ_DATA |
       +-----+-----+       +-----+-----+
             |                   |
             v                   v
       +-----------+       +-----------+
       | DATA_ACK  |       |MASTER_ACK |
       +-----+-----+       +-----+-----+
             |                   |
             +---------+---------+
                       |
                       v
                  +---------+
                  |  STOP   |
                  +----+----+
                       |
                       v
                  +---------+
                  |  DONE   |
                  +----+----+
                       |
                       v
                    IDLE
```

The implementation may split START and STOP into multiple states when necessary to guarantee correct SDA/SCL timing.

Important protocol constraints include:

* SDA changes while SCL is LOW.
* SDA is sampled while SCL is HIGH.
* START occurs when SDA transitions HIGH → LOW while SCL is HIGH.
* STOP occurs when SDA transitions LOW → HIGH while SCL is HIGH.

These timing relationships are described in the supplied I²C project documentation. 

---

# 17. Slave FSM

The Slave FSM consists conceptually of:

```text
IDLE
  |
  v
RECV_ADDR
  |
  v
ADDR_ACK
  |
  +------------+
  |            |
 WRITE        READ
  |            |
  v            v
WRITE_DATA   READ_DATA
  |            |
  v            v
DATA_ACK     READ_ACK
  |            |
  +------> WAIT_STOP
              |
              v
             IDLE
```

### Slave states

| State        | Function                         |
| ------------ | -------------------------------- |
| `IDLE`       | Wait for START                   |
| `RECV_ADDR`  | Receive 7-bit address + R/W      |
| `ADDR_ACK`   | Compare address and generate ACK |
| `WRITE_DATA` | Receive an 8-bit byte            |
| `DATA_ACK`   | Acknowledge received byte        |
| `READ_DATA`  | Transmit stored byte             |
| `READ_ACK`   | Receive Master ACK/NACK          |
| `WAIT_STOP`  | Wait for STOP or repeated START  |

A wrong address causes the Slave to avoid acknowledging the transaction and wait for the transaction to terminate. A repeated START can return the Slave to address reception without first returning to the idle state. 

---

# 18. Internal Control Flow

The complete control path is:

```text
          APB WRITE
              |
              v
       +--------------+
       | CTRL Register|
       +------+-------+
              |
         START Pulse
              |
              v
       +--------------+
       |  I²C Master  |
       +------+-------+
              |
          SDA / SCL
              |
              v
       +--------------+
       |  I²C Slave   |
       +------+-------+
              |
          Received Data
              |
              v
       +--------------+
       | Status/RX Reg|
       +------+-------+
              |
              v
          APB READ
```

### Example write

```text
APB Write 0x08 = 0x50
        |
        v
SLAVE_ADDR = 0x50

APB Write 0x0C = 0xA5
        |
        v
TX_DATA = 0xA5

APB Write 0x00 = START + WRITE
        |
        v
Master starts transaction
        |
        v
START → 50+W → ACK → A5 → ACK → STOP
        |
        v
DONE = 1
```

### Example read

```text
Slave contains 0xA5
        |
        v
APB configures RW = READ
        |
        v
START
        |
        v
50 + R
        |
        v
ACK
        |
        v
Slave sends A5
        |
        v
Master NACK
        |
        v
STOP
        |
        v
RX_DATA = A5
```

---

# 19. Verification

Verification is performed using a **self-checking Verilog/SystemVerilog testbench**.

The testbench is responsible for:

* Generating `PCLK`.
* Applying reset.
* Driving APB transactions.
* Configuring the peripheral.
* Launching I²C transactions.
* Monitoring the I²C bus.
* Checking Master status.
* Checking Slave received data.
* Comparing expected and received data.
* Detecting ACK errors.
* Performing randomized transactions.
* Producing automated PASS/FAIL results.

The verification architecture is conceptually:

```text
                  +----------------+
                  | APB Stimulus   |
                  | Tasks          |
                  +-------+--------+
                          |
                          v
                    +-----------+
                    |    DUT    |
                    +-----+-----+
                          |
                     SDA / SCL
                          |
              +-----------+-----------+
              |                       |
              v                       v
        I²C Monitor              Scoreboard
              |                       |
              +-----------+-----------+
                          |
                          v
                     PASS / FAIL
```

The supplied project specification explicitly requires a self-checking testbench rather than relying solely on manually inspected waveforms. 

---

# 20. Verification Test Cases

The planned verification suite includes the following tests.

| Test                | Description                                |
| ------------------- | ------------------------------------------ |
| Reset               | Verify reset and initial states            |
| Single Write        | Write `0xA5` to the Slave                  |
| Single Read         | Read known data from the Slave             |
| Multiple Writes     | Write `00`, `FF`, `55`, `AA`               |
| Multiple Reads      | Read and compare known values              |
| Wrong Address       | Verify NACK and error handling             |
| Random Transactions | Perform randomized read/write transactions |

For example, the random test should perform at least ten randomized transactions according to the project verification plan. 

A successful regression should produce output similar to:

```text
==========================================
       APB-I2C VERIFICATION START
==========================================

TEST 1: RESET
PASS

TEST 2: WRITE 0xA5
PASS

TEST 3: READ 0xA5
PASS

TEST 4: MULTIPLE WRITE
PASS

TEST 5: MULTIPLE READ
PASS

TEST 6: WRONG ADDRESS
PASS

TEST 7: RANDOM TRANSACTIONS
PASS

==========================================
TOTAL TESTS : 7
PASSED      : 7
FAILED      : 0
==========================================
```

Real verification failures should cause the testbench to report failure using `$fatal` or an equivalent mechanism.

---

# 21. Waveform Verification

Waveforms are used as a secondary verification and debugging tool.

The primary waveform should focus on the important APB and I²C signals rather than displaying every internal signal.

Recommended signals include:

```text
PCLK
PSEL
PENABLE
PWRITE
PADDR
PWDATA
PRDATA
PREADY

SCL
SDA

master_state
slave_state

BUSY
DONE
ACK_ERROR

TX_DATA
RX_DATA
slave_rx_data
```

Important waveform sections include:

### APB

* Register write
* Register read
* START command
* STATUS readback

### I²C Write

```text
START
Address + R/W
ACK
Data
ACK
STOP
```

### I²C Read

```text
START
Address + R/W
ACK
Slave Data
Master NACK
STOP
RX_DATA
```

The supplied course project also uses QuestaSim waveforms to demonstrate address transmission, data transfer, acknowledgements, and received data. 

---

# 22. RTL and Design Methodology

The project follows a modular RTL design methodology.

### Design principles

* Synthesizable RTL.
* Clear module boundaries.
* Meaningful signal names.
* Explicit FSM states.
* No unnecessary clock domains.
* No unsynthesizable constructs inside the DUT.
* No `force`/`release` in synthesizable RTL.
* Testbench-specific constructs remain in the testbench.
* Avoid unnecessary monolithic modules.
* Parameterize timing-related values where useful.

Particular attention should be given to:

* FSM transitions.
* Bit-counter boundaries.
* ACK timing.
* START timing.
* STOP timing.
* Open-drain behavior.
* Reset behavior.
* APB SETUP/ACCESS timing.
* Status register behavior.
* SDA/SCL bus contention.

These requirements are part of the project's RTL design guidelines. 

---

# 23. FPGA Design Flow

The project is designed to be compatible with a standard FPGA-oriented RTL flow:

```text
       RTL Source
           |
           v
       Compilation
           |
           v
       Elaboration
           |
           v
          Lint
           |
           v
     RTL Simulation
           |
           v
       Synthesis
           |
           v
 FPGA Implementation
   / Place & Route
           |
           v
 Utilization / Timing
       Reports
```

Depending on the available FPGA toolchain, the project can produce:

* synthesis reports
* utilization reports
* timing reports
* synthesized schematics
* implementation reports

The project does **not** require physical FPGA programming.

> **Important:** RTL simulation and FPGA synthesis/implementation are software-based verification and design-flow steps. They do not constitute physical hardware validation.

No physical FPGA board was available for this project, so no physical board testing or bitstream programming was performed. This limitation is explicitly defined in the project specification. 

---

# 24. Repository Structure

The recommended repository structure is:

```text
APB-Controlled-I2C/
│
├── rtl/
│   ├── apb_i2c_regs.sv
│   ├── i2c_master.sv
│   ├── i2c_slave.sv
│   ├── i2c_clock_gen.sv
│   ├── i2c_bus.sv
│   └── apb_i2c_top.sv
│
├── tb/
│   ├── tb_apb_i2c.sv
│   ├── apb_tasks.sv
│   ├── i2c_monitor.sv
│   ├── scoreboard.sv
│   └── assertions.sv
│
├── sim/
│   └── wave.do
│
├── docs/
│   ├── architecture.md
│   ├── register_map.md
│   └── verification_plan.md
│
├── reports/
│   ├── synthesis/
│   ├── implementation/
│   ├── timing/
│   └── utilization/
│
├── README.md
└── .gitignore
```

The project specification recommends separating RTL, testbench, simulation, documentation, and FPGA-flow reports in this manner. 

---

# 25. Project Limitations

The current project intentionally has a limited scope.

### Implemented scope

* APB register interface
* 32-bit APB data path
* 7-bit I²C addressing
* 8-bit data
* Single I²C Master
* Single verification Slave
* Standard-mode 100 kHz target
* START
* STOP
* ACK
* NACK
* Read
* Write
* Open-drain bus behavior
* Configurable Slave address
* TX/RX data registers
* BUSY/DONE status
* ACK error reporting
* Self-checking verification

### Not included

The following features are outside the current project scope:

* Multi-master arbitration
* 10-bit I²C addressing
* SMBus
* I3C
* DMA
* Hardware FIFO
* Complex interrupt controller
* Clock stretching
* High-speed I²C
* Fast-mode Plus
* Dynamic multi-slave enumeration
* Physical FPGA-board validation
* FPGA bitstream programming

These are intentionally excluded to keep the design manageable and fully verifiable within the project timeframe. 

---

# 26. Future Improvements

Possible extensions include:

### Multi-byte transfers

Replace the single-byte TX/RX registers with a FIFO-based architecture:

```text
APB
 |
 v
TX FIFO ---> I²C Master ---> SDA/SCL
                    |
                    v
               I²C Slave
                    |
                    v
                 RX FIFO
                    |
                    v
                   APB
```

This would allow software to queue multiple bytes without requiring an APB access for every individual byte.

### Additional I²C features

Potential future extensions include:

* Clock stretching
* Multi-master arbitration
* 10-bit addressing
* Repeated-start transactions
* Multiple I²C Slaves
* Programmable SCL frequency
* Multi-byte transactions
* FIFO buffering
* Interrupt generation
* Bus error detection
* Timeout handling

### Hardware validation

With a suitable FPGA board and external I²C device, the design could eventually be validated against physical hardware.

---

# 27. Team

This project was developed as part of the **NTI Digital Design / FPGA training**.

### Team Members

| Member                         |
| ------------------------------ |
| Ahmed Wael Sadek ElSawy        |
| Omar Ahmed Gamal Abdo          |
| Youssef Hatem Abdeljalil       |
| Youssef Mohammed Zainelabedeen |
| Zeyad Hany Mahmoud             |

---

# 28. References

### AMBA APB

**Arm AMBA APB Protocol Specification, ARM IHI 0024D, Issue D**

The APB specification was used as the reference for:

* APB signals
* SETUP/ACCESS operation
* `PREADY`
* `PSLVERR`
* APB register-access behavior
* APB operating states



### I²C Protocol

**I²C Communication Protocol — Digital IC Design Using FPGA Course Project, NTI**

The supplied I²C project was used as a reference for:

* I²C Master/Slave architecture
* SDA/SCL operation
* Open-drain signaling
* START/STOP conditions
* ACK/NACK
* Read/write transactions
* Master and Slave FSM concepts
* Verification methodology



### Project Specification

**APB-Controlled I2C Master with I2C Slave — RTL Design, Verification, and FPGA Flow**

This document defines the project architecture, scope, register map, module interfaces, verification strategy, test plan, repository structure, and FPGA design-flow requirements. 

---

## Project Status

The intended final deliverable is a modular RTL IP block with:

```text
                 APB
                  |
                  v
          +---------------+
          | APB Registers |
          +-------+-------+
                  |
                  v
          +---------------+
          |  I²C Master   |
          +-------+-------+
                  |
               SDA/SCL
                  |
                  v
          +---------------+
          |   I²C Slave   |
          +---------------+
                  |
                  v
            Verification
```

The design target is:

**Synthesizable → Simulated → Self-Checked → Linted → Synthesis-Ready → Implementation-Ready**

with **no claim of physical FPGA validation or board programming**.

---

### License

This project is intended for **educational purposes** and was developed as part of NTI digital design/FPGA training.
