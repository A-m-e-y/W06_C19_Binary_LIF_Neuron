// tb_binary_lif_neuron.v
`timescale 1ns / 1ps

// Module: tb_binary_lif_neuron
// Description: Testbench for the binary_lif_neuron module.
//              This testbench provides clock, reset, and various input scenarios
//              to verify the functionality of the LIF neuron.
//              It also dumps waveforms to a VCD file for visual inspection.
module tb_binary_lif_neuron;

    // Parameters for the LIF neuron under test.
    // These must match the parameters defined in the 'binary_lif_neuron' module.
    parameter POTENTIAL_WIDTH = 16;      // Width of the potential variable (P)
    parameter FRACTION_BITS = 8;         // Number of bits for the fractional part
    parameter SCALE_FACTOR = (1 << FRACTION_BITS); // Calculation of 2^FRACTION_BITS (e.g., 256)

    // Testbench signals (registers for inputs, wires for outputs)
    reg clk;
    reg reset;
    reg I; // Binary input to the neuron
    reg [FRACTION_BITS-1:0] lambda_val_scaled; // Scaled leak factor
    reg [POTENTIAL_WIDTH-1:0] theta_val_scaled;  // Scaled threshold
    reg [POTENTIAL_WIDTH-1:0] reset_val_scaled;  // Scaled reset potential
    wire S; // Spiking output from the neuron

    // Clock generation: Creates a periodic clock signal.
    // The clock period is defined by CLK_PERIOD.
    parameter CLK_PERIOD = 10; // 10 ns clock period (corresponds to 100 MHz clock frequency)
    always #((CLK_PERIOD / 2)) clk = ~clk; // Toggle clock every half period

    // Instantiate the Binary LIF Neuron module under test.
    // Parameters are passed to configure the neuron's width and fixed-point precision.
    binary_lif_neuron #(
        .POTENTIAL_WIDTH(POTENTIAL_WIDTH),
        .FRACTION_BITS(FRACTION_BITS)
    ) lif_neuron (
        .clk(clk),
        .reset(reset),
        .I(I),
        .lambda_val_scaled(lambda_val_scaled),
        .theta_val_scaled(theta_val_scaled),
        .reset_val_scaled(reset_val_scaled),
        .S(S)
    );

    // Initial block for defining test scenarios and simulation control.
    initial begin
        // Setup VCD (Value Change Dump) file for waveform visualization.
        // This allows you to view signal changes over time using tools like GTKWave.
        $dumpfile("lif_neuron.vcd");    // Specifies the output VCD file name
        $dumpvars(0, tb_binary_lif_neuron); // Dumps all signals in the current scope to the VCD file

        // 1. Initialize all testbench signals to a known state.
        clk = 0;
        reset = 1; // Assert reset initially to clear the neuron's state
        I = 0;
        lambda_val_scaled = 0;
        theta_val_scaled = 0;
        reset_val_scaled = 0;

        // Apply reset for one full clock cycle to ensure the neuron initializes correctly.
        #CLK_PERIOD; // Wait for one clock period while reset is active
        reset = 0;   // De-assert reset to begin normal operation

        $display("--- Starting Simulation ---");

        // --- Scenario 1: Constant input below threshold ---
        // Objective: Demonstrate that the neuron does not spike if the input is
        //            insufficient to raise the potential above the threshold,
        //            especially with significant leakage.
        $display("\nScenario 1: Constant input below threshold");
        // Parameters for this scenario:
        //   lambda = 0.5 (high leakage) -> 0.5 * 256 = 128
        //   theta  = 2.0 (high threshold) -> 2.0 * 256 = 512
        //   reset_val = 0.0 (reset to zero after spike, though not expected here)
        lambda_val_scaled = 0.5 * SCALE_FACTOR; // Leak factor (0.5)
        theta_val_scaled = 2.0 * SCALE_FACTOR;  // High threshold (2.0)
        reset_val_scaled = 0.0 * SCALE_FACTOR;  // Reset potential (0.0)
        I = 1; // Provide a constant input pulse

        repeat (20) @(posedge clk); // Run for 20 clock cycles to observe behavior
        $display("Expected S1: Potential should accumulate but not reach threshold. S should remain 0.");


        // --- Scenario 2: Input that accumulates until reaching threshold ---
        // Objective: Show that the neuron's potential can build up over time with
        //            repeated inputs, eventually crossing the threshold and spiking.
        $display("\nScenario 2: Input accumulates until reaching threshold");
        // Reset the neuron state before starting a new scenario.
        reset = 1; #CLK_PERIOD; reset = 0;
        // Parameters for this scenario:
        //   lambda = 0.9 (less leakage) -> 0.9 * 256 = 230 (approx)
        //   theta  = 1.5 (moderate threshold) -> 1.5 * 256 = 384
        //   reset_val = 0.1 (reset to a small positive value after spike)
        lambda_val_scaled = 0.9 * SCALE_FACTOR; // Leak factor (0.9)
        theta_val_scaled = 1.5 * SCALE_FACTOR;  // Moderate threshold (1.5)
        reset_val_scaled = 0.1 * SCALE_FACTOR;  // Reset potential (0.1)
        I = 1; // Provide a constant input pulse

        repeat (20) @(posedge clk); // Run for 20 clock cycles
        $display("Expected S2: Potential should accumulate and eventually reach threshold, causing spikes.");


        // --- Scenario 3: Leakage with no input ---
        // Objective: Demonstrate the leakage mechanism where the potential decays
        //            when no input is present.
        $display("\nScenario 3: Leakage with no input");
        // Reset the neuron state.
        reset = 1; #CLK_PERIOD; reset = 0;
        // Parameters for this scenario:
        //   lambda = 0.8 (moderate leakage) -> 0.8 * 256 = 204 (approx)
        //   theta  = 1.0 (threshold 1.0)
        //   reset_val = 0.0
        lambda_val_scaled = 0.8 * SCALE_FACTOR; // Leak factor (0.8)
        theta_val_scaled = 1.0 * SCALE_FACTOR;  // Threshold (1.0)
        reset_val_scaled = 0.0 * SCALE_FACTOR;  // Reset potential (0.0)

        // First, provide some input to build up the potential to a non-zero value.
        I = 1;
        repeat (5) @(posedge clk); // Apply input for 5 cycles
        I = 0; // Then, remove the input to observe pure leakage

        repeat (20) @(posedge clk); // Run for 20 clock cycles to observe leakage
        $display("Expected S3: Potential should decrease over time due to leakage.");


        // --- Scenario 4: Strong input causing immediate spiking ---
        // Objective: Show that a sufficiently strong input (or low threshold) can
        //            cause the neuron to spike quickly, potentially in a single cycle.
        $display("\nScenario 4: Strong input causing immediate spiking");
        // Reset the neuron state.
        reset = 1; #CLK_PERIOD; reset = 0;
        // Parameters for this scenario:
        //   lambda = 0.8 (moderate leakage)
        //   theta  = 0.5 (very low threshold) -> 0.5 * 256 = 128
        //   reset_val = 0.0
        lambda_val_scaled = 0.8 * SCALE_FACTOR; // Leak factor (0.8)
        theta_val_scaled = 0.5 * SCALE_FACTOR;  // Very low threshold (0.5)
        reset_val_scaled = 0.0 * SCALE_FACTOR;  // Reset potential (0.0)

        I = 1; // Provide a strong input, expected to cause immediate spiking

        repeat (10) @(posedge clk); // Run for 10 clock cycles
        $display("Expected S4: Neuron should spike almost immediately with strong input.");


        // Small delay before finishing simulation to ensure final state is captured.
        #CLK_PERIOD;
        $display("\n--- Simulation Finished ---");
        $finish; // End the simulation
    end

    // Monitor block: Displays the current state of important signals at each positive clock edge.
    // This helps in understanding the neuron's behavior during simulation.
    // The potential 'P' is also displayed in its scaled (integer) and unscaled (float) forms.
    always @(posedge clk) begin
        $display("Time: %0t ns, Reset: %b, Input I: %b, P: %0d (%.3f), S: %b",
                 $time, reset, I, lif_neuron.P, $itor(lif_neuron.P) / SCALE_FACTOR, S);
    end

endmodule
