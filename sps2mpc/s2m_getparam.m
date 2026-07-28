function v = s2m_getparam(blk, candidates, default)

%S2M_GETPARAM  Return first existing numeric dialog param among candidates.
%   Tolerates unknown exact names by trying several; falls back to default.

if nargin < 3, default = NaN; end
if ischar(candidates), candidates = {candidates}; end
for i = 1:numel(candidates)
    try
        raw = get_param(blk, candidates{i});
        num = str2double(raw);
        if ~isnan(num), v = num; return; end
        vec = str2num(raw); %#ok<ST2NM>
        if ~isempty(vec), v = vec(1); return; end
    catch
    end
end
v = default;
end
