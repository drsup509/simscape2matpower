function S = extract_switched_loads(model, comp) %#ok<INUSL>
%EXTRACT_SWITCHED_LOADS  Loads gated by a Circuit Breaker (Three-Phase).
%   These are switchable disturbance loads used for fault/contingency studies.
%   Each is traced THROUGH its breaker to the busbar on the breaker's other
%   side (the plain topology tracer stops at the breaker, so these loads are
%   otherwise dropped from the base case). Returned OUT-of-service (status 0)
%   so the nominal base case is unchanged.
%
%   Output struct array fields: .bus .Pd .Qd .status .name

    S = struct('bus',{},'Pd',{},'Qd',{},'status',{},'name',{});

    brk = find_system(model,'SearchDepth',1,'Regexp','on', ...
                      'MaskType','[Cc]ircuit [Bb]reaker');
    if isempty(brk), return; end
    isBrk = containers.Map(brk, num2cell(true(1,numel(brk))));

    % bus block path -> bus id
    isBus       = containers.Map('KeyType','char','ValueType','logical');
    busName2idx = containers.Map('KeyType','char','ValueType','double');
    for i = 1:numel(comp.bus)
        p  = comp.bus{i};
        id = s2m_busnum(get_param(p,'Name')); if isnan(id), id = i; end
        isBus(p) = true; busName2idx(p) = id;
    end

    for k = 1:numel(comp.load)
        blk = comp.load{k};

        % a breaker directly wired to this load?
        brkBlk = '';
        for nm = i_neighbours(blk)
            if isBrk.isKey(nm{1}), brkBlk = nm{1}; break; end
        end
        if isempty(brkBlk), continue; end   % not a switched load

        % bus on the breaker's other side
        b = [];
        for nm = i_neighbours(brkBlk)
            if isBus.isKey(nm{1}), b(end+1) = busName2idx(nm{1}); end %#ok<AGROW>
        end
        if isempty(b), continue; end
        b = b(1);

        name = get_param(blk,'Name');
        P = i_power(blk, {'P'},                              name, '([\d.]+)\s*MW');
        Q = i_power(blk, {'Qpos','Q','InductiveReactivePower'}, name, '([\d.]+)\s*MVAr');

        S(end+1) = struct('bus',b,'Pd',P,'Qd',Q, ...
                          'status',0,'name',name); %#ok<AGROW>
    end
end

%%

function mw = i_power(blk, cand, name, namePat)
%I_POWER  Read a power dialog param (respecting its *_unit) and return MW/MVAr.
    for i = 1:numel(cand)
        try
            raw = get_param(blk, cand{i});
            val = str2double(raw); if isnan(val), v = str2num(raw); if ~isempty(v), val = v(1); end, end %#ok<ST2NM>
            if ~isnan(val)
                u = 'W';
                try, u = get_param(blk, [cand{i} '_unit']); catch, end
                mw = val * s2m_units(u) / 1e6;   % -> MW / MVAr
                return;
            end
        catch
        end
    end
    t = regexpi(name, namePat, 'tokens', 'once');
    if isempty(t), mw = 0; else, mw = str2double(t{1}); end   % name is already MW
end

%%

function names = i_neighbours(blk)
    names = {};
    try, pc = get_param(blk,'PortConnectivity'); catch, return; end
    for p = 1:numel(pc)
        h = double([pc(p).SrcBlock(:); pc(p).DstBlock(:)]);
        for hh = h(h ~= -1)'
            names{end+1} = getfullname(hh); %#ok<AGROW>
        end
    end
    names = unique(names, 'stable');
end
