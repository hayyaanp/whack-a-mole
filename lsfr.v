module lfsr(
    output reg [3:0] out,
    input clk,
    input paused
);
    reg [3:0] state;

    initial begin
        state = 4'b1111; // Initialize to a non-zero value
    end

    always @(posedge clk) begin
        if (!paused) begin
            state <= {state[2:0], state[3] ^ state[2]}; // Feedback taps at bits 3 and 2
            out <= state;
        end
    end
endmodule
