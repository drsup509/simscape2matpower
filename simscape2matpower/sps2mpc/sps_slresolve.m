function v = sps_slresolve(blk, name, default)
%SPS_SLRESOLVE  Evaluate a (possibly symbolic) block parameter to numbers.
%   Specialized Power Systems blocks are parameterised with MATLAB expressions
%   that reference base-workspace variables (e.g. "line(30,3)", "p0(1,1)*1E9").
%   slResolve evaluates them in the block's variable context.
if nargin < 3, default = NaN; end
try
    raw = get_param(blk, name);
    v = slResolve(raw, blk);
    if isempty(v), v = default; end
catch
    v = default;
end
end
