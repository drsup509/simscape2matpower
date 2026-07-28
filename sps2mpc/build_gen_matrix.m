function [gen, gencost] = build_gen_matrix(gens, baseMVA)

    %BUILD_GEN_MATRIX  21-column gen matrix + simple linear gencost.
    %   cols: bus Pg Qg Qmax Qmin Vg mBase status Pmax Pmin Pc1..apf

    m = numel(gens);
    gen = zeros(m,21);

    for i = 1:m
        gen(i,1)  = gens(i).bus;
        gen(i,2)  = gens(i).Pg;
        gen(i,3)  = gens(i).Qg;
        gen(i,4)  = gens(i).Qmax;
        gen(i,5)  = gens(i).Qmin;
        gen(i,6)  = gens(i).Vg;
        gen(i,7)  = baseMVA;
        gen(i,8)  = 1;                       % status
        gen(i,9)  = gens(i).Pmax;
        gen(i,10) = gens(i).Pmin;
    end

    gencost = zeros(m,7);

    for i = 1:m, gencost(i,:) = [2 0 0 3 0 1 0]; end   % model 2 poly, cost = 1*Pg

end
