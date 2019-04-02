function resultStats = getClassificationStats(trainingLabels, testingLabels, trainingPredictions, testingPredictions)

% Get AUC on testing set
if(numel(unique(testingLabels)) == 2)
    [~,~,~,resultStats.testingSetAUC,~,~,~] = perfcurve(testingLabels,testingPredictions,1);
else
    resultStats.testingSetAUC = NaN;
end

% Get operating point on training set
[tFPR,tTPR,tT,tAUC,tOPTROCPT,~,~] = perfcurve(trainingLabels,trainingPredictions,1);
resultStats.trainingSetAUC = tAUC;

% method 1: accuracy with maximum likilihood as decision threshold
testDecisionMaxL = round(testingPredictions);

% method 2: accuracy using optimal ROC point as decision threshold
optim_idx = find(tFPR == tOPTROCPT(1) & tTPR == tOPTROCPT(2));
resultStats.optROCpoint = tT(optim_idx); % operating point
testDecisionROC = testingPredictions > resultStats.optROCpoint;

decOpts = {testDecisionROC,testDecisionMaxL};

if(size(decOpts{1},1) ~= size(testingLabels,1))
    decOpts = {testDecisionROC',testDecisionMaxL'};
end

for(b = 1:2)    
    t = [];
    testDecision = logical(decOpts{b});
    t.testDecision = testDecision;
    t.testAccuracy = sum(testDecision == testingLabels)/numel(testingLabels);
    t.confusionMatrix = confusionmat(logical(testingLabels),testDecision);
    
    tp = length(intersect(find(testDecision == 1), find(testingLabels == 1)));
    tn = length(intersect(find(testDecision == 0), find(testingLabels == 0)));
    fp = length(intersect(find(testDecision == 1), find(testingLabels == 0)));
    fn = length(intersect(find(testDecision == 0), find(testingLabels == 1)));
    
    t.testSensitivity = tp / (tp + fn);
    t.testSpecificity = tn / (tn + fp);
    
    if(b == 1)
        for fn = fieldnames(t)'
            resultStats.([fn{1} 'MaxL']) = t.(fn{1});
        end
    else
        for fn = fieldnames(t)'
            resultStats.([fn{1} 'ROCpt']) = t.(fn{1});
        end
    end
    
end
