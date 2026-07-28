function T = sps_extract_generators(model, busOfElem)
%SPS_EXTRACT_GENERATORS  Synchronous Machine load-flow data -> gen structs.
%   Each G# subsystem holds a Synchronous Machine whose load-flow mask carries
%   BusType ('swing'/'PV'/'PQ') and Pref (W). The scheduled voltage Vg is taken
%   from the matching Load Flow Bus Vref.
    T = struct('bus',{},'Pg',{},'Qg',{},'Vg',{}, ...
               'Pmax',{},'Pmin',{},'Qmax',{},'Qmin',{},'isSlack',{});

    % bus id -> Vref, from Load Flow Bus blocks
    vmap = containers.Map('KeyType','double','ValueType','double');
    lfb = find_system(model,'SearchDepth',1,'MaskType','Load Flow Bus');
    for i = 1:numel(lfb)
        id = i_bus_number(get_param(lfb{i},'ID'));
        if isnan(id), continue; end
        vr = str2double(get_param(lfb{i},'Vref'));
        if ~isnan(vr), vmap(id) = vr; end
    end

    gg = find_system(model,'SearchDepth',1,'Regexp','on', ...
                     'BlockType','SubSystem','Name','^G\d+$');
    for k = 1:numel(gg)
        gsys = gg{k};
        b = busOfElem(gsys); if isempty(b), continue; end, b = b(1);
        sm = find_system(gsys,'MaskType','Synchronous Machine');
        if isempty(sm), continue; end
        mac = sm{1};
        bt = lower(strtrim(i_str(get_param(mac,'BusType'))));
        slack = ~isempty(strfind(bt,'swing')) || ~isempty(strfind(bt,'slack')); %#ok<STREMP>
        Pref = sps_slresolve(mac,'Pref',0);
        Pg = i_first(Pref,0)/1e6;
        if isKey(vmap,b), Vg = vmap(b); else, Vg = 1.0; end
        T(end+1) = struct('bus',b,'Pg',Pg,'Qg',0,'Vg',Vg, ...
            'Pmax',Pg*2+500,'Pmin',0,'Qmax',9999,'Qmin',-9999, ...
            'isSlack',slack); %#ok<AGROW>
    end

    if ~isempty(T) && ~any([T.isSlack]), T(1).isSlack = true; end
end

function n = i_bus_number(s)
    t = regexp(s, '(\d+)', 'tokens', 'once');
    if isempty(t), n = NaN; else, n = str2double(t{1}); end
end

function v = i_first(x, d)
    if isempty(x) || all(isnan(x(:))), v = d; else, v = x(1); end
end

function s = i_str(x)
    if ischar(x) || isstring(x), s = char(x); else, s = ''; end
end
