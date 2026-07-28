function idx = s2m_buses_from_name(nm, nBus)
    %S2M_BUSES_FROM_NAME  Extract bus indices encoded in a name.
    %   "TF 4-1" -> [4 1] ; "B4 to B5 50 km" -> [4 5] ; "Gen1@Bus1" -> 1

    tok = regexp(nm, '(\d+)\s*-\s*(\d+)', 'tokens', 'once');       % "4-1"

    if ~isempty(tok)
        idx = [str2double(tok{1}) str2double(tok{2})];
    else
        t = regexp(nm, '(\d+)', 'tokens');
        idx = cellfun(@(c) str2double(c{1}), t);
    end

    idx = idx(idx >= 1 & idx <= nBus);
    idx = unique(idx, 'stable');

end
