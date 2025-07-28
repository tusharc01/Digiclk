// Top module - Digital Clock
module digiclk(
    input wire Gclk, rst,
    input wire time_set, alarm_set, alarm_on,       //switches
    input wire inc_hr, dec_hr, inc_min, dec_min,    //push button
    output reg alarm_out,         //led
    output reg [7:0] Disp_Val,    //7seg
    output reg [7:0] Disp_Seg     //AN
);
    // Internal registers for time keeping
    reg [5:0] outh, outm, outs;           // Current time
    reg [5:0] alarmh, alarmm;             // Alarm time
    reg clk;                              // 1Hz clock
    reg [26:0] counter;                  // Counter for 1Hz clock generation
    reg [15:0] CntRec;                    // Counter for display refresh
    
    // Wires for 7-segment display values
    wire [6:0] outsegs1, outsegs2;        // Seconds display
    wire [6:0] outsegm1, outsegm2;        // Minutes display
    wire [6:0] outsegh1, outsegh2;        // Hours display
    wire [6:0] outsegs1_a, outsegs2_a;    // Alarm seconds display
    wire [6:0] outsegm1_a, outsegm2_a;    // Alarm minutes display
    wire [6:0] outsegh1_a, outsegh2_a;    // Alarm hours display

    // 1Hz clock generation
    always @(posedge Gclk, posedge rst) begin
        if(rst) begin
            clk <= 0;
            counter <= 0;   
        end else if(counter == 27'd99999999) begin
            clk <= ~clk;
            counter <= 27'd0;
        end else counter <= counter + 1;  
    end

    // Display refresh counter
    always @(posedge Gclk or posedge rst) begin
        if(rst)
            CntRec <= 16'd0;
        else
            CntRec <= CntRec + 1;
    end

    // Alarm setting
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            alarmh <= 6'd0;
            alarmm <= 6'd0;
        end else if(alarm_set) begin
            if(inc_hr == 1'b1) begin
                if(alarmh == 6'd23) 
                    alarmh <= 6'd0;
                else 
                    alarmh <= alarmh + 1;
            end else if(inc_min == 1'b1) begin
                if(alarmm == 6'd59) 
                    alarmm <= 6'd0;
                else 
                    alarmm <= alarmm + 1;
            end else if(dec_hr == 1'b1) begin
                if(alarmh == 6'd0) 
                    alarmh <= 6'd23;
                else 
                    alarmh <= alarmh - 1;
            end else if(dec_min == 1'b1) begin
                if(alarmm == 6'd0) 
                    alarmm <= 6'd59;
                else 
                    alarmm <= alarmm - 1;
            end
        end
    end

    // Time setting
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            outh <= 6'd0;
            outm <= 6'd0;
            outs <= 6'd0;
        end else if(time_set) begin
            if(inc_hr == 1'b1) begin
                if(outh == 6'd23) 
                    outh <= 6'd0;
                else 
                    outh <= outh + 1;
            end else if(inc_min == 1'b1) begin
                if(outm == 6'd59) 
                    outm <= 6'd0;
                else 
                    outm <= outm + 1;
            end else if(dec_hr == 1'b1) begin
                if(outh == 6'd0) 
                    outh <= 6'd23;
                else 
                    outh <= outh - 1;
            end else if(dec_min == 1'b1) begin
                if(outm == 6'd0) 
                    outm <= 6'd59;
                else 
                    outm <= outm - 1;
            end
        end else begin
            // Normal time flow
            if(outs != 6'd59) 
                outs <= outs + 1;
            else begin 
                outs <= 6'd0;
                if(outm == 6'd59) begin
                    outm <= 6'd0;
                    if(outh == 6'd23)
                        outh <= 6'd0;
                    else
                        outh <= outh + 1;
                end else
                    outm <= outm + 1;   
            end
        end
    end

    // Alarm trigger
    always @(posedge clk or posedge rst) begin
        if(rst)
            alarm_out <= 0;
        else if((alarmh == outh) && (alarmm == outm) && (outs == 0) && alarm_on)
            alarm_out <= 1;
        else
            alarm_out <= 0;
    end

    // BCD conversion instances
    wire [3:0] bcd_s0, bcd_s1;
    wire [3:0] bcd_m0, bcd_m1;
    wire [3:0] bcd_h0, bcd_h1;
    wire [3:0] bcd_am0, bcd_am1;
    wire [3:0] bcd_ah0, bcd_ah1;

    bin2bcd conv_sec  (.bin(outs),  .bcd0(bcd_s0), .bcd1(bcd_s1));
    bin2bcd conv_min  (.bin(outm),  .bcd0(bcd_m0), .bcd1(bcd_m1));
    bin2bcd conv_hour (.bin(outh),  .bcd0(bcd_h0), .bcd1(bcd_h1));
    bin2bcd conv_amin (.bin(alarmm), .bcd0(bcd_am0), .bcd1(bcd_am1));
    bin2bcd conv_ahour(.bin(alarmh), .bcd0(bcd_ah0), .bcd1(bcd_ah1));

    // 7-segment conversion instances
    bcd2seg conv_s1(.bcd(bcd_s0), .outseg(outsegs1));
    bcd2seg conv_s2(.bcd(bcd_s1), .outseg(outsegs2));
    bcd2seg conv_m1(.bcd(bcd_m0), .outseg(outsegm1));
    bcd2seg conv_m2(.bcd(bcd_m1), .outseg(outsegm2));
    bcd2seg conv_h1(.bcd(bcd_h0), .outseg(outsegh1));
    bcd2seg conv_h2(.bcd(bcd_h1), .outseg(outsegh2));
    
    bcd2seg conv_am1(.bcd(bcd_am0), .outseg(outsegm1_a));
    bcd2seg conv_am2(.bcd(bcd_am1), .outseg(outsegm2_a));
    bcd2seg conv_ah1(.bcd(bcd_ah0), .outseg(outsegh1_a));
    bcd2seg conv_ah2(.bcd(bcd_ah1), .outseg(outsegh2_a));

    // Display multiplexing
    
    always @(posedge Gclk or posedge rst) begin
        if(rst) begin
            Disp_Val <= 8'd0;
            Disp_Seg <= 8'd0;
        end else begin
            if(CntRec == 16'd10922) begin                    //A 16-bit counter can count from 0 to 2^16 - 1 = 65535
                if(!alarm_set) begin                         //This range needs to be divided into six equal parts (for six digits).
                    Disp_Val <= outsegs1;                    //Each 6 digit get 65535/6 = 10922 counts
                    Disp_Seg <= 8'b1111_1110;
                end else begin
                    Disp_Val <= outsegs1_a;
                    Disp_Seg <= 8'b1111_1110;
                end
            end else if(CntRec == 16'd21844) begin           //2nd digit: 10922 x 2 = 21844   and so on. 
                if(!alarm_set) begin
                    Disp_Val <= outsegs2;
                    Disp_Seg <= 8'b1111_1101;
                end else begin
                    Disp_Val <= outsegs2_a;
                    Disp_Seg <= 8'b1111_1101;
                end
            end else if(CntRec == 16'd32766) begin
                if(!alarm_set) begin
                    Disp_Val <= outsegm1;
                    Disp_Seg <= 8'b1111_1011;
                end else begin
                    Disp_Val <= outsegm1_a;
                    Disp_Seg <= 8'b1111_1011;
                end
            end else if(CntRec == 16'd43688) begin
                if(!alarm_set) begin
                    Disp_Val <= outsegm2;
                    Disp_Seg <= 8'b1111_0111;
                end else begin
                    Disp_Val <= outsegm2_a;
                    Disp_Seg <= 8'b1111_0111;
                end
            end else if(CntRec == 16'd54610) begin
                if(!alarm_set) begin
                    Disp_Val <= outsegh1;
                    Disp_Seg <= 8'b1110_1111;
                end else begin
                    Disp_Val <= outsegh1_a;
                    Disp_Seg <= 8'b1110_1111;
                end
            end else if(CntRec == 16'd65532) begin
                if(!alarm_set) begin
                    Disp_Val <= outsegh2;
                    Disp_Seg <= 8'b1101_1111;
                end else begin
                    Disp_Val <= outsegh2_a;
                    Disp_Seg <= 8'b1101_1111;
                end
            end
        end
    end

endmodule



module bcd2seg(
    input [3:0] bcd,
    output reg [6:0] outseg  );

    always @(*) begin
        case(bcd)
          4'd0: outseg=7'b0000001;
          4'd1: outseg=7'b1001111;
          4'd2: outseg=7'b0010010;
          4'd3: outseg=7'b0000110;  
          4'd4: outseg=7'b1001100;
          4'd5: outseg=7'b0100100;
          4'd6: outseg=7'b0100000;
          4'd7: outseg=7'b0001111;
          4'd8: outseg=7'b0000000;
          4'd9: outseg=7'b0000100;
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
