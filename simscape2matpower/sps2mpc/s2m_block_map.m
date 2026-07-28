function map = s2m_block_map()
%S2M_BLOCK_MAP  Keywords matched against (ReferenceBlock/MaskType + Name),
%   whitespace-normalized, case-insensitive. Includes NAME-based patterns so
%   classification works even when Simscape Electrical is unlicensed (blocks
%   then report empty MaskType/ReferenceBlock and only the Name is available).
map.gen   = {'@bus','swing','synchronous machine round','synchronous machine salient','three-phase source'};
map.load  = {'wye-connected load','delta-connected load','load '};
map.line  = {'transmission line','pi section','distributed parameter',' to '};
map.trafo = {'two-winding transformer','winding transformer','tf '};
map.shunt = {'shunt reactor','shunt capacitor'};
map.bus   = {'busbar','bus'};
end
