function v = s2m_safe(x, d)

%S2M_SAFE  Return x, or default d when x is NaN/empty.

if isempty(x) || isnan(x), v = d; else, v = x; end

end
