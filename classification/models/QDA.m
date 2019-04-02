function [methodstring,stats] = QDA( training_set , testing_set, training_labels, testing_labels )
unq_tra_lab = unique(training_labels);
if numel(unq_tra_lab) ~= 2
    error('Only 2 labels allowed');
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

methodstring = 'QDA';

% assignin('base','testing_set',testing_set);
% assignin('base','testing_labels',testing_labels);
% assignin('base','training_set',training_set);
% assignin('base','training_labels',training_labels);


try 
    [decision,~,probs,~,c] = classify(testing_set,training_set,training_labels,'quadratic'); 
catch err
%     [decision,~,probs,~,c] = classify(testing_set,training_set,training_labels,'diagquadratic');
    [decision,~,probs,~,c] = classify(testing_set,training_set,training_labels,'diagquadratic');     
end

% c(1,2) is the coefficient info for comparing class 1 to class 2
targetclass_name = c(1,2).name2;
if targetclass_name==1, targetclass=2; else targetclass=1; end;
stats.prediction = single(probs(:,targetclass));

    % method 1: accuracy with maximum likilihood as decision threshold
    stats.accMaxL = sum(decision == testing_labels')/numel(testing_labels);
    stats.decisionMaxL = decision;


% Patrick's new method (pick operating point based on training set)
if exist('testing_labels','var') && numel(unique(testing_labels)) > 1
    
    
    % Get AUC on testing set
    [~,~,~,stats.auc,~,~,~] = perfcurve(testing_labels,stats.prediction,targetclass_name);
    
    % Get operating point on training set
    try
        [~,~,tProbs,~,c] = classify(training_set,training_set,training_labels,'quadratic');
    catch
        [~,~,tProbs,~,c] = classify(training_set,training_set,training_labels,'diagquadratic');
    end
    
    [tFPR,tTPR,tT,tAUC,tOPTROCPT,~,~] = perfcurve(training_labels,single(tProbs(:,targetclass)),targetclass_name);
    stats.trainingSetAUC = tAUC;

    optim_idx = find(tFPR == tOPTROCPT(1) & tTPR == tOPTROCPT(2));
    
    stats.optROCpoint = tT(optim_idx); % operating point
    stats.decisionOptROCpoint = stats.prediction > stats.optROCpoint;
    
    % method 2: accuracy using optimal ROC point as decision threshold
    stats.accOptROCpoint = sum(stats.decisionOptROCpoint == testing_labels')/numel(testing_labels);
    
%     stats.spec = 1-FPR;
%     stats.sens = TPR;
end

