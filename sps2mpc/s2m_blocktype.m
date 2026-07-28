function bt = s2m_blocktype(blk)
%S2M_BLOCKTYPE  Best available type identity for a block.
%   MaskType if set; else the linked-library ReferenceBlock path
%   (linked Three-Phase blocks report BlockType="Reference"); else BlockType.
bt = '';
try, bt = get_param(blk,'MaskType'); catch, end
if isempty(bt)
    try, rb = get_param(blk,'ReferenceBlock'); catch, rb = ''; end
    if ~isempty(rb), bt = rb; end          % e.g. ".../Busbar", ".../Wye-Connected Load"
end
if isempty(bt), try, bt = get_param(blk,'BlockType'); catch, end; end
end
