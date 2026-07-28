function T = sps_extract_lines(model, busOfElem, buses, baseMVA, freq)
%SPS_EXTRACT_LINES  Three-Phase PI Section Line -> per-unit r,x,b.
%   Positive-sequence values (first element of the R/L/C vectors) are read in
%   SI units (Ohm, H, F) and converted to system p.u. via Zbase = kV^2/baseMVA.
    if nargin < 5 || isempty(freq), freq = 60; end
    w = 2*pi*freq;

    kvOf = containers.Map('KeyType','double','ValueType','double');
    for i = 1:numel(buses), kvOf(buses(i).bus) = buses(i).baseKV; end

    T = struct('fbus',{},'tbus',{},'r',{},'x',{},'b',{});
    pl = find_system(model,'SearchDepth',1,'MaskType','Three-Phase PI Section Line');
    for k = 1:numel(pl)
        blk = pl{k};
        ft = busOfElem(blk);
        if numel(ft) < 2, continue; end
        fb = ft(1); tb = ft(2);
        if ~isKey(kvOf, fb), continue; end
        len = i_first(sps_slresolve(blk,'Length',1), 1); if len == 0, len = 1; end
        R = i_first(sps_slresolve(blk,'Resistances',0), 0);   % Ohm (pos-seq)
        L = i_first(sps_slresolve(blk,'Inductances',0), 0);   % H
        C = i_first(sps_slresolve(blk,'Capacitances',0), 0);  % F
        Zb = (kvOf(fb)^2)/baseMVA;
        T(end+1) = struct('fbus',fb,'tbus',tb, ...
            'r', (R*len)/Zb, 'x', (w*L*len)/Zb, 'b', (w*C*len)*Zb); %#ok<AGROW>
    end
end

function v = i_first(x, d)
    if isempty(x) || all(isnan(x(:))), v = d; else, v = x(1); end
end
