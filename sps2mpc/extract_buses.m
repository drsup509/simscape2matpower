function T = extract_buses(model, comp) %#ok<INUSL>

    %EXTRACT_BUSES  One bus per Busbar block; baseKV from VRated (volts).

    T = struct('bus',{},'baseKV',{});

    for i = 1:numel(comp.bus)
        blk = comp.bus{i};
        nm = get_param(blk,'Name');
        id = s2m_busnum(nm); if isnan(id), id = i; end
        v  = s2m_getparam(blk, {'VRated','BaseVoltage','Vnom','NominalVoltage'}, NaN);
        if ~isnan(v)
            vu = '';
            try, vu = char(get_param(blk,'VRated_unit')); catch, end
            kv = (v * s2m_units(vu)) / 1000;   % -> volts via unit, then kV
        else
            kv = i_kv_from_name(nm);           % parse "Bus4 230kV" -> 230
        end
        T(end+1) = struct('bus',id,'baseKV',kv); %#ok<AGROW>
    end

end

%%

function kv = i_kv_from_name(nm)

    % Parse a voltage like "230kV" or "16.5 kV" from a block name.
    t = regexpi(nm, '([\d.]+)\s*kV', 'tokens', 'once');
    if isempty(t), kv = 230; else, kv = str2double(t{1}); end

end
