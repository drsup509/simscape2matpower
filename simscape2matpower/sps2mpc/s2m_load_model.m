function model = s2m_load_model(modelName)
%S2M_LOAD_MODEL  Load a Simulink/Simscape model and return its name handle.
[~, model] = fileparts(modelName);      % accept path or bare name
if isempty(find_system('SearchDepth',0,'Name',model))
    load_system(modelName);
end
end
