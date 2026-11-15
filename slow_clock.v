module slow_clock(
    input clk,
    output reg slowclock,
    input reset
);
    reg [25:0] counter; // Adjust the width based on your clock frequency
    parameter DIVISOR = 50_000_000; // For a 1 Hz clock from a 50 MHz input

    always @(posedge clk) begin
        if (reset) begin
            counter <= 0;
            slowclock <= 0;
        end else begin
            if (counter >= (DIVISOR - 1)) begin
                counter <= 0;
                slowclock <= ~slowclock;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule
