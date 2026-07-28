function cfg = config()
% CONFIG  Central configuration for the converter Simpower to Matpower

%% MODEL
% Default model name (bare, no extension) used by run_conversion when no
% explicit model path is passed. Resolved under test_system/sps/<name>.slx.
cfg.simulation.modelName = '';

%% MATLAB LICENSE
% Path to a licensed MATLAB executable that includes Simscape Electrical.
% Required to fully load Simscape/Specialized Power Systems models; an
% unlicensed MATLAB produces a degenerate/diverging network. Edit to match
% your install.
cfg.matlab.licensedExecutable = ''; %example: C:\Program Files\MATLAB\R2024a\bin\matlab.exe

%% MATPOWER
% Root folder of the MATPOWER install providing the steady-state functions
% (loadcase, runpf, ...). Added to the session path at pipeline start via
% install_matpower (session only, not saved). Edit to match your install.
cfg.matpower.path = ''; % example: C:\Program Files\MATPOWER\7.1

end
