function T = extract_generators(model, comp, busOfElem) %#ok<INUSL>

    %EXTRACT_GENERATORS  Pg/Vg parsed from the "... 1.025 pu 163 MW" name.

    T = struct('bus',{},'Pg',{},'Qg',{},'Vg',{},'Pmax',{},'Pmin',{}, ...
            'Qmax',{},'Qmin',{},'isSlack',{});
    for k = 1:numel(comp.gen)
        blk = comp.gen{k};
        b = busOfElem(blk); if isempty(b), continue; end, b = b(1);
        nm = get_param(blk,'Name');
        Vg = i_grab(nm, '([\d.]+)\s*pu', 1.0);
        Pg = i_grab(nm, '([\d.]+)\s*MW', 0);
        slack = ~isempty(regexpi(nm,'swing|slack','once'));
        T(end+1) = struct('bus',b,'Pg',Pg,'Qg',0,'Vg',Vg, ...
            'Pmax',Pg*2+300,'Pmin',0,'Qmax',300,'Qmin',-300,'isSlack',slack); %#ok<AGROW>
    end

    if ~isempty(T) && ~any([T.isSlack]), T(1).isSlack = true; end

end

    %%

function v = i_grab(s, pat, d)

    t = regexpi(s, pat, 'tokens', 'once');
    if isempty(t), v = d; else, v = str2double(t{1}); end

end
