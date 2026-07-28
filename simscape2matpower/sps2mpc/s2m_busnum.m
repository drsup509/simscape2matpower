function n = s2m_busnum(name)

    %S2M_BUSNUM  First integer in a block name ("Bus4\n230kV" -> 4).

    t = regexp(name, '(\d+)', 'tokens', 'once');
    if isempty(t), n = NaN; else, n = str2double(t{1}); end

end
