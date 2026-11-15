module Final (
    input CLOCK_50,
    input wire [1:0] KEY,
    output reg [9:0] LEDR,
    input wire [9:0] SW,
    output reg [7:0] HEX0,
    output reg [7:0] HEX1,
    output reg [7:0] HEX2,
    output reg [7:0] HEX3,
    output reg [7:0] HEX4,
    output reg [7:0] HEX5,
    output reg [35:0] GPIO
);

    // State Variables
    reg [3:0] random_adjusted;
    reg [9:0] score;
    reg [3:0] score1, score2;
    reg [3:0] pos;
    reg wacked;
    reg enb;
    reg [9:0] SW_pre;
    reg [5:0] timer;
    reg [3:0] timer1, timer2;
    wire [3:0] random_number;
    wire slowclock;
    wire timeout, t1, t2;
    reg paused;
    reg key1_pre;

    // High Score Variables
    reg [9:0] high_score;
    reg [3:0] high_score1;
    reg [3:0] high_score2;

    // Startup Flag
    reg startup;

    // Wires for decoder outputs (7 bits)
    wire [6:0] hex0_segments;
    wire [6:0] hex1_segments;
    wire [6:0] hex2_segments;
    wire [6:0] hex3_segments;
    wire [6:0] hex4_segments;
    wire [6:0] hex5_segments;

    // Turn HEX, paused to off, and startup flag to on
    initial begin
        HEX0 = 8'b11111111;
        HEX1 = 8'b11111111;
        HEX2 = 8'b11111111;
        HEX3 = 8'b11111111;
        HEX4 = 8'b11111111;
        HEX5 = 8'b11111111;
        paused = 0;
        high_score = 0;
        startup = 1; // Set startup flag
    end
	 
	 localparam [3:0]
    LETTER_R = 4'd1,
    LETTER_E = 4'd2,
    LETTER_A = 4'd3,
    LETTER_D = 4'd4,
    LETTER_Y = 4'd5,
    LETTER_P = 4'ha,
    LETTER_L = 4'hb,
    LETTER_H = 4'he,
    LETTER_I = 4'hf;

    lfsr rn(.out(random_number), .clk(CLOCK_50), .paused(paused | startup));
    expire_mole ex(.t1(t1), .t2(t2), .timeout(timeout), .clk(CLOCK_50), .reset(enb), .paused(paused | startup));
    slow_clock sc(.clk(CLOCK_50), .slowclock(slowclock), .reset(~KEY[0]));

    seven_segment_decoder decoder0(.a(score2), .f(hex0_segments));
    seven_segment_decoder decoder1(.a(score1), .f(hex1_segments));
    seven_segment_decoder decoder2(.a(high_score2), .f(hex2_segments));
    seven_segment_decoder decoder3(.a(high_score1), .f(hex3_segments));
    seven_segment_decoder decoder4(.a(timer2), .f(hex4_segments));
    seven_segment_decoder decoder5(.a(timer1), .f(hex5_segments));

    // Game Logic
    always @(posedge CLOCK_50) begin
        SW_pre <= SW;
        key1_pre <= KEY[1];

        if (startup) begin
            // Display 'READY' on HEX displays
            HEX5[6:0] <= seg_decoder_HI(LETTER_R);	// 'R'
            HEX4[6:0] <= seg_decoder_HI(LETTER_E);	// 'E'
            HEX3[6:0] <= seg_decoder_HI(LETTER_A); // 'A'
            HEX2[6:0] <= seg_decoder_HI(LETTER_D); // 'D'
            HEX1[6:0] <= seg_decoder_HI(LETTER_Y); // 'Y'
            HEX0[6:0] <= 7'b1111111;	// Blank
            HEX5[7] <= 1'b1;
            HEX4[7] <= 1'b1;
            HEX3[7] <= 1'b1;
            HEX2[7] <= 1'b1;
            HEX1[7] <= 1'b1;
            HEX0[7] <= 1'b1;

            if (key1_pre == 1 && KEY[1] == 0) begin
                startup <= 0;
                paused <= 0;
					 
                score <= 0;
                timer <= 6'd30; // Set the timer to 30 seconds
                LEDR <= 10'b0;
                GPIO[0] <= 0;
            end
        end else begin
            if (key1_pre == 1 && KEY[1] == 0 && KEY[0] == 1) begin
                paused <= ~paused;
            end

            // Make sure random number is withi the 0-9 range
            if (random_number > 4'd9)
                random_adjusted <= random_number - 4'd6;
            else
                random_adjusted <= random_number;

            enb <= (~KEY[0]) | (wacked && !paused) | (timeout && !paused);

            if (enb && (timer > 0) && !paused) begin
                LEDR <= 10'b0; // Turn off all LEDs
                LEDR[random_adjusted] <= 1; // Light up one mole LED
                pos <= random_adjusted;     // Then update for the new mole position
            end

            if (!paused) begin
                wacked <= (~SW_pre[pos]) & SW[pos];

                // Scoring System, make sure maximum points doesn't exceed 99 points
                if (wacked && (timer > 0)) begin
                    if (t2) begin
                        if (t1)
                            score <= (score + 3 > 99) ? 99 : score + 3; // Less than 0.5 sec
                        else
                            score <= (score + 2 > 99) ? 99 : score + 2; // Less than 1 sec
                    end else
                        score <= (score + 1 > 99) ? 99 : score + 1;     // Less than 1.5 sec
                end

                // Deduct one point if mole expires
                if (timeout && (timer > 0)) begin
                    if (score > 0)
                        score <= score - 1;
                    else
                        score <= 0;
                end
            end else begin
                // Keep current values when paused
                wacked <= wacked;
                score <= score;
            end

            // Display currenbt game score on HEX0-1
            score1 <= (score / 10) % 10;
            score2 <= score % 10;
            HEX1[6:0] <= hex1_segments;
            HEX0[6:0] <= hex0_segments;
            HEX1[7] <= 1'b1;
            HEX0[7] <= 1'b1;

            // Timer
            if (slowclock && !paused) begin
                if (timer > 0)
                    timer <= timer - 1;
                else
                    timer <= 0;
            end

            // Display timer on HEX5 and HEX4 during game
            if (timer > 0) begin
                timer1 <= (timer / 10) % 10;
                timer2 <= timer % 10;
					 
                HEX5[6:0] <= hex5_segments;
                HEX4[6:0] <= hex4_segments;
                HEX5[7] <= 1'b1;
                HEX4[7] <= 1'b1;
                
                HEX3 <= 8'b11111111;
                HEX2 <= 8'b11111111;
            end

            // Game Over
            if (timer == 0) begin
                // Update high score
                if (score > high_score) begin
                    high_score <= score;
                end

                // Display high score on HEX2-3
                high_score1 <= (high_score / 10) % 10;
                high_score2 <= high_score % 10;
                HEX3[6:0] <= hex3_segments;
                HEX2[6:0] <= hex2_segments;
                HEX3[7] <= 1'b1;
                HEX2[7] <= 1'b1;

                // Display 'H' and 'I' on HEX5-4 to rtepresent 'High Score'
                HEX5[6:0] <= seg_decoder_HI(LETTER_H); // 'H'
                HEX4[6:0] <= seg_decoder_HI(LETTER_I); // 'I'
                HEX5[7] <= 1'b1;
                HEX4[7] <= 1'b1;

                LEDR <= 10'b0;
                GPIO[0] <= 1;
            end

            // Full Reset: both keys are pressed
            if (~KEY[0] && ~KEY[1]) begin
                // Full reset, including high score
                score <= 0;
                timer <= 6'd30; // Reset to 30 seconds
                high_score <= 0; // Reset high score
                LEDR <= 10'b0;
                GPIO[0] <= 0;
                paused <= 0;    // Reset paused state

                // Display 'PLAY' on HEX5, HEX4, HEX3, HEX2
                HEX5[6:0] <= seg_decoder_HI(LETTER_P); // 'P'
                HEX4[6:0] <= seg_decoder_HI(LETTER_L); // 'L'
                HEX3[6:0] <= seg_decoder_HI(LETTER_A); // 'A'
                HEX2[6:0] <= seg_decoder_HI(LETTER_Y); // 'Y'
                HEX5[7] <= 1'b1; // DP off
                HEX4[7] <= 1'b1; // DP off
                HEX3[7] <= 1'b1; // DP off
                HEX2[7] <= 1'b1; // DP off

                // Clear other displays
                HEX1 <= 8'b11111111;
                HEX0 <= 8'b11111111;

            end else if (~KEY[0]) begin
                // Normal reset, do not reset high score
                score <= 0;
                timer <= 6'd30; // Reset to 30 seconds
                LEDR <= 10'b0;
                GPIO[0] <= 0;
                paused <= 0;    // Reset paused state
                // Do not reset high_score
            end
        end
    end

    // Helper function to decode letters
    function [6:0] seg_decoder_HI;
        input [3:0] digit;
        begin
            case (digit)
                LETTER_R: seg_decoder_HI = 7'b1001110; // 'R'
                LETTER_E: seg_decoder_HI = 7'b0000110; // 'E'
                LETTER_A: seg_decoder_HI = 7'b0001000; // 'A'
                LETTER_D: seg_decoder_HI = 7'b0100001; // 'D'
                LETTER_Y: seg_decoder_HI = 7'b0010001; // 'Y'
                LETTER_P: seg_decoder_HI = 7'b0001100; // 'P'
                LETTER_L: seg_decoder_HI = 7'b1000111; // 'L'
                LETTER_H: seg_decoder_HI = 7'b0001001; // 'H'
                LETTER_I: seg_decoder_HI = 7'b1001111; // 'I'
                default: seg_decoder_HI = 7'b1111111;  // Blank
             endcase
        end
    endfunction

endmodule
