# W06_C19_Binary_LIF_Neuron

## Overview

This project implements a **Binary Leaky Integrate-and-Fire (LIF) Neuron** in Verilog, suitable for digital hardware (FPGA/ASIC) or simulation. The LIF neuron is a fundamental building block in neuromorphic and spiking neural network systems, modeling the behavior of biological neurons in a simplified, discrete-time, and fixed-point arithmetic form.

The project consists of two main Verilog files:

- [`binary_lif_neuron.v`](#binary_lif_neuronv): The core hardware module implementing the binary LIF neuron.
- [`tb_binary_lif_neuron.v`](#tb_binary_lif_neuronv): A comprehensive testbench that simulates and verifies the neuron under a variety of scenarios.

This documentation provides a detailed technical explanation of the neuron model, the implementation, the simulation methodology, and how all components interact.

---

## Table of Contents

- [Background: Leaky Integrate-and-Fire Neuron](#background-leaky-integrate-and-fire-neuron)
- [Project Structure](#project-structure)
- [File-by-File Technical Description](#file-by-file-technical-description)
  - [binary_lif_neuron.v](#binary_lif_neuronv)
  - [tb_binary_lif_neuron.v](#tb_binary_lif_neuronv)
- [Simulation Output](#simulation-output)
- [Simulation and Output Interpretation](#simulation-and-output-interpretation)
- [Parameterization and Fixed-Point Arithmetic](#parameterization-and-fixed-point-arithmetic)
- [How the Components Connect](#how-the-components-connect)
- [Extending and Customizing](#extending-and-customizing)
- [References](#references)

---

## Background: Leaky Integrate-and-Fire Neuron

The **Leaky Integrate-and-Fire (LIF) neuron** is a canonical model in computational neuroscience and neuromorphic engineering. Its behavior is governed by the following discrete-time update equation:

```
P(t) = lambda * P(t-1) + I(t)
if P(t) >= theta:
    S(t) = 1
    P(t) = reset_val
else:
    S(t) = 0
```

Where:
- `P(t)`: Membrane potential at time `t`
- `lambda`: Leak factor (0 < lambda < 1), controlling how quickly the potential decays
- `I(t)`: Input at time `t` (here, binary: 0 or 1)
- `theta`: Threshold for spiking
- `reset_val`: Value to which the potential is reset after a spike
- `S(t)`: Output spike (1 if neuron fires, 0 otherwise)

This project implements the above in **fixed-point arithmetic** for digital hardware.

---

## Project Structure

```
W06_C19_Binary_LIF_Neuron/
├── binary_lif_neuron.v      # Core LIF neuron module (parameterized, synthesizable)
├── tb_binary_lif_neuron.v   # Testbench for simulation and verification
└── README.md                # This documentation
```

---

## File-by-File Technical Description

### binary_lif_neuron.v

**Role:**  
Implements the parameterized, synthesizable binary LIF neuron module. This is the hardware description of a single neuron.

**Key Features:**
- **Parameterization:**  
  - `POTENTIAL_WIDTH`: Bit-width of the membrane potential register (e.g., 16 bits).
  - `FRACTION_BITS`: Number of bits for the fractional part (e.g., 8 bits for Q8 fixed-point).
- **Inputs:**
  - `clk`: System clock.
  - `reset`: Asynchronous reset.
  - `I`: Binary input (0 or 1).
  - `lambda_val_scaled`: Leak factor, scaled as an integer (e.g., 0.8 * 256 = 204).
  - `theta_val_scaled`: Threshold, scaled as an integer.
  - `reset_val_scaled`: Reset value, scaled as an integer.
- **Outputs:**
  - `S`: Spike output (1 if neuron fires, 0 otherwise).
- **Internal Logic:**
  - Maintains a register `P` for the membrane potential.
  - On each clock cycle:
    - Multiplies `P` by `lambda_val_scaled` (leakage), using fixed-point arithmetic.
    - Adds input `I` (scaled to fixed-point).
    - Compares to threshold; if exceeded, emits a spike and resets `P`.
    - Otherwise, updates `P` with the new value.
- **Fixed-Point Arithmetic:**
  - All real-valued parameters are represented as integers, scaled by `2^FRACTION_BITS`.
  - Multiplications and additions are performed in integer arithmetic, with appropriate bit-shifting to maintain scale.

**Typical Usage:**  
Instantiate this module in a larger digital system or simulate it using a testbench.

---

### tb_binary_lif_neuron.v

**Role:**  
A comprehensive testbench for simulating and verifying the behavior of the `binary_lif_neuron` module.

**Key Features:**
- **Parameter Matching:**  
  - Uses the same `POTENTIAL_WIDTH` and `FRACTION_BITS` as the neuron module.
  - Defines a `SCALE_FACTOR` for easy conversion between real values and fixed-point representation.
- **Clock Generation:**  
  - Generates a periodic clock (`clk`) with a defined period (e.g., 10 ns).
- **Test Scenarios:**  
  - **Scenario 1:** Constant input below threshold (tests sub-threshold accumulation and leakage).
  - **Scenario 2:** Input accumulates until reaching threshold (tests spiking and reset).
  - **Scenario 3:** Leakage with no input (tests decay of potential).
  - **Scenario 4:** Strong input causing immediate spiking (tests fast response).
- **Waveform Dumping:**  
  - Generates a VCD file (`lif_neuron.vcd`) for waveform analysis in tools like GTKWave.
- **Signal Monitoring:**  
  - At every clock edge, prints the current state: time, reset, input, potential (both integer and float), and spike output.
- **Reset Handling:**  
  - Applies resets between scenarios to ensure independent, repeatable tests.
- **Parameter Setting:**  
  - For each scenario, sets `lambda_val_scaled`, `theta_val_scaled`, and `reset_val_scaled` to demonstrate different neuron behaviors.

**Typical Usage:**  
Run in a Verilog simulator (e.g., Icarus Verilog, ModelSim) to observe and verify neuron behavior under various conditions.

```bash
> iverilog tb_binary_lif_neuron.v binary_lif_neuron.v -g2005-sv && vvp a.out
```

---

## Simulation Output
```bash
Time: 5000 ns, Reset: 1, Input I: 0, P: 0 (0.000), S: 0
--- Starting Simulation ---

Scenario 1: Constant input below threshold
Time: 15000 ns, Reset: 0, Input I: 1, P: 0 (0.000), S: 0
Time: 25000 ns, Reset: 0, Input I: 1, P: 256 (1.000), S: 0
Time: 35000 ns, Reset: 0, Input I: 1, P: 384 (1.500), S: 0
Time: 45000 ns, Reset: 0, Input I: 1, P: 448 (1.750), S: 0
Time: 55000 ns, Reset: 0, Input I: 1, P: 480 (1.875), S: 0
Time: 65000 ns, Reset: 0, Input I: 1, P: 496 (1.938), S: 0
Time: 75000 ns, Reset: 0, Input I: 1, P: 504 (1.969), S: 0
Time: 85000 ns, Reset: 0, Input I: 1, P: 508 (1.984), S: 0
Time: 95000 ns, Reset: 0, Input I: 1, P: 510 (1.992), S: 0
Time: 105000 ns, Reset: 0, Input I: 1, P: 511 (1.996), S: 0
Time: 115000 ns, Reset: 0, Input I: 1, P: 511 (1.996), S: 0
Time: 125000 ns, Reset: 0, Input I: 1, P: 511 (1.996), S: 0
Time: 135000 ns, Reset: 0, Input I: 1, P: 511 (1.996), S: 0
Time: 145000 ns, Reset: 0, Input I: 1, P: 511 (1.996), S: 0
Time: 155000 ns, Reset: 0, Input I: 1, P: 511 (1.996), S: 0
Time: 165000 ns, Reset: 0, Input I: 1, P: 511 (1.996), S: 0
Time: 175000 ns, Reset: 0, Input I: 1, P: 511 (1.996), S: 0
Time: 185000 ns, Reset: 0, Input I: 1, P: 511 (1.996), S: 0
Time: 195000 ns, Reset: 0, Input I: 1, P: 511 (1.996), S: 0
Time: 205000 ns, Reset: 0, Input I: 1, P: 511 (1.996), S: 0
Expected S1: Potential should accumulate but not reach threshold. S should remain 0.

Scenario 2: Input accumulates until reaching threshold
Time: 215000 ns, Reset: 0, Input I: 1, P: 0 (0.000), S: 0
Time: 225000 ns, Reset: 0, Input I: 1, P: 256 (1.000), S: 0
Time: 235000 ns, Reset: 0, Input I: 1, P: 26 (0.102), S: 1
Time: 245000 ns, Reset: 0, Input I: 1, P: 279 (1.090), S: 0
Time: 255000 ns, Reset: 0, Input I: 1, P: 26 (0.102), S: 1
Time: 265000 ns, Reset: 0, Input I: 1, P: 279 (1.090), S: 0
Time: 275000 ns, Reset: 0, Input I: 1, P: 26 (0.102), S: 1
Time: 285000 ns, Reset: 0, Input I: 1, P: 279 (1.090), S: 0
Time: 295000 ns, Reset: 0, Input I: 1, P: 26 (0.102), S: 1
Time: 305000 ns, Reset: 0, Input I: 1, P: 279 (1.090), S: 0
Time: 315000 ns, Reset: 0, Input I: 1, P: 26 (0.102), S: 1
Time: 325000 ns, Reset: 0, Input I: 1, P: 279 (1.090), S: 0
Time: 335000 ns, Reset: 0, Input I: 1, P: 26 (0.102), S: 1
Time: 345000 ns, Reset: 0, Input I: 1, P: 279 (1.090), S: 0
Time: 355000 ns, Reset: 0, Input I: 1, P: 26 (0.102), S: 1
Time: 365000 ns, Reset: 0, Input I: 1, P: 279 (1.090), S: 0
Time: 375000 ns, Reset: 0, Input I: 1, P: 26 (0.102), S: 1
Time: 385000 ns, Reset: 0, Input I: 1, P: 279 (1.090), S: 0
Time: 395000 ns, Reset: 0, Input I: 1, P: 26 (0.102), S: 1
Time: 405000 ns, Reset: 0, Input I: 1, P: 279 (1.090), S: 0
Expected S2: Potential should accumulate and eventually reach threshold, causing spikes.

Scenario 3: Leakage with no input
Time: 415000 ns, Reset: 0, Input I: 1, P: 0 (0.000), S: 0
Time: 425000 ns, Reset: 0, Input I: 1, P: 0 (0.000), S: 1
Time: 435000 ns, Reset: 0, Input I: 1, P: 0 (0.000), S: 1
Time: 445000 ns, Reset: 0, Input I: 1, P: 0 (0.000), S: 1
Time: 455000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 1
Time: 465000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 475000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 485000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 495000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 505000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 515000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 525000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 535000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 545000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 555000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 565000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 575000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 585000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 595000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 605000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 615000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 625000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 635000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Time: 645000 ns, Reset: 0, Input I: 0, P: 0 (0.000), S: 0
Expected S3: Potential should decrease over time due to leakage.

Scenario 4: Strong input causing immediate spiking
Time: 655000 ns, Reset: 1, Input I: 0, P: 0 (0.000), S: 0
Time: 665000 ns, Reset: 0, Input I: 1, P: 0 (0.000), S: 0
Time: 675000 ns, Reset: 0, Input I: 1, P: 0 (0.000), S: 1
Time: 685000 ns, Reset: 0, Input I: 1, P: 0 (0.000), S: 1
Time: 695000 ns, Reset: 0, Input I: 1, P: 0 (0.000), S: 1
Time: 705000 ns, Reset: 0, Input I: 1, P: 0 (0.000), S: 1
Time: 715000 ns, Reset: 0, Input I: 1, P: 0 (0.000), S: 1
Time: 725000 ns, Reset: 0, Input I: 1, P: 0 (0.000), S: 1
Time: 735000 ns, Reset: 0, Input I: 1, P: 0 (0.000), S: 1
Time: 745000 ns, Reset: 0, Input I: 1, P: 0 (0.000), S: 1
Time: 755000 ns, Reset: 0, Input I: 1, P: 0 (0.000), S: 1
Expected S4: Neuron should spike almost immediately with strong input.

--- Simulation Finished ---
tb_binary_lif_neuron.v:150: $finish called at 765000 (1ps)

```

## Simulation and Output Interpretation

When running the testbench, you will see detailed output for each scenario, including the time, input, potential, and spike output. For example:

```
Time: 25000 ns, Reset: 0, Input I: 1, P: 256 (1.000), S: 0
...
Expected S1: Potential should accumulate but not reach threshold. S should remain 0.
```

- **P (integer):** The fixed-point value of the membrane potential.
- **P (float):** The real-valued equivalent (`P / SCALE_FACTOR`).
- **S:** Spike output (1 = spike, 0 = no spike).

The VCD file can be loaded into a waveform viewer for graphical inspection.

---

## Parameterization and Fixed-Point Arithmetic

- **Fixed-Point Representation:**  
  All real-valued parameters (leak, threshold, reset value) are represented as integers scaled by `2^FRACTION_BITS`. For example, with `FRACTION_BITS = 8`, a value of 0.5 is represented as `0.5 * 256 = 128`.
- **Scaling Input:**  
  The binary input `I` is scaled to fixed-point by multiplying by `2^FRACTION_BITS` when added to the potential.
- **Multiplication and Shifting:**  
  The leak operation multiplies the potential by the leak factor, then right-shifts by `FRACTION_BITS` to maintain scale.

---

## How the Components Connect

1. **Instantiation:**  
   The testbench (`tb_binary_lif_neuron.v`) instantiates the neuron module (`binary_lif_neuron.v`) with matching parameters.

2. **Signal Flow:**  
   - The testbench drives the clock, reset, input, and parameter signals.
   - The neuron module receives these signals, updates its internal state, and outputs the spike signal.
   - The testbench monitors and displays the outputs, and controls the simulation flow.

3. **Simulation Loop:**  
   - For each scenario, the testbench sets the parameters and input, then advances the simulation for a number of clock cycles.
   - The neuron module processes the input and updates its state on each clock edge.
   - The testbench collects and displays results, and resets the neuron between scenarios.

4. **Waveform Generation:**  
   - All signals are dumped to a VCD file for post-simulation analysis.

---


## Summary Table

| File                     | Description                                                      |
|--------------------------|------------------------------------------------------------------|
| `binary_lif_neuron.v`    | Parameterized, synthesizable binary LIF neuron module            |
| `tb_binary_lif_neuron.v` | Testbench for simulation, verification, and waveform generation  |
| `README.md`              | Project documentation (this file)                                |

---
