function comp = s2m_classify_blocks(model, map, verbose)
%S2M_CLASSIFY_BLOCKS  Classify TOP-LEVEL blocks by type (or name).
if nargin < 3, verbose = true; end
blocks = find_system(model,'SearchDepth',1,'Type','block');
cats = {'gen','load','line','trafo','shunt','bus'};   % bus LAST (least specific)
for c = 1:numel(cats), comp.(cats{c}) = {}; end
for k = 1:numel(blocks)
    blk = blocks{k};
    hay = lower([s2m_blocktype(blk) ' ' get_param(blk,'Name')]);
    hay = regexprep(hay, '\s+', ' ');
    for c = 1:numel(cats)
        if any(cellfun(@(p) contains(hay, lower(p)), map.(cats{c})))
            comp.(cats{c}){end+1,1} = blk; break;
        end
    end
end
if verbose
    fprintf('Classified: %d bus, %d gen, %d load, %d trafo, %d line, %d shunt\n', ...
        numel(comp.bus),numel(comp.gen),numel(comp.load), ...
        numel(comp.trafo),numel(comp.line),numel(comp.shunt));
end
end
