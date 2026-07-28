function buses = sps_infer_basekv(model, busOfElem, buses)
%SPS_INFER_BASEKV  Fill base kV for buses lacking a Load Flow Bus, using the
%   nominal winding voltages of the transformers connected to them. Buses that
%   already carry an authoritative Load Flow Bus Vbase are left untouched.

    % authoritative bus ids (those with a Load Flow Bus Vbase)
    auth = false(1, max([buses.bus]));
    lfb = find_system(model,'SearchDepth',1,'MaskType','Load Flow Bus');
    for i = 1:numel(lfb)
        id = i_num(get_param(lfb{i},'ID'));
        vb = str2double(get_param(lfb{i},'Vbase'));
        if ~isnan(id) && ~isnan(vb) && id <= numel(auth), auth(id) = true; end
    end

    kvOf = containers.Map('KeyType','double','ValueType','double');
    for i = 1:numel(buses), kvOf(buses(i).bus) = buses(i).baseKV; end

    tr = find_system(model,'SearchDepth',1,'MaskType','Three-Phase Transformer (Two Windings)');
    for k = 1:numel(tr)
        blk = tr{k};
        ft = busOfElem(blk);
        if numel(ft) < 2, continue; end
        W1 = i_res(blk,'Winding1'); W2 = i_res(blk,'Winding2');
        i_set(ft(1), W1, auth, kvOf);
        i_set(ft(2), W2, auth, kvOf);
    end

    for i = 1:numel(buses)
        if isKey(kvOf, buses(i).bus), buses(i).baseKV = kvOf(buses(i).bus); end
    end
end

function i_set(busId, W, auth, kvOf)
    if isempty(W) || isnan(W(1)) || W(1) <= 0, return; end
    if busId <= numel(auth) && auth(busId), return; end   % keep authoritative
    kvOf(busId) = W(1)/1000;   %#ok<NASGU> kvOf is a handle Map, updated by ref
end

function v = i_res(blk, name)
    try, v = slResolve(get_param(blk,name), blk); catch, v = NaN; end
end

function n = i_num(s)
    t = regexp(s, '(\d+)', 'tokens', 'once');
    if isempty(t), n = NaN; else, n = str2double(t{1}); end
end
