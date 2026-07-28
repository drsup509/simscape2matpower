function T = sps_extract_transformers(model, busOfElem, buses, baseMVA)
%SPS_EXTRACT_TRANSFORMERS  Three-Phase Transformer (Two Windings) -> r,x,ratio.
%   Winding R/X are per-unit on the transformer's NominalPower base; they are
%   summed and rescaled to the system base. The off-nominal tap ratio is
%   derived from the winding voltages relative to the connected bus base kV.
    kvOf = containers.Map('KeyType','double','ValueType','double');
    for i = 1:numel(buses), kvOf(buses(i).bus) = buses(i).baseKV; end

    T = struct('fbus',{},'tbus',{},'r',{},'x',{},'ratio',{},'shift',{});
    tr = find_system(model,'SearchDepth',1,'MaskType','Three-Phase Transformer (Two Windings)');
    for k = 1:numel(tr)
        blk = tr{k};
        ft = busOfElem(blk);
        if numel(ft) < 2, continue; end
        fb = ft(1); tb = ft(2);

        NP = sps_slresolve(blk,'NominalPower',NaN);
        Sr = i_first(NP, NaN);                       % VA
        W1 = sps_slresolve(blk,'Winding1',[NaN 0 0]);
        W2 = sps_slresolve(blk,'Winding2',[NaN 0 0]);
        rpu = i_at(W1,2,0) + i_at(W2,2,0);           % pu on Sr base
        xpu = i_at(W1,3,0) + i_at(W2,3,0);
        if ~isnan(Sr) && Sr > 0, scale = baseMVA/(Sr/1e6); else, scale = 1; end

        % tap ratio from winding voltages vs bus base kV
        Vw1 = i_at(W1,1,NaN); Vw2 = i_at(W2,1,NaN);
        ratio = i_tap_ratio(Vw1, Vw2, kvOf, fb, tb);

        T(end+1) = struct('fbus',fb,'tbus',tb, ...
            'r',rpu*scale, 'x',xpu*scale, 'ratio',ratio, 'shift',0); %#ok<AGROW>
    end
end

function ratio = i_tap_ratio(Vw1, Vw2, kvOf, fb, tb)
    ratio = 1;
    if any(isnan([Vw1 Vw2])) || ~isKey(kvOf,fb) || ~isKey(kvOf,tb), return; end
    kvf = kvOf(fb)*1000; kvt = kvOf(tb)*1000;         % V
    % assign windings to buses by voltage proximity
    if abs(Vw1-kvf)+abs(Vw2-kvt) <= abs(Vw1-kvt)+abs(Vw2-kvf)
        Vf = Vw1; Vt = Vw2;
    else
        Vf = Vw2; Vt = Vw1;
    end
    if kvf > 0 && kvt > 0 && Vt > 0
        ratio = (Vf/kvf) / (Vt/kvt);
    end
    if ~isfinite(ratio) || ratio <= 0, ratio = 1; end
end

function v = i_first(x, d)
    if isempty(x) || all(isnan(x(:))), v = d; else, v = x(1); end
end

function v = i_at(x, idx, d)
    if numel(x) >= idx && ~isnan(x(idx)), v = x(idx); else, v = d; end
end
