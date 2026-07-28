function bus = build_bus_matrix(buses, loads, shunts, gens)

    %BUILD_BUS_MATRIX  13-column MATPOWER bus matrix.
    %   cols: bus_i type Pd Qd Gs Bs area Vm Va baseKV zone Vmax Vmin

    n = numel(buses);
    bus = zeros(n,13);

    for i = 1:n
        bus(i,1)  = buses(i).bus;
        bus(i,2)  = 1;                      % PQ by default
        bus(i,7)  = 1;                      % area
        bus(i,8)  = 1.0;                    % Vm
        bus(i,9)  = 0;                      % Va
        bus(i,10) = buses(i).baseKV;
        bus(i,11) = 1;                      % zone
        bus(i,12) = 1.1; bus(i,13) = 0.9;   % Vmax/Vmin
    end

    if ~isempty(loads)
        bus = i_accumulate(bus, [loads.bus], [loads.Pd], 3);
        bus = i_accumulate(bus, [loads.bus], [loads.Qd], 4);
    end

    if ~isempty(shunts)
        bus = i_accumulate(bus, [shunts.bus], [shunts.Gs], 5);
        bus = i_accumulate(bus, [shunts.bus], [shunts.Bs], 6);
    end

    for g = 1:numel(gens)
        r = bus(:,1) == gens(g).bus;
        if gens(g).isSlack, bus(r,2) = 3; elseif bus(r,2) ~= 3, bus(r,2) = 2; end
    end

end

%%

function M = i_accumulate(M, busIds, vals, col)

    for i = 1:numel(busIds)
        r = M(:,1) == busIds(i);
        if any(r), M(r,col) = M(r,col) + vals(i); end
    end

end
