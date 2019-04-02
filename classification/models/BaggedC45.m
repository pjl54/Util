function [methodstring,stats] = BaggedC45(training_set , testing_set, training_labels, testing_labels)

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

methodstring = 'BaggedC45';
% Options for TreeBagger
% options = statset('UseParallel','always','UseSubstreams','never');
options = statset('UseParallel','never','UseSubstreams','never');

% B = TreeBagger(50,training_set,training_labels,'FBoot',0.667,'oobpred','on','Method','classification','NVarToSample','all','NPrint',25,'Options',options);    % create bagged d-tree classifiers from training
B = TreeBagger(50,training_set,training_labels,'FBoot',0.667,'oobpred','on','Method','classification','Prior',[.5 .5],'Options',options);    % create bagged d-tree classifiers from training

[Yfit,Scores] = predict(B,testing_set);   % use to classify testing

stats.prediction = Scores(:,2); % Select probabilities -- check manual entry for 'predict', look at 'B' to make sure your reqd class is the second column
decision = str2double(Yfit);
stats.trained_classifier = B;

% Patrick's new method (pick operating point based on training set)

% method 1: accuracy with maximum likilihood as decision threshold
stats.accMaxL = sum(decision == testing_labels')/numel(testing_labels);
stats.decisionMaxL = decision;

% Get AUC on testing set
if(numel(unique(testing_labels))>1)
    [~,~,~,stats.auc,~,~,~] = perfcurve(testing_labels,stats.prediction,1);
else
    stats.auc = [];
end
% Get operating point on training set
[~,tScores] = predict(B,training_set);   % use to classify testing

[tFPR,tTPR,tT,tAUC,tOPTROCPT,~,~] = perfcurve(training_labels,tScores(:,2),1);
stats.trainingSetAUC = tAUC;

optim_idx = find(tFPR == tOPTROCPT(1) & tTPR == tOPTROCPT(2));

stats.optROCpoint = tT(optim_idx); % operating point
stats.decisionOptROCpoint = stats.prediction > stats.optROCpoint;

% method 2: accuracy using optimal ROC point as decision threshold
stats.accOptROCpoint = sum(stats.decisionOptROCpoint == testing_labels')/numel(testing_labels);

%     stats.spec = 1-FPR;
%     stats.sens = TPR;
end
