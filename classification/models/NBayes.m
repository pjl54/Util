function [methodstring,stats] = NBayes(training_set , testing_set, training_labels, testing_labels,varargin)

unq_tra_lab = unique(training_labels);
if numel(unq_tra_lab) ~= 2
    %     error('Only 2 labels allowed');
else
    idx1 = ismember(training_labels,unq_tra_lab(1));
    idx2 = ismember(training_labels,unq_tra_lab(2));
    training_labels(idx1) = 0;
    training_labels(idx2) = 1;
    idx1 = ismember(testing_labels,unq_tra_lab(1));
    idx2 = ismember(testing_labels,unq_tra_lab(2));
    testing_labels(idx1) = 0;
    testing_labels(idx2) = 1;
end

methodstring = 'NBayes';

% fit training data using specified distribution and prior info
% O1 = fitcnb(training_set,training_labels,'Distribution',distrib,'Prior',prior);
O1 = fitcnb(training_set,training_labels,'Prior','uniform');

% predict testing data using trained classifier
[decision,posterior] = O1.predict(testing_set);

stats.prediction = posterior(:,2);
stats.decision = decision;

unq_testing_labels = unique(testing_labels);
stats.prediction = posterior(:,2);

% method 1: accuracy with maximum likilihood as decision threshold
    stats.accMaxL = sum(decision == testing_labels')/numel(testing_labels);
    stats.decisionMaxL = logical(decision);    

% Patrick's new method (pick operating point based on training set)
if exist('testing_labels','var') && numel(unique(testing_labels)) > 1
        
    % Get AUC on testing set
    [~,~,~,stats.auc,~,~,~] = perfcurve(testing_labels,stats.prediction,1);
    
    % Get operating point on training set
    [~,tPosts] = O1.predict(training_set);
    [tFPR,tTPR,tT,tAUC,tOPTROCPT,~,~] = perfcurve(training_labels,tPosts(:,2),1);
    stats.trainingSetAUC = tAUC;

    optim_idx = find(tFPR == tOPTROCPT(1) & tTPR == tOPTROCPT(2));
    
    stats.optROCpoint = tT(optim_idx); % operating point
    stats.decisionOptROCpoint = stats.prediction > stats.optROCpoint;
        
    % method 2: accuracy using optimal ROC point as decision threshold
    stats.accOptROCpoint = sum(stats.decisionOptROCpoint == testing_labels')/numel(testing_labels);
    
%     stats.spec = 1-FPR;
%     stats.sens = TPR;
end