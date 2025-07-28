// Top module - Digital Clock

module digiclk(
    input wire clk, rst,
    input wire time_set,       //switch
    input wire inc_hr, dec_hr, inc_min, dec_min,    //push button
    output reg [6:0] Disp_Val,    //7seg
    output reg [7:0] Disp_Seg,     //AN
    output wire dp
);

    assign dp = 1;

    // Internal registers for time keeping
    reg [5:0] outh, outm, outs;           // Current time (removed seconds)
    reg clk_1;                      // 1Hz clock
    reg [26:0] counter;             // Counter for 1Hz clock generation
    reg [15:0] CntRec;              // Counter for display refresh
    
    // Wires for 7-segment display values
    wire [6:0] outsegm1, outsegm2;  // Minutes display
    wire [6:0] outsegh1, outsegh2;  // Hours display
    
    // 1Hz clock generation
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            clk_1 <= 0;
            counter <= 0;   
        end else if(counter == 27'd49999999) begin
            clk_1 <= ~clk_1;
            counter <= 27'd0;
        end else counter <= counter + 1;  
    end

    // Display refresh counter
    always @(posedge clk or posedge rst) begin
        if(rst)
            CntRec <= 16'd0;
        else
            CntRec <= CntRec + 1;
    end

    // Alarm and Time Setting Logic
    always @(posedge clk_1) begin
        if(rst) begin
            outh <= 6'd0;
            outm <= 6'd0;
        end else if(time_set) begin
            // Hour increment/decrement
            if(inc_hr) begin
                outh <= (outh == 6'd23) ? 6'd0 : outh + 1;
            end else if(dec_hr) begin
                outh <= (outh == 6'd0) ? 6'd23 : outh - 1;
            end

            // Minute increment/decrement
            if(inc_min) begin
                outm <= (outm == 6'd59) ? 6'd0 : outm + 1;
            end else if(dec_min) begin
                outm <= (outm == 6'd0) ? 6'd59 : outm - 1;
            end
        end 
             // Normal time progression (unchanged)
            if(outs == 6'd59) begin
                outs <= 6'd0;
                    if(outm == 6'd59) begin
                        outm <= 6'd0;
                        outh <= (outh == 6'd23) ? 6'd0 : outh + 1;
                    end else
                        outm <= outm + 1;
                    end else
                        outs <= outs + 1;
            end
    
    // BCD conversion instances
    wire [3:0] bcd_m0, bcd_m1;
    wire [3:0] bcd_h0, bcd_h1;


    bin2bcd conv_min  (.bin(outm),  .bcd0(bcd_m0), .bcd1(bcd_m1));
    bin2bcd conv_hour (.bin(outh),  .bcd0(bcd_h0), .bcd1(bcd_h1));

    // 7-segment conversion instances
    bcd2seg conv_m1(.bcd(bcd_m0), .outseg(outsegm1));
    bcd2seg conv_m2(.bcd(bcd_m1), .outseg(outsegm2));
    bcd2seg conv_h1(.bcd(bcd_h0), .outseg(outsegh1));
    bcd2seg conv_h2(.bcd(bcd_h1), .outseg(outsegh2));


    // Display multiplexing
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            Disp_Val <= 7'd0;
            Disp_Seg <= 8'd0;
        end else begin
            if(CntRec == 16'd16384)
                begin  // Minutes digit 1
                        Disp_Val <= outsegm1;
                        Disp_Seg <= 8'b11111110;
            end else if(CntRec == 16'd32768)
                begin  // Minutes digit 2
                        Disp_Val <= outsegm2;
                        Disp_Seg <= 8'b11111101;
            end else if(CntRec == 16'd49152)
                begin  // Hours digit 1
                        Disp_Val <= outsegh1;
                        Disp_Seg <= 8'b11111011;
            end else if(CntRec == 16'd65535)
                begin  // Hours digit 2
                        Disp_Val <= outsegh2;
                        Disp_Seg <= 8'b11110111;
            end
        end
    end

endmodule


module bcd2seg(
    input [3:0] bcd,
    output reg [6:0] outseg  );

    always @(*) begin
        case(bcd)
          4'd0: outseg=7'b1000000;
          4'd1: outseg=7'b1111001;
          4'd2: outseg=7'b0100100;
          4'd3: outseg=7'b0110000;  
          4'd4: outseg=7'b0011001;
          4'd5: outseg=7'b0010010;
          4'd6: outseg=7'b0000010;
          4'd7: outseg=7'b1111000;
          4'd8: outseg=7'b0000000;
          4'd9: outseg=7'b0010000;
          default: outseg=7'b0000000;
        endcase
    end
endmodule

module bin2bcd (
    input [5:0] bin,
    output reg [3:0] bcd0,
    output reg [3:0] bcd1
);

always @(*) begin
    case (bin)
    6'd0: begin bcd1 <= 4'b0000; bcd0 <= 4'b0000; end
    6'd1: begin bcd1 <= 4'b0000; bcd0 <= 4'b0001; end
    6'd2: begin bcd1 <= 4'b0000; bcd0 <= 4'b0010; end
    6'd3: begin bcd1 <= 4'b0000; bcd0 <= 4'b0011; end
    6'd4: begin bcd1 <= 4'b0000; bcd0 <= 4'b0100; end
    6'd5: begin bcd1 <= 4'b0000; bcd0 <= 4'b0101; end
    6'd6: begin bcd1 <= 4'b0000; bcd0 <= 4'b0110; end
    6'd7: begin bcd1 <= 4'b0000; bcd0 <= 4'b0111; end
    6'd8: begin bcd1 <= 4'b0000; bcd0 <= 4'b1000; end
    6'd9: begin bcd1 <= 4'b0000; bcd0 <= 4'b1001; end
    6'd10: begin bcd1 <= 4'b0001; bcd0 <= 4'b0000; end
    6'd11: begin bcd1 <= 4'b0001; bcd0 <= 4'b0001; end
    6'd12: begin bcd1 <= 4'b0001; bcd0 <= 4'b0010; end
    6'd13: begin bcd1 <= 4'b0001; bcd0 <= 4'b0011; end
    6'd14: begin bcd1 <= 4'b0001; bcd0 <= 4'b0100; end
    6'd15: begin bcd1 <= 4'b0001; bcd0 <= 4'b0101; end
    6'd16: begin bcd1 <= 4'b0001; bcd0 <= 4'b0110; end
    6'd17: begin bcd1 <= 4'b0001; bcd0 <= 4'b0111; end
    6'd18: begin bcd1 <= 4'b0001; bcd0 <= 4'b1000; end
    6'd19: begin bcd1 <= 4'b0001; bcd0 <= 4'b1001; end
    6'd20: begin bcd1 <= 4'b0010; bcd0 <= 4'b0000; end
    6'd21: begin bcd1 <= 4'b0010; bcd0 <= 4'b0001; end
    6'd22: begin bcd1 <= 4'b0010; bcd0 <= 4'b0010; end
    6'd23: begin bcd1 <= 4'b0010; bcd0 <= 4'b0011; end
    6'd24: begin bcd1 <= 4'b0010; bcd0 <= 4'b0100; end
    6'd25: begin bcd1 <= 4'b0010; bcd0 <= 4'b0101; end
    6'd26: begin bcd1 <= 4'b0010; bcd0 <= 4'b0110; end
    6'd27: begin bcd1 <= 4'b0010; bcd0 <= 4'b0111; end
    6'd28: begin bcd1 <= 4'b0010; bcd0 <= 4'b1000; end
    6'd29: begin bcd1 <= 4'b0010; bcd0 <= 4'b1001; end
    6'd30: begin bcd1 <= 4'b0011; bcd0 <= 4'b0000; end
    6'd31: begin bcd1 <= 4'b0011; bcd0 <= 4'b0001; end
    6'd32: begin bcd1 <= 4'b0011; bcd0 <= 4'b0010; end
    6'd33: begin bcd1 <= 4'b0011; bcd0 <= 4'b0011; end
    6'd34: begin bcd1 <= 4'b0011; bcd0 <= 4'b0100; end
    6'd35: begin bcd1 <= 4'b0011; bcd0 <= 4'b0101; end
    6'd36: begin bcd1 <= 4'b0011; bcd0 <= 4'b0110; end
    6'd37: begin bcd1 <= 4'b0011; bcd0 <= 4'b0111; end
    6'd38: begin bcd1 <= 4'b0011; bcd0 <= 4'b1000; end
    6'd39: begin bcd1 <= 4'b0011; bcd0 <= 4'b1001; end
    6'd40: begin bcd1 <= 4'b0100; bcd0 <= 4'b0000; end
    6'd41: begin bcd1 <= 4'b0100; bcd0 <= 4'b0001; end
    6'd42: begin bcd1 <= 4'b0100; bcd0 <= 4'b0010; end
    6'd43: begin bcd1 <= 4'b0100; bcd0 <= 4'b0011; end
    6'd44: begin bcd1 <= 4'b0100; bcd0 <= 4'b0100; end
    6'd45: begin bcd1 <= 4'b0100; bcd0 <= 4'b0101; end
    6'd46: begin bcd1 <= 4'b0100; bcd0 <= 4'b0110; end
    6'd47: begin bcd1 <= 4'b0100; bcd0 <= 4'b0111; end
    6'd48: begin bcd1 <= 4'b0100; bcd0 <= 4'b1000; end
    6'd49: begin bcd1 <= 4'b0100; bcd0 <= 4'b1001; end
    6'd50: begin bcd1 <= 4'b0101; bcd0 <= 4'b0000; end
    6'd51: begin bcd1 <= 4'b0101; bcd0 <= 4'b0001; end
    6'd52: begin bcd1 <= 4'b0101; bcd0 <= 4'b0010; end
    6'd53: begin bcd1 <= 4'b0101; bcd0 <= 4'b0011; end
    6'd54: begin bcd1 <= 4'b0101; bcd0 <= 4'b0100; end
    6'd55: begin bcd1 <= 4'b0101; bcd0 <= 4'b0101; end
    6'd56: begin bcd1 <= 4'b0101; bcd0 <= 4'b0110; end
    6'd57: begin bcd1 <= 4'b0101; bcd0 <= 4'b0111; end
    6'd58: begin bcd1 <= 4'b0101; bcd0 <= 4'b1000; end
    6'd59: begin bcd1 <= 4'b0101; bcd0 <= 4'b1001; end
    6'd60: begin bcd1 <= 4'b0110; bcd0 <= 4'b0000; end
    default: begin bcd1 <= 4'b0000; bcd0 <= 4'b0000; end
    endcase

end

endmodule
