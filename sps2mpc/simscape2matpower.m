function mpc = simscape2matpower(modelName, opts)

    %SIMSCAPE2MATPOWER  Convert a Simscape Electrical (Three-Phase) model to MATPOWER.

    if nargin < 2, opts = struct(); end
    baseMVA = i_opt(opts,'baseMVA',100);
    freq    = i_opt(opts,'freq',60);
    verbose = i_opt(opts,'verbose',true);
    doSave  = i_opt(opts,'save',true);
    inclSw  = i_opt(opts,'includeSwitchedLoads',false);  % breaker-gated loads
    saveDir = i_opt(opts,'saveDir',pwd);                 % output folder for the .m case

    model = s2m_load_model(modelName);

    % Dispatch by Simscape family. Specialized Power Systems (powerlib) models
    % use their own backend; everything else is treated as Simscape Electrical
    % Three-Phase (ee_lib).
    if strcmp(i_detect_family(model), 'sps')
        if verbose, fprintf('Detected Specialized Power Systems model; using SPS backend.\n'); end
        mpc = sps2matpower(model, opts);
        return;
    end

    map   = s2m_block_map();
    comp  = s2m_classify_blocks(model, map, verbose);

    buses     = extract_buses(model, comp);
    busOfElem = s2m_build_topology(model, comp);

    gens   = extract_generators(model, comp, busOfElem);
    loads  = extract_loads(model, comp, busOfElem);
    lines  = extract_lines(model, comp, busOfElem, buses, baseMVA, freq);
    trafos = extract_transformers(model, comp, busOfElem, buses, baseMVA);
    shunts = extract_shunts(model, comp, busOfElem, freq);

    % Switchable disturbance loads sitting behind a Circuit Breaker. Kept OUT
    % of the base case by default (nominal snapshot); fold them in on request.
    swloads = extract_switched_loads(model, comp);
    if inclSw && ~isempty(swloads)
        loads = [loads, rmfield(swloads, {'status','name'})];
        if verbose, fprintf('Included %d switched load(s) in base case.\n', numel(swloads)); end
    end

    bus           = build_bus_matrix(buses, loads, shunts, gens);
    [gen,gencost] = build_gen_matrix(gens, baseMVA);
    branch        = build_branch_matrix(lines, trafos);

    mpc = s2m_assemble_case(baseMVA, bus, gen, branch, gencost);
    s2m_validate_case(mpc, verbose);
    i_check_sane(mpc, model);   % fail loudly on a degenerate/broken conversion

    % Record switchable loads as metadata for contingency dataset generation.
    % cols: [bus  Pd(MW)  Qd(MVAr)  status(1=in base case, 0=out)].
    if ~isempty(swloads)
        st = inclSw * ones(numel(swloads),1);
        mpc.switched_load = [ [swloads.bus].' [swloads.Pd].' [swloads.Qd].' st ];
        if verbose && ~inclSw
            fprintf(['Recorded %d switchable load(s) in mpc.switched_load ' ...
                     '(out of base case).\n'], numel(swloads));
        end
    end

    if doSave
        caseName = ['case_' i_clean_name(model)];
        if ~isempty(saveDir) && exist(saveDir,'dir') ~= 7, mkdir(saveDir); end
        outfile = fullfile(saveDir, [caseName '.m']);
        savecase(outfile, mpc);
        % savecase writes only standard fields; append switched_load so that
        % loadcase() reads it back.
        if isfield(mpc,'switched_load') && ~isempty(mpc.switched_load)
            i_append_switched(outfile, mpc.switched_load);
        end
        if verbose, fprintf('Saved MATPOWER case: %s\n', outfile); end
    end

end

%%

function v = i_opt(s, f, d)

    if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = d; end

end

%%

function n = i_clean_name(model)
%I_CLEAN_NAME  Make a valid MATLAB function name from a model name.
    n = char(model);
    n = regexprep(n, '\W', '_');          % non-word chars -> underscore
    if isempty(n) || ~isletter(n(1)), n = ['m_' n]; end
end

%%

function i_append_switched(outfile, M)
%I_APPEND_SWITCHED  Append the switched_load matrix to a savecase .m file so
%   that loadcase() restores it. Columns: [bus Pd(MW) Qd(MVAr) status].
    fid = fopen(outfile, 'a');
    if fid < 0, return; end
    fprintf(fid, '\n%%%% switchable disturbance loads (behind a breaker)\n');
    fprintf(fid, '%%\tbus\tPd\tQd\tstatus (1=in base case, 0=out)\n');
    fprintf(fid, 'mpc.switched_load = [\n');
    for r = 1:size(M,1)
        fprintf(fid, '\t%g\t%g\t%g\t%g;\n', M(r,1), M(r,2), M(r,3), M(r,4));
    end
    fprintf(fid, '];\n');
    fclose(fid);
end

%%

function fam = i_detect_family(model)
%I_DETECT_FAMILY  'sps' for Specialized Power Systems, else 'ee_lib'.
    masks = get_param(find_system(model,'LookUnderMasks','on', ...
        'FollowLinks','on','Type','Block'), 'MaskType');
    if ~iscell(masks), masks = {masks}; end
    masks = lower(masks(~cellfun('isempty',masks)));
    spsKeys = {'load flow bus','pi section line'};
    for i = 1:numel(masks)
        for j = 1:numel(spsKeys)
            if ~isempty(strfind(masks{i}, spsKeys{j})) %#ok<STREMP>
                fam = 'sps'; return;
            end
        end
    end
    fam = 'ee_lib';
end

%%

function i_check_sane(mpc, model)
%I_CHECK_SANE  Abort on a degenerate conversion (broken/restricted model load).
%   If the Simscape model does not load fully (e.g. this MATLAB lacks a
%   Simscape Electrical license), block connectivity is not resolved and the
%   topology collapses -- yielding a case with too few buses/branches whose
%   power flow silently diverges. Detect that and fail with a clear message.
    nb  = size(mpc.bus,1);
    ng  = size(mpc.gen,1);
    nbr = size(mpc.branch,1);
    if nb >= 2 && ng >= 1 && nbr >= 1
        % Branch reactances must not all be zero. In restricted-mode loads the
        % line/transformer R/L/C parameters resolve to 0, giving a
        % zero-impedance network whose power flow is singular.
        if any(mpc.branch(:,4) ~= 0), return; end
        error('simscape2matpower:zeroImpedance', ...
            ['Conversion of "%s" produced a network with all-zero branch ' ...
             'reactances.\nThe Simscape line/transformer parameters did not ' ...
             'resolve.\n%s'], char(model), i_license_hint());
    end
    error('simscape2matpower:degenerate', ...
        ['Conversion of "%s" produced a degenerate network ' ...
         '(%d bus, %d gen, %d branch).\nThe Simscape model did not load ' ...
         'fully, so block connectivity was not resolved.\n%s'], ...
        char(model), nb, ng, nbr, i_license_hint());
end

%%

function h = i_license_hint()
%I_LICENSE_HINT  Diagnostic string naming the Simscape Electrical license
%   status and the MATLAB currently in use, with the fix.
    feats = {'Simscape','Simscape_Electrical','Sim_Power_Systems'};
    have = false(1, numel(feats));
    for k = 1:numel(feats)
        try, have(k) = license('test', feats{k}) == 1; catch, have(k) = false; end
    end
    lic = sprintf('Simscape=%d, Simscape_Electrical=%d, Sim_Power_Systems=%d', ...
        have(1), have(2), have(3));
    h = sprintf(['CAUSE: missing Simscape Electrical license (license status: %s).\n' ...
        'Current MATLAB : %s (%s)\n' ...
        'This install cannot fully load Simscape/Specialized Power Systems ' ...
        'models, so their block parameters and connectivity are not resolved.\n' ...
        'FIX: run the conversion in a licensed MATLAB with Simscape Electrical ' ...
        'installed (see cfg.matlab.licensedExecutable in config.m).'], ...
        lic, matlabroot, version('-release'));
end
