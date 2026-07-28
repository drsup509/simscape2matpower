function T = extract_loads(model, comp, busOfElem) %#ok<INUSL>

    %EXTRACT_LOADS  Wye-Connected Load: P (W), Qpos (var). Name is fallback.

    T = struct('bus',{},'Pd',{},'Qd',{});

    for k = 1:numel(comp.load)
        blk = comp.load{k};
        b = busOfElem(blk); if isempty(b), continue; end, b = b(1);
        nm = get_param(blk,'Name');
        P = s2m_getparam(blk, {'P'}, NaN);
        Q = s2m_getparam(blk, {'Qpos','Q','InductiveReactivePower'}, NaN);
        if isnan(P), P = i_grab(nm,'([\d.]+)\s*MW',0)   * 1e6; end
        if isnan(Q), Q = i_grab(nm,'([\d.]+)\s*MVAr',0) * 1e6; end
        T(end+1) = struct('bus',b,'Pd',P/1e6,'Qd',Q/1e6); %#ok<AGROW>
    end

end

    %%

function v = i_grab(s, pat, d)

    t = regexpi(s, pat, 'tokens', 'once');
    if isempty(t), v = d; else, v = str2double(t{1}); end

end
