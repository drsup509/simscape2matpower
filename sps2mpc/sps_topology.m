function [busOfElem, buses, node] = sps_topology(model, comp) %#ok<INUSD>
%SPS_TOPOLOGY  Electrical node graph for a Specialized Power Systems model.
%
%   Buses are electrical nodes formed by the physical wiring. Connectivity is
%   taken from each block's PortConnectivity (which Simulink pre-resolves across
%   branch points), and union-find is run over (block, side) terminals:
%     * pass-through blocks (V-I Measurement, closed breakers) short L<->R,
%     * impedance elements (PI line, transformer) keep L and R separate.
%
%   A node containing a numbered "Three-Phase V-I Measurement" block (named
%   "1".."39") takes that number as its bus id; remaining nodes get fresh ids.
%
%   Returns:
%     busOfElem : containers.Map, block path -> [busA (busB)]
%     buses     : struct array with fields .bus, .baseKV
%     node      : diagnostics struct

    blks = find_system(model,'SearchDepth',1,'Type','block');
    n = numel(blks);

    % handle -> index
    h2idx = containers.Map('KeyType','double','ValueType','double');
    handles = zeros(1,n);
    for i = 1:n
        handles(i) = get_param(blks{i},'Handle');
        h2idx(handles(i)) = i;
    end

    % per-block neighbor sets by side (neighbor handles)
    nbrL = cell(1,n); nbrR = cell(1,n);
    hasL = false(1,n); hasR = false(1,n);
    for i = 1:n
        L = []; R = [];
        pc = get_param(blks{i},'PortConnectivity');
        for e = 1:numel(pc)
            t = pc(e).Type;
            if numel(t) >= 5 && strcmp(t(1:5),'LConn')
                side = 'L';
            elseif numel(t) >= 5 && strcmp(t(1:5),'RConn')
                side = 'R';
            else
                continue;
            end
            these = [pc(e).DstBlock(:)' pc(e).SrcBlock(:)'];
            if side == 'L'
                L = [L these]; hasL(i) = true; %#ok<AGROW>
            else
                R = [R these]; hasR(i) = true; %#ok<AGROW>
            end
        end
        nbrL{i} = unique(L); nbrR{i} = unique(R);
    end

    % union-find over (block,side): key = 2*i-1 (L), 2*i (R)
    parent = 1:(2*n);
    keyOf = @(i,s) (s=='L')*(2*i-1) + (s=='R')*(2*i);

    % 1) connect terminals across blocks
    for i = 1:n
        for s = 'LR'
            if s=='L', hs = nbrL{i}; else, hs = nbrR{i}; end
            for h = hs
                if ~isKey(h2idx, h), continue; end
                j = h2idx(h);
                if any(nbrL{j} == handles(i))
                    js = 'L';
                elseif any(nbrR{j} == handles(i))
                    js = 'R';
                else
                    continue;
                end
                parent = i_union(parent, keyOf(i,s), keyOf(j,js));
            end
        end
    end

    % 2) short pass-through blocks
    for i = 1:n
        if i_is_passthrough(blks{i}) && hasL(i) && hasR(i)
            parent = i_union(parent, keyOf(i,'L'), keyOf(i,'R'));
        end
    end

    % ---- assign bus ids ----
    % Load Flow Bus IDs are authoritative (the load-flow bus identity); anchor
    % them first. Numbered V-I Measurement names only fill remaining nodes.
    root2bus = containers.Map('KeyType','double','ValueType','double');
    root2kv  = containers.Map('KeyType','double','ValueType','double');

    % Load Flow Bus (ID + Vbase) -- authoritative
    lfb = find_system(model,'SearchDepth',1,'MaskType','Load Flow Bus');
    for i = 1:numel(lfb)
        id = i_num_from_name(get_param(lfb{i},'ID'));
        vb = str2double(get_param(lfb{i},'Vbase'));
        if isnan(id), continue; end
        j = h2idx(get_param(lfb{i},'Handle'));
        if hasL(j)
            r = i_find(parent, keyOf(j,'L'));
        elseif hasR(j)
            r = i_find(parent, keyOf(j,'R'));
        else
            continue;
        end
        root2bus(r) = id;                       % overrides any measurement guess
        if ~isnan(vb), root2kv(r) = vb/1000; end
    end

    % numbered measurement names -- only for nodes not already anchored
    for i = 1:n
        num = i_bus_number(blks{i});
        if isnan(num), continue; end
        if hasL(i)
            r = i_find(parent, keyOf(i,'L'));
        elseif hasR(i)
            r = i_find(parent, keyOf(i,'R'));
        else
            continue;
        end
        if ~isKey(root2bus, r) && ~any(cell2mat(root2bus.values) == num)
            root2bus(r) = num;
        end
    end

    % fresh ids for unanchored nodes
    used = cell2mat(root2bus.values); if isempty(used), used = 0; end
    nextId = max(used) + 1;
    allRoots = zeros(1,0);
    for i = 1:n
        if hasL(i), allRoots(end+1) = i_find(parent, keyOf(i,'L')); end %#ok<AGROW>
        if hasR(i), allRoots(end+1) = i_find(parent, keyOf(i,'R')); end %#ok<AGROW>
    end
    roots = unique(allRoots);
    for r = roots
        if ~isKey(root2bus, r), root2bus(r) = nextId; nextId = nextId + 1; end
    end

    % ---- outputs ----
    busIds = unique(cell2mat(root2bus.values));
    buses = struct('bus',{},'baseKV',{});
    for bId = busIds
        kv = 345;
        for r = roots
            if root2bus(r) == bId && isKey(root2kv, r), kv = root2kv(r); break; end
        end
        buses(end+1) = struct('bus',bId,'baseKV',kv); %#ok<AGROW>
    end

    busOfElem = containers.Map('KeyType','char','ValueType','any');
    for i = 1:n
        b = [];
        imp = i_is_impedance(blks{i});
        if hasL(i), b(end+1) = root2bus(i_find(parent, keyOf(i,'L'))); end %#ok<AGROW>
        if hasR(i) && imp, b(end+1) = root2bus(i_find(parent, keyOf(i,'R'))); end %#ok<AGROW>
        busOfElem(blks{i}) = b;
    end

    node = struct('root2bus',root2bus,'blks',{blks});
end

% ================= helpers =================
function r = i_find(parent, x)
    r = x;
    while parent(r) ~= r, r = parent(r); end
end

function parent = i_union(parent, a, b)
    ra = a; while parent(ra) ~= ra, ra = parent(ra); end
    rb = b; while parent(rb) ~= rb, rb = parent(rb); end
    if ra ~= rb, parent(ra) = rb; end
end

function tf = i_is_passthrough(blk)
    mt = lower(regexprep(get_param(blk,'MaskType'),'\s+',' '));
    tf = contains(mt,'measurement') || contains(mt,'breaker');
end

function tf = i_is_impedance(blk)
    mt = lower(regexprep(get_param(blk,'MaskType'),'\s+',' '));
    tf = contains(mt,'pi section line') || contains(mt,'transformer');
end

function num = i_bus_number(blk)
    mt = lower(regexprep(get_param(blk,'MaskType'),'\s+',' '));
    if ~contains(mt,'measurement'), num = NaN; return; end
    num = i_num_from_name(get_param(blk,'Name'));
end

function num = i_num_from_name(nm)
    t = regexp(char(nm), '(\d+)', 'match', 'once');
    if isempty(t), num = NaN; else, num = str2double(t); end
end
