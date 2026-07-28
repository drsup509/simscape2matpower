function T = extract_shunts(model, comp, busOfElem, freq) %#ok<INUSL,INUSD>

    %EXTRACT_SHUNTS  Shunt caps/reactors as Gs,Bs (MW/MVAr at 1 pu voltage).
    T = struct('bus',{},'Gs',{},'Bs',{});

    for k = 1:numel(comp.shunt)
        blk = comp.shunt{k};
        b = busOfElem(blk); if isempty(b), continue; end, b = b(1);
        Qc = s2m_getparam(blk,{'CapacitiveReactivePower','Qc','C'},0);
        Ql = s2m_getparam(blk,{'InductiveReactivePower','Ql','L'},0);
        T(end+1) = struct('bus',b,'Gs',0,'Bs',(s2m_safe(Qc,0)-s2m_safe(Ql,0))/1e6); %#ok<AGROW>
    end

end
