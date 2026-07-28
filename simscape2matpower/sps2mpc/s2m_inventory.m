function inv = s2m_inventory(model)

%S2M_INVENTORY  Report every unique block type in the model and its dialog
%   parameters. RUN THIS FIRST on your real model to see the exact names,
%   then (if needed) refine the keyword lists in S2M_BLOCK_MAP.

model = s2m_load_model(model);
blocks = find_system(model,'LookUnderMasks','all','FollowLinks','on','Type','block');
types = containers.Map('KeyType','char','ValueType','any');
for k = 1:numel(blocks)
    bt = s2m_blocktype(blocks{k});
    if isempty(bt) || types.isKey(bt), continue; end
    try, params = get_param(blocks{k},'DialogParameters');
    catch, params = struct(); end
    if isstruct(params), pnames = fieldnames(params); else, pnames = {}; end
    types(bt) = pnames;
end
inv = types;
fprintf('\n=== Simscape model inventory: %s ===\n', model);
keys = types.keys;
for i = 1:numel(keys)
    fprintf('\n[%s]\n', keys{i});
    p = types(keys{i});
    for j = 1:numel(p), fprintf('    %s\n', p{j}); end
end
end
