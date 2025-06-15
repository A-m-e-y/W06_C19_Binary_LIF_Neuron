// binary_lif_neuron.v
`timescale 1ns / 1ps

// Module: binary_lif_neuron
// Description: Implements a binary Leaky Integrate-and-Fire (LIF) neuron.
//              The neuron's potential (P) accumulates input (I) and leaks over time
//              based on a leak factor (lambda). If the potential exceeds a threshold (theta),
//              the neuron spikes (S=1) and its potential is reset.
//
// Parameters:
//   POTENTIAL_WIDTH: Width of the register for the potential variable P.
//                    This determines the maximum integer value P can hold.
//   FRACTION_BITS:   Number of bits representing the fractional part in fixed-point
//                    arithmetic. This allows for representing values like 0.5 or 0.9.
//                    The actual scale factor is 2^FRACTION_BITS.
//
// Inputs:
//   clk:               System clock. Operations occur on its positive edge.
//   reset:             Asynchronous reset signal. When high, clears P and S.
//   I:                 Binary input to the neuron (0 or 1).
//   lambda_val_scaled: Scaled leak factor (lambda * 2^FRACTION_BITS).
//                      Lambda is between 0 and 1.
//   theta_val_scaled:  Scaled threshold value (theta * 2^FRACTION_BITS).
//   reset_val_scaled:  Scaled potential value to reset P to after a spike
//                      (reset_val * 2^FRACTION_BITS).
//
// Outputs:
//   S:                 Spiking state of the neuron (0 for not spiking, 1 for spiking).

module binary_lif_neuron #(
    parameter POTENTIAL_WIDTH = 16, // Width for the potential variable P (e.g., 16 bits)
    parameter FRACTION_BITS = 8     // Number of bits for the fractional part (e.g., 8 bits for 256 scale)
) (
    input wire clk,
    input wire reset,
    input wire I,                   // Binary input (0 or 1)
    input wire [FRACTION_BITS-1:0] lambda_val_scaled, // Leak factor, scaled (e.g., 0.8 -> 204 if FRACTION_BITS=8)
    input wire [POTENTIAL_WIDTH-1:0] theta_val_scaled,  // Threshold, scaled (e.g., 1.5 -> 384 if FRACTION_BITS=8)
    input wire [POTENTIAL_WIDTH-1:0] reset_val_scaled,  // Reset potential, scaled (e.g., 0.1 -> 25 if FRACTION_BITS=8)
    output reg S                     // Spiking state (0 or 1)
);

    // Register to store the neuron's potential.
    // Its width includes both integer and fractional parts as defined by POTENTIAL_WIDTH.
    reg [POTENTIAL_WIDTH-1:0] P;

    // Initial block for simulation setup.
    // In a real hardware design (FPGA/ASIC), P and S would typically be initialized
    // by a power-on reset or through the 'reset' signal. This block ensures defined
    // states at time 0 for Verilog simulation environments.
    initial begin
        P = 0; // Initialize potential to zero
        S = 0; // Initialize spike state to zero
    end

    // Always block for sequential logic, triggered by clock positive edge or reset positive edge.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Asynchronous reset:
            // When 'reset' is high, immediately clear the potential and spike state.
            P <= 0;
            S <= 0;
        end else begin
            // Non-reset state (normal operation):
            // 1. Calculate the leaked potential: P(t-1) * lambda
            //    The multiplication result can be wider than POTENTIAL_WIDTH + FRACTION_BITS.
            //    It's temporarily stored in 'P_mul_result'.
            //    The right shift (>>>) by FRACTION_BITS effectively divides by 2^FRACTION_BITS,
            //    performing the fixed-point scaling operation for the leak.
            reg [POTENTIAL_WIDTH + FRACTION_BITS - 1:0] P_mul_result;
            reg [POTENTIAL_WIDTH-1:0] P_current_cycle_calc; // Potential value calculated for this cycle

            P_mul_result = P * lambda_val_scaled;
            P_current_cycle_calc = P_mul_result >>> FRACTION_BITS;

            // 2. Accumulate input: Add the scaled input I(t) to the leaked potential.
            //    If I is 1, we add 2^FRACTION_BITS, which represents 1.0 in our fixed-point format.
            //    If I is 0, nothing is added.
            P_current_cycle_calc = P_current_cycle_calc + (I ? (1 << FRACTION_BITS) : 0);

            // 3. Threshold function and Reset mechanism:
            //    Check if the newly calculated potential exceeds or meets the threshold.
            if (P_current_cycle_calc >= theta_val_scaled) begin
                // If potential crosses threshold:
                S <= 1;             // Neuron spikes (output S becomes 1)
                P <= reset_val_scaled; // Reset potential to the specified reset_val_scaled
            end else begin
                // If potential does not cross threshold:
                S <= 0;             // Neuron does not spike (output S remains 0)
                P <= P_current_cycle_calc; // Update potential with the calculated value
            end
        end
    end

endmodule
