function busOfElem = s2m_build_topology(model, comp) %#ok<INUSL>

    %S2M_BUILD_TOPOLOGY  Map each element to the bus(es) it connects to.
    %   Buses ARE the Busbar blocks. An element's bus = the busbar(s) it is
    %   directly wired to (physical PortConnectivity); falls back to bus numbers
    %   parsed from the element name.

    isBus = containers.Map('KeyType','char','ValueType','logical');
    busName2idx = containers.Map('KeyType','char','ValueType','double');

    for i = 1:numel(comp.bus)
        id = s2m_busnum(get_param(comp.bus{i},'Name')); if isnan(id), id = i; end
        isBus(comp.bus{i}) = true; busName2idx(comp.bus{i}) = id;
    end

    nBus = numel(comp.bus);
    elems = [comp.gen; comp.load; comp.trafo; comp.line; comp.shunt];
    busOfElem = containers.Map('KeyType','char','ValueType','any');

    for k = 1:numel(elems)
        idx = i_direct_buses(elems{k}, isBus, busName2idx);
        if isempty(idx)
            idx = s2m_buses_from_name(get_param(elems{k},'Name'), nBus);
        end
        busOfElem(elems{k}) = unique(idx, 'stable');
    end

end

%%
function idx = i_direct_buses(blk, isBus, busName2idx)
    % Direct physical neighbours that are busbars (no multi-hop: avoids
    % collapsing the grid through shared grounds).

    idx = [];
    try, pc = get_param(blk,'PortConnectivity'); catch, return; end

    for p = 1:numel(pc)

        nbrs = double([pc(p).SrcBlock(:); pc(p).DstBlock(:)]);

        for h = nbrs(nbrs ~= -1)'
            nb = getfullname(h);
            if isBus.isKey(nb), idx(end+1) = busName2idx(nb); end %#ok<AGROW>
        end

    end

    idx = unique(idx, 'stable');

end
