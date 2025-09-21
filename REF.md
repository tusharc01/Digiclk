Seven Segment Display

A seven-segment display is built from individual LED’s arranged in a figure-8 pattern as shown. Any LED/segment can be individually illuminated, so any one of 128 different patterns can be shown. The figure below shows segment illumination patterns for decimal and hexadecimal digits.

The Boolean board includes two 4-digit seven-segment displays (8 total digits) that use a common anode configuration. Segment LEDs consume about 3mA each (well within the current sourcing capability of the FPGA pins), so the cathodes are tied directly to FPGA pins. Since 24mA+ can flow through the anode signals, the anodes are driven from transistors that can provide the needed current (and the transistors are driven from the FPGA pins). All signals are active low.

To drive a single digit, the corresponding anode signal can be driven (low), and then individual cathodes can be driven (also low) to turn on individual segments. To drive all digits to create an eight-digit display, a scanning display controller is needed. To learn more about seven segment displays, including an example design of a seven-segment controller, see the “Seven segment controller” document:

Reference: https://www.realdigital.org/doc/586fb4c3326dcd493a5774b2a6050f41
