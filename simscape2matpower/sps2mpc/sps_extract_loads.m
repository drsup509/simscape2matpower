function T = sps_extract_loads(model, busOfElem)
%SPS_EXTRACT_LOADS  Three-Phase Parallel RLC Load -> Pd/Qd (MW/MVAr).
%   Qd = inductive - capacitive reactive power.
    T = struct('bus',{},'Pd',{},'Qd',{});
    ld = find_system(model,'SearchDepth',1,'MaskType','Three-Phase Parallel RLC Load');
    for k = 1:numel(ld)
        blk = ld{k};
        b = busOfElem(blk); if isempty(b), continue; end, b = b(1);
        P  = sps_slresolve(blk,'ActivePower',0);
        QL = sps_slresolve(blk,'InductivePower',0);
        QC = sps_slresolve(blk,'CapacitivePower',0);
        P = i_first(P,0); QL = i_first(QL,0); QC = i_first(QC,0);
        T(end+1) = struct('bus',b,'Pd',P/1e6,'Qd',(QL-QC)/1e6); %#ok<AGROW>
    end
end

function v = i_first(x, d)
    if isempty(x) || all(isnan(x(:))), v = d; else, v = x(1); end
end
