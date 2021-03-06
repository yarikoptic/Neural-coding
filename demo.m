%% DEMO

% This is a demo of the neural-coding toolbox
% Requires VIM-1 dataset CRCNS.org

%% Add neural-coding toolbox to search path, cleanup and seed random number generator

addpath(genpath(pwd));

close all; clear all; clc;

rng(1); 

%% Load data

Stimuli           = load('Stimuli.mat'); % from the vim-1 data set.
training_stimulus = double(Stimuli.stimTrn);
test_stimulus     = double(Stimuli.stimVal);
clear Stimuli

EstimatedResponses = load('EstimatedResponses.mat'); % from the vim-1 data set.
ROI                = 1;
training_response  = EstimatedResponses.dataTrnS1(ROI == EstimatedResponses.roiS1 & all(isfinite(EstimatedResponses.dataTrnS1), 2) & all(isfinite(EstimatedResponses.dataValS1), 2), :)';
test_response      = EstimatedResponses.dataValS1(ROI == EstimatedResponses.roiS1 & all(isfinite(EstimatedResponses.dataTrnS1), 2) & all(isfinite(EstimatedResponses.dataValS1), 2), :)';
clear EstimatedResponses

%% choose random subset of voxels for demonstration purposes

nvoxels = 20;
prm = randperm(size(training_response,2));
training_response = training_response(:,prm(1:nvoxels));
test_response = test_response(:,prm(1:nvoxels));

%% Define feature model

%fm = IdentityModel;
%fm = PCAModel;
%fm = ICAModel;
fm = TICAModel;

%% Train feature model

fm.fit(training_stimulus);

%% Simulate feature model

training_feature = fm.predict(training_stimulus);
test_feature     = fm.predict(test_stimulus);

%% Define response model

rm = KernelRidgeRegression;
    
%% Train response model

rm.fit(training_feature, training_response);

%% Simulate response model

training_response_hat = rm.predict(training_feature);
test_response_hat     = rm.predict(test_feature);

%% Analyze encoding performance

R = diag(corr(test_response, test_response_hat));

disp(['encoding performance: ' num2str(nanmean(R)) ' (mean R)'])

figure(2); semilogx(sort(R, 'descend')); xlabel('voxel'); ylabel('R'); title('encoding performance');

%% identify images

nanidx = any(isnan(test_response_hat));

[~, identification_index] = max(corr(test_response(:,~nanidx)', test_response_hat(:,~nanidx)'), [], 2);

test_stimulus_size = size(test_stimulus);

recon = zeros(test_stimulus_size);
for index = 1 : test_stimulus_size(1)
    recon(index,:,:) = test_stimulus(identification_index(index),:,:);
end

disp(['identification performance: ' num2str(100 * mean(identification_index' == 1 : test_stimulus_size(1))) '% (accuracy)']);



