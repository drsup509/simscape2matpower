function mpc = s2m_assemble_case(baseMVA, bus, gen, branch, gencost)

%S2M_ASSEMBLE_CASE  Pack a valid MATPOWER case struct.

mpc.version = '2';
mpc.baseMVA = baseMVA;
mpc.bus     = bus;
mpc.gen     = gen;
mpc.branch  = branch;

if nargin >= 5 && ~isempty(gencost), mpc.gencost = gencost; end

if ~isempty(bus) && ~any(bus(:,2) == 3), mpc.bus(1,2) = 3; end   % ensure one ref

end
