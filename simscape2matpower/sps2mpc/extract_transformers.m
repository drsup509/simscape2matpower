function T = extract_transformers(model, comp, busOfElem, buses, baseMVA) %#ok<INUSL>
    %EXTRACT_TRANSFORMERS  Params are per-unit on the transformer's own base;
    %   rescale to the system base by baseMVA/SRated.
    T = struct('fbus',{},'tbus',{},'r',{},'x',{},'ratio',{},'shift',{});

    for k = 1:numel(comp.trafo)
        blk = comp.trafo{k};
        ft = busOfElem(blk);
        if numel(ft) < 2, ft = s2m_buses_from_name(get_param(blk,'Name'), numel(buses)); end
        if numel(ft) < 2, continue; end
        fb = ft(1); tb = ft(2);
        Sr  = s2m_getparam(blk, {'SRated'}, NaN);                 % VA
        rpu = s2m_safe(s2m_getparam(blk,{'pu_Rw1'},0),0) + s2m_safe(s2m_getparam(blk,{'pu_Rw2'},0),0);
        xpu = s2m_safe(s2m_getparam(blk,{'pu_Xl1'},0),0) + s2m_safe(s2m_getparam(blk,{'pu_Xl2'},0),0);
        if ~isnan(Sr) && Sr > 0, scale = baseMVA/(Sr/1e6); else, scale = 1; end
        T(end+1) = struct('fbus',fb,'tbus',tb, ...
            'r',rpu*scale, 'x',xpu*scale, 'ratio',1, 'shift',0); %#ok<AGROW>
    end

end
