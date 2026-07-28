function ok = s2m_validate_case(mpc, verbose)

%S2M_VALIDATE_CASE  Structural checks + optional power-flow smoke test.

if nargin < 2, verbose = true; end
ok = true; msgs = {};
nRef = sum(mpc.bus(:,2) == 3);
if nRef ~= 1, ok = false; msgs{end+1} = sprintf('Reference buses = %d (need 1).',nRef); end
if isempty(mpc.gen),    ok = false; msgs{end+1} = 'No generators found.'; end
if isempty(mpc.branch), ok = false; msgs{end+1} = 'No branches found.'; end
if ~isempty(mpc.branch)
    connected = unique([mpc.branch(:,1); mpc.branch(:,2)]);
    orphan = setdiff(mpc.bus(:,1), connected);
    if ~isempty(orphan), msgs{end+1} = sprintf('%d unconnected bus(es).',numel(orphan)); end
end
if verbose
    if ok, fprintf('Structural checks passed.\n'); end
    for i = 1:numel(msgs), fprintf('  [warn] %s\n', msgs{i}); end
end

if exist('runpf','file') == 2 && ok

    try
        r = runpf(mpc, mpoption('verbose',0,'out.all',0));
        if verbose
            if r.success, fprintf('Power flow converged.\n');
            else, fprintf('  [warn] Power flow did NOT converge.\n'); end
        end
        ok = ok && r.success;
    catch e
        if verbose, fprintf('  [warn] runpf error: %s\n', e.message); end
    end
end

end
