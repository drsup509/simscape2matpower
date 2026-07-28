function branch = build_branch_matrix(lines, trafos)

    %BUILD_BRANCH_MATRIX  13-col branch matrix. Inputs already in system p.u.
    %   cols: fbus tbus r x b rateA rateB rateC ratio angle status angmin angmax

    rows = {};
    for k = 1:numel(lines)
        L = lines(k);
        rows{end+1} = [L.fbus L.tbus L.r L.x L.b 0 0 0 0 0 1 -360 360]; %#ok<AGROW>
    end

    for k = 1:numel(trafos)
        T = trafos(k);
        rows{end+1} = [T.fbus T.tbus T.r T.x 0 0 0 0 T.ratio T.shift 1 -360 360]; %#ok<AGROW>
    end

    if isempty(rows), branch = zeros(0,13); else, branch = cell2mat(rows'); end

end
