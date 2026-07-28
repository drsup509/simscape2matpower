function pu = s2m_to_perunit(val, kind, baseMVA, baseKV)

%S2M_TO_PERUNIT  Convert SI values to MATPOWER per-unit on (baseMVA,baseKV).

Zbase = (baseKV^2)/baseMVA;                 % ohms
switch lower(kind)
    case {'r','x'}, pu = val ./ Zbase;      % ohm     -> pu impedance
    case {'g','b'}, pu = val .* Zbase;      % siemens -> pu admittance
    otherwise, error('s2m_to_perunit:kind','Unknown kind ''%s''.',kind);
end
end
