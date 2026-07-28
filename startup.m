% STARTUP  Initialize the Converter project.
%   Adds all project folders to the MATLAB path. Steady-state layer uses IEEE
%   MATPOWER test cases; dynamic layer uses Simscape Electrical. 

clc;
clear all;
close all;

fprintf('\n=============================================\n');
fprintf(' CONVERTER SPS TO MPC\n');
fprintf('=============================================\n\n');

projectRoot = fileparts(mfilename('fullpath'));
addpath(genpath(projectRoot));

rng('default');

fprintf('Project initialized successfully.\n');
fprintf('Root: %s\n', projectRoot);
fprintf('MATLAB version: %s\n', version);
fprintf('MATLAB executable: %s\n\n', fullfile(matlabroot, 'bin', computer('arch'), 'matlab.exe'));
