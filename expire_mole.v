module expire_mole(
    output reg t1,          // True if less than 0.5 seconds have passed
    output reg t2,          // True if less than 1 second has passed
    output reg timeout,     // True when mole expires (after 1.5 seconds)
    input clk,
    input reset,
    input paused
);
    reg [25:0] counter; // Adjust the width based on your clock frequency
    parameter HALF_SEC = 25_000_000; // For a 50 MHz clock
    parameter ONE_SEC = 50_000_000;
    parameter ONE_HALF_SEC = 75_000_000;

    always @(posedge clk) begin
        if (reset || paused) begin
            counter <= 0;
            t1 <= 1;
            t2 <= 1;
            timeout <= 0;
        end else begin
            counter <= counter + 1;
            if (counter >= ONE_HALF_SEC) begin
                timeout <= 1;
                t1 <= 0;
                t2 <= 0;
            end else if (counter >= ONE_SEC) begin
                t1 <= 0;
                t2 <= 0;
                timeout <= 0;
            end else if (counter >= HALF_SEC) begin
                t1 <= 0;
                t2 <= 1;
                timeout <= 0;
            end else begin
                t1 <= 1;
                t2 <= 1;
                timeout <= 0;
            end
        end
    end
endmodule
