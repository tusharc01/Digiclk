# Digiclk

***

### 1. Clock Divider

The first core component is the **Clock Divider**. Its purpose is to take the high-frequency clock from the FPGA's oscillator, which is typically 50 or 100 MHz, and scale it down to a precise 1 Hz signal. This 1 Hz clock, which I've named `clk_1`, serves as the heartbeat for our timekeeping logic, ensuring that the seconds counter increments accurately once every second.

This is implemented using a simple counter. On every rising edge of the main system clock, the `counter` register increments. When it reaches a specific value—in this case, `49,999,999` for a 100 MHz input—it toggles the `clk_1` signal and resets itself. This division is fundamental for the clock's accuracy.

### 2. Time Counters and User Interface

The second part combines the **Time Counters** and the **User Interface** for setting the time. This logic is built inside a single process sensitive to the 1 Hz `clk_1` signal.

* **Normal Operation:** When the `time_set` switch is off, the module operates as a standard clock. On each tick of `clk_1`, the seconds counter (`outs`) increments. The logic includes the necessary rollover conditions: when seconds reach 59, they reset to 0 and increment the minutes (`outm`). Similarly, when minutes reach 59, they reset and increment the hours (`outh`), which is designed to roll over from 23 to 0 for a 24-hour format.

* **Time Setting:** When the user activates the `time_set` switch, the clock's behavior changes. The normal time progression is halted, and the push buttons (`inc_hr`, `dec_hr`, `inc_min`, `dec_min`) become active. These allow the user to directly modify the `outh` and `outm` registers. The logic correctly handles wrapping around; for example, incrementing the hour from 23 takes it to 0, and decrementing from 0 takes it to 23.


### 3. Display Driver: Data Conversion

For the third part, we have the **Display Driver**, which handles the crucial task of making the time visible. The time is stored in binary format in the `outh` and `outm` registers, which isn't suitable for a 7-segment display.



Therefore, we use a two-step conversion process:

1.  **Binary to BCD:** I've instantiated a `bin2bcd` module that converts the 6-bit binary values for hours and minutes into two 4-bit BCD (Binary-Coded Decimal) digits. For example, the binary value for 23 is converted into two BCD numbers: `0010` (2) and `0011` (3). This is implemented as a simple combinational lookup table.
2.  **BCD to 7-Segment:** Each of these BCD digits is then passed to a `bcd2seg` module. This module translates the 4-bit BCD digit into the 7-bit pattern required to light up the correct segments on the display. This is also pure combinational logic.

### 4. Display Driver: Multiplexing

Finally, to drive the four separate 7-segment display digits without needing four complete sets of output pins, I've implemented **Display Multiplexing**.

A high-speed counter, `CntRec`, continuously cycles through four states very rapidly. In each state, the logic performs two actions:
1.  It places the 7-segment pattern for one specific digit (e.g., the tens-of-hours digit) onto the `Disp_Val` output bus.
2.  It activates the corresponding single display digit by asserting its anode/cathode line via the `Disp_Seg` output.

This process switches between the four digits so quickly that, due to persistence of vision, the human eye perceives all four digits as being solidly lit at the same time, giving us a stable time display.


<p align="center">
  <img src="https://github.com/tusharc01/Digiclk/blob/main/FPGA_digiclk.jpeg" alt="FPGA_Digiclk" width="600"/>
</p>
