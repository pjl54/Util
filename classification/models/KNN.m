function [methodstring,stats] = KNN(training_set , testing_set, training_labels, testing_labels,varargin)

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

methodstring = 'KNN';

% fit training data using specified distribution and prior info
% O1 = fitcnb(training_set,training_labels,'Distribution',distrib,'Prior',prior);
O1 = fitcknn(training_set,training_labels,'BreakTies','nearest','Prior','uniform','Distance','euclidean');

% predict testing data using trained classifier
[decision,posterior] = O1.predict(testing_set);

stats.prediction = posterior(:,2);
stats.decision = decision;

unq_testing_labels = unique(testing_labels);
if numel(unq_testing_labels) == 2 % things we will do only if there are 2 classes
    stats.prediction = posterior(:,2);
    
    
    % George's old method (pick operating point based on testing set)
    %     [FPR,TPR,T,AUC,OPTROCPT,~,~] = perfcurve(testing_labels,stats.prediction,targetclass_name);  % calculate AUC. 'perfcurve' can also calculate sens, spec etc. to plot the ROC curve.
    %     [TP FN] = perfcurve(testing_labels,stats.prediction,targetclass_name,'xCrit','TP','yCrit','FN');
    %     [FP TN] = perfcurve(testing_labels,stats.prediction,targetclass_name,'xCrit','FP','yCrit','TN');
    %     [~,ACC] = perfcurve(testing_labels,stats.prediction,targetclass_name,'xCrit','TP','yCrit','accu');
    %     [~,PPV] = perfcurve(testing_labels,stats.prediction,targetclass_name,'xCrit','TP','yCrit','PPV');
    %
    %     optim_idx = find(FPR == OPTROCPT(1) & TPR == OPTROCPT(2));
    %     stats.tp = TP(optim_idx);
    %     stats.fn = FN(optim_idx);
    %     stats.fp = FP(optim_idx);
    %     stats.tn = TN(optim_idx);
    %     stats.auc = AUC;
    %     stats.spec = 1-FPR(optim_idx);
    %     stats.sens = TPR(optim_idx);
    %     stats.acc = ACC(optim_idx);
    %     stats.ppv = PPV(optim_idx);
    %     stats.threshold = T(optim_idx);
    %     stats.decision = stats.prediction >= stats.threshold;
    % end
    
    % Patrick's new method (pick operating point based on training set)
    [~,~,~,stats.auc,~,~,~] = perfcurve(testing_labels,stats.prediction,1);
    stats.acc = sum(decision == testing_labels)/numel(testing_labels);
    TPR = numel(intersect(find(decision),find(testing_labels)))/numel(find(testing_labels));
    FPR = numel(intersect(find(~decision),find(~testing_labels)))/numel(find(~testing_labels));
    stats.decision = decision;
    stats.spec = 1-FPR;
    stats.sens = TPR;    
    
elseif numel(unq_testing_labels) > 2 % can't do ROC if there's more than 2 classes, so we'll do simple accuracy
    stats.decision = decision; % setting decision directly from bayesian classifier
    
    % calculating accuracy
    correctly_classified = 0;
    for i=1:length(unq_testing_labels)
        idx = testing_labels == unq_testing_labels(i);
        correctly_classified = correctly_classified + nnz(stats.decision(idx) == testing_labels(idx));
    end
    stats.acc = correctly_classified/length(testing_labels);
    
end