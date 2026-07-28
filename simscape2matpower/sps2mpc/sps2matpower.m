function mpc = sps2matpower(modelName, opts)

    %SPS2MATPOWER  Convert a Specialized Power Systems (powerlib) model to MATPOWER.
    %   Handles the SimPowerSystems family: Load Flow Bus, Three-Phase PI Section
    %   Line, Three-Phase Transformer (Two Windings), Three-Phase Parallel RLC
    %   Load and Synchronous Machine (inside G# subsystems). Reuses the shared
    %   build_*/assemble/validate helpers.

    if nargin < 2, opts = struct(); end
    baseMVA = i_opt(opts,'baseMVA',100);
    freq    = i_opt(opts,'freq',60);
    verbose = i_opt(opts,'verbose',true);
    doSave  = i_opt(opts,'save',true);
    saveDir = i_opt(opts, 'saveDir', pwd);   % output folder for the .m case

    model = s2m_load_model(modelName);

    [busOfElem, buses] = sps_topology(model, struct());
    buses = sps_infer_basekv(model, busOfElem, buses);

    loads  = sps_extract_loads(model, busOfElem);
    lines  = sps_extract_lines(model, busOfElem, buses, baseMVA, freq);
    trafos = sps_extract_transformers(model, busOfElem, buses, baseMVA);
    gens   = sps_extract_generators(model, busOfElem);
    shunts = struct('bus',{},'Gs',{},'Bs',{});

    bus           = build_bus_matrix(buses, loads, shunts, gens);
    [gen,gencost] = build_gen_matrix(gens, baseMVA);
    branch        = build_branch_matrix(lines, trafos);

    mpc = s2m_assemble_case(baseMVA, bus, gen, branch, gencost);
    s2m_validate_case(mpc, verbose);
    i_check_sane(mpc, model);   % fail loudly on a degenerate/broken conversion

    if doSave
        caseName = ['case_' i_clean_name(model)];
        if ~isempty(saveDir) && exist(saveDir,'dir') ~= 7, mkdir(saveDir); end
        outfile = fullfile(saveDir, [caseName '.m']);
        savecase(outfile, mpc);
        if verbose, fprintf('Saved MATPOWER case: %s\n', outfile); end
    end

end

%%

function v = i_opt(s, f, d)
    if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = d; end
end

%%

function n = i_clean_name(model)
    n = char(model);
    n = regexprep(n, '\W', '_');
    if isempty(n) || ~isletter(n(1)), n = ['m_' n]; end
end

%%

function i_check_sane(mpc, model)
%I_CHECK_SANE  Abort on a degenerate conversion (broken topology).
%   In an environment without a full Simscape Electrical license the model
%   loads in restricted mode: PortConnectivity does not populate, topology
%   collapses to a single node and the resulting case has no branches/gens.
%   Detect that and fail with a clear, actionable message rather than handing
%   back a network whose power flow silently diverges.
    nb  = size(mpc.bus,1);
    ng  = size(mpc.gen,1);
    nbr = size(mpc.branch,1);
    if nb >= 2 && ng >= 1 && nbr >= 1, return; end
    error('sps2matpower:degenerate', ...
        ['Conversion of "%s" produced a degenerate network ' ...
         '(%d bus, %d gen, %d branch).\nThe Simscape model did not load ' ...
         'fully -- this MATLAB likely lacks a Simscape Electrical license, ' ...
         'so block connectivity was not resolved.\nRun the conversion in the ' ...
         'licensed MATLAB, e.g.:\n' ...
         '  C:\\Program Files\\MATLAB\\R2024a-IREQ\\bin\\matlab.exe'], ...
        char(model), nb, ng, nbr);
end

