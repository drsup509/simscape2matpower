function mpc = run_conversion(modelFile)
% RUN_CONVERSION  Convert the Simscape/SPS test system to a MATPOWER case.
%
%   mpc = RUN_CONVERSION()
%   mpc = RUN_CONVERSION(modelFile)
%
%   End-to-end driver for the project:
%     1. adds every project folder to the path;
%     2. loads the central configuration (config.m);
%     3. installs MATPOWER for this session (path only, not saved);
%     4. converts the model in test_system/sps via simscape2matpower;
%     5. saves the generated MATPOWER case into test_system/mpc;
%     6. runs a power flow as a sanity check.
%
%   modelFile (optional) : path to the .slx model to convert. When omitted,
%   uses test_system/sps/<cfg.simulation.modelName>.slx.
%
%   Requires a licensed MATLAB with Simscape Electrical (see
%   cfg.matlab.licensedExecutable in config.m). An unlicensed MATLAB cannot
%   fully load the Simscape model and produces a degenerate/diverging case.

%% --- Project paths -------------------------------------------------------
projectRoot = fileparts(mfilename('fullpath'));
addpath(genpath(projectRoot));

cfg = config();

%% --- MATPOWER (session path only, not saved) ----------------------------
% Skip the install if MATPOWER is already on the path: install_matpower errors
% when run a second time in the same session (e.g. two conversions back to back).
if exist('runpf', 'file') ~= 2
    if isempty(cfg.matpower.path) || exist(cfg.matpower.path, 'dir') ~= 7
        error('run_conversion:matpower', ...
            'MATPOWER path not found: "%s". Set cfg.matpower.path in config.m.', ...
            cfg.matpower.path);
    end
    addpath(cfg.matpower.path);   % expose install_matpower itself
    install_matpower(1, 0, 1);    % modify path, do not save, verbose
else
    fprintf('MATPOWER already on path; skipping install_matpower.\n');
end

%% --- Input model / output folder ----------------------------------------
if nargin < 1 || isempty(modelFile)
    modelFile = fullfile(projectRoot, 'test_system', 'sps', ...
        [cfg.simulation.modelName '.slx']);
end
if exist(modelFile, 'file') ~= 4 && exist(modelFile, 'file') ~= 2
    error('run_conversion:model', 'Model not found: "%s".', modelFile);
end

outDir = fullfile(projectRoot, 'test_system', 'mpc');
if exist(outDir, 'dir') ~= 7, mkdir(outDir); end

%% --- Convert Simscape -> MATPOWER ---------------------------------------
opts = struct( ...
    'baseMVA', 100, ...
    'freq',    60, ...
    'verbose', true, ...
    'save',    true, ...
    'saveDir', outDir);

fprintf('\nConverting "%s" -> MATPOWER case in %s\n', ...
    modelFile, outDir);
mpc = simscape2matpower(modelFile, opts);

%% --- Sanity power flow --------------------------------------------------
fprintf('\nRunning power flow on the converted case...\n');
runpf(mpc);

fprintf('\nDone. MATPOWER case written to: %s\n', outDir);

end
