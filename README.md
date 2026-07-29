# Simscape2MATPOWER: Automated Conversion of Simscape Electrical Networks to MATPOWER Cases

Convert Simulink electrical models to [MATPOWER](https://matpower.org) steady-state
cases (".m" case files) and run a power flow to validate the result.

Two model families are supported through a single entry point, auto-detected:

- **Simscape Electrical Three-Phase** ("e_lib") — e.g. the IEEE 9-bus model.
- **Specialized Power Systems** ("powerlib" / SimPowerSystems) — e.g. the New
  England 39-bus model.

## Requirements

- **MATLAB with Simscape Electrical** (licensed). The converter must fully load
  the Simulink model to resolve block connectivity and parameters. An unlicensed
  MATLAB loads the model in restricted mode and produces a degenerate /
  diverging network; the converter detects this and fails with a clear message.
  - Verified with "C:\Program Files\MATLAB\R2024a-IREQ\bin\matlab.exe".
- **MATPOWER 8.0** (provides "loadcase", "runpf", "savecase", ...).
  - Verified with "\matpower8.1".

## Configuration

Edit ["config/config.m"](config/config.m) to match your install:

| Field | Purpose |
| --- | --- |
| "cfg.simulation.modelName" | Default model (bare name) used when "run_conversion" is called with no argument. Resolved under "test_system/sps/<name>.slx". |
| "cfg.matlab.licensedExecutable" | Path to the licensed MATLAB executable (Simscape Electrical). |
| "cfg.matpower.path" | Root folder of the MATPOWER install. Added to the session path (not saved). |

## Usage

Run from a licensed MATLAB, with the project root as the current folder.

Convert the default model ("cfg.simulation.modelName"):

### matlab
mpc = run_conversion;
###

Convert a specific model:

### matlab
mpc = run_conversion(fullfile('test_system','sps', ...
    'IEEE39Buses','NE39bus','NE39bus2_PQ.slx'));
###

From a shell:

### powershell
& 'C:\Program Files\MATLAB\R2024a-IREQ\bin\matlab.exe' -batch ^
  "cd('<projectRoot>'); run_conversion;"
###

"run_conversion" will:

1. add all project folders to the path;
2. load "config.m";
3. install MATPOWER for the session (skipped if already on the path);
4. convert the model via "simscape2matpower" (auto-dispatches to the SPS backend
   for Specialized Power Systems models);
5. save the case to "test_system/mpc/case_<ModelName>.m";
6. run a power flow as a sanity check.

## Project layout

###
run_conversion.m        End-to-end driver (entry point)
startup.m               Adds project folders to the path
config/
  config.m              Central configuration (paths + default model)
sps2mpc/                Conversion engine
  simscape2matpower.m   Main API; detects family, dispatches
  sps2matpower.m        Specialized Power Systems backend
  extract_*.m           ee_lib element extractors (bus/gen/load/line/trafo/...)
  sps_*.m               SPS element extractors + topology
  build_*_matrix.m      Assemble MATPOWER bus/gen/branch matrices
  s2m_*.m               Shared helpers (topology, units, per-unit, validation)
test_system/
  sps/                  Input Simulink models
  mpc/                  Generated MATPOWER cases (output)
###

## Test systems

| Model | Family | Output |
| --- | --- | --- |
| "test_system/sps/IEEE9BusSystem.slx" | Simscape Electrical (ee_lib) | "test_system/mpc/case_IEEE9BusSystem.m" |
| "test_system/sps/IEEE39Buses/NE39bus/NE39bus2_PQ.slx" | Specialized Power Systems | "test_system/mpc/case_NE39bus2_PQ.m" |

Both convert and pass a MATPOWER power flow (Newton, converged).

## Notes

- **Bus numbering** follows the model's own labels (Load Flow Bus IDs for SPS
  models), not necessarily canonical "1..N" numbering. For NE39 this means IDs
  run up to 41 with gaps — faithful to the Simulink model, not the textbook.
- Running two conversions in the same MATLAB session is supported: the MATPOWER
  install step is skipped on the second call.
