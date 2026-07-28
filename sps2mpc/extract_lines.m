function T = extract_lines(model, comp, busOfElem, buses, baseMVA, freq) %#ok<INUSL>
%EXTRACT_LINES  Transmission Line (Three-Phase) -> per-unit r,x,b.
if nargin < 6 || isempty(freq), freq = 60; end
w = 2*pi*freq;

% Build bus -> baseKV lookup defensively
kvOf = containers.Map('KeyType','double','ValueType','double');
for i = 1:numel(buses)
    kvOf(buses(i).bus) = buses(i).baseKV;
end

T = struct('fbus',{},'tbus',{},'r',{},'x',{},'b',{});
for k = 1:numel(comp.line)
    blk = comp.line{k};
    ft = busOfElem(blk);
    if numel(ft) < 2, ft = s2m_buses_from_name(get_param(blk,'Name'), numel(buses)); end
    if numel(ft) < 2, continue; end
    fb = ft(1); tb = ft(2);
    if ~kvOf.isKey(fb), continue; end

    % Read value + unit together, then convert to SI base units.
    [lenv, lenu] = i_valunit(blk, {'length','Length'}, 1);
    if isnan(lenv) || lenv == 0, lenv = 1; lenu = 'km'; end
    len_m = lenv * s2m_units(lenu);                 % metres

    [Rv, Ru] = i_valunit(blk, {'R'}, 0);            % e.g. Ohm/km
    [Lv, Lu] = i_valunit(blk, {'L'}, 0);            % e.g. mH/km
    [Cv, Cu] = i_valunit(blk, {'Cl','C'}, 0);       % e.g. uF/km

    Rtot = s2m_safe(Rv,0) * s2m_units(Ru) * len_m;  % Ohm
    Ltot = s2m_safe(Lv,0) * s2m_units(Lu) * len_m;  % H
    Ctot = s2m_safe(Cv,0) * s2m_units(Cu) * len_m;  % F

    Zb = (kvOf(fb)^2)/baseMVA;                      % Ohm
    T(end+1) = struct('fbus',fb,'tbus',tb, ...
        'r', Rtot/Zb, 'x', (w*Ltot)/Zb, 'b', (w*Ctot)*Zb); %#ok<AGROW>
end
end

function [v, u] = i_valunit(blk, names, dflt)
%I_VALUNIT  First readable numeric param among "names", plus its "<name>_unit".
if nargin < 3, dflt = NaN; end
v = dflt; u = '';
for i = 1:numel(names)
    try
        raw = get_param(blk, names{i});
        num = str2double(raw);
        if isnan(num)
            vec = str2num(raw); %#ok<ST2NM>
            if ~isempty(vec), num = vec(1); end
        end
        if ~isnan(num)
            v = num;
            try, u = char(get_param(blk, [names{i} '_unit'])); catch, u = ''; end
            return;
        end
    catch
    end
end
end
