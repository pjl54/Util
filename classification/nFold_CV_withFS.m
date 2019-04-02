function stats = nFold_CV_withFS(dataSet,dataLabels,nFeatures,n,nIter,cs,fs,Subsets)
% Using n-fold subset selection and C4.5 decision tree classifier
% Input:
%   dataSet: Feature matrix.  Rows are studies, columns are features
%   dataLabels: Data label vector with each study labelled as 1 or 0.
%       numel(dataLabels) must equal number of rows in dataSet
%   shuffle: 1 for random, 0 for non-random partition (Default: 1)
%   n: Number of folds to your cross-validation (Default: 3).  If n ==
%       number of studies, switches to leave-one-out cross validation
%   nIter: Number of cross-validation iterations (Default: 1)
%   cs (classifierString): Classifier to use, must be an element of set: {'LDA','QDA','SVM','NBayes','BaggedC45','KNN'}
%   fs (featureSelectionString): Feature selection method to use, must be
%      supported by Matlab's rankfeatures function
%   Subsets: pass your own training and testing subsets & labels (Default:
%       computer will generate using 'nFold')
%
% Output:
%   stats: struct containing TP, FP, TN, FN, etc.

% dataSet(dataSet<2*eps) = 0;;

% %% Pruning of features which have the same value for >80% of observations
% % NOTE: You may not want to do this
badFeats = [];
% for(k = 1:size(dataSet,2))
%     if(numel(unique(dataSet(:,k))) < size(dataSet,1)*.2)
%         badFeats(end+1) = k;
%     end
% end
% dataSet(:,badFeats) = [];
%
% % %% Replaces NaN and Inf with values
% % % You may not want to do this either
% dataSet = standardizeMissing(dataSet,Inf);
% dataSet = standardizeMissing(dataSet,-Inf);
% dataSet = fillmissing(dataSet,'movmedian',50);
% %
% % %% Remove duplicate columns
% %
% [~,iaFirst] = uniquetol(dataSet',1e-10,'ByRows',true);
% dataSet = dataSet(:,sort(iaFirst));
% %% Remove repeated columns
%
% % [~,idxs] = unique(dataSet','rows');
% % dataSet = dataSet(:,idxs);
%
% %%


if nargin < 8
    Subsets = [];
end
shuffle = 1; % randomized

parfor j=1:nIter
    try
        predictions = NaN(1,numel(dataLabels));
        if isempty(Subsets)
            if(n == numel(dataLabels))
                [tra, tes]=GenerateSubsets('LOO',dataSet,dataLabels);
            else
                [tra, tes]=GenerateSubsets('nFold',dataSet,dataLabels,shuffle,n);
            end
        else
            tra = Subsets{j}.training;
            tes = Subsets{j}.testing;
        end
        tempStats = struct;
        featStore = nan(sum(nFeatures(1,:)),n);
        
        for i=1:n
            
            trainingSet = dataSet(tra{i},:);
            testingSet = dataSet(tes{i},:);
            trainingLabels = dataLabels(tra{i});
            testingLabels = dataLabels(tes{i});
            
            sigFeats = getSigFeats(trainingSet,trainingLabels,fs,nFeatures);
            
            trainingSet = trainingSet(:,sigFeats);
            testingSet = testingSet(:,sigFeats);
            
            [temp_stats,~] = Classify(cs, trainingSet , testingSet, trainingLabels(:), testingLabels(:));
            [training_temp_stats,~] = Classify(cs, trainingSet , trainingSet, trainingLabels(:), trainingLabels(:));
            
            predictions(tes{i}) = [temp_stats.prediction];
            
            for(featToAdd = 1:length(sigFeats))
                sigFeats(featToAdd) = sigFeats(featToAdd) + sum(badFeats <= sigFeats(featToAdd));
            end
            featStore(:,i) = sigFeats;
            
            rs = getClassificationStats(trainingLabels, testingLabels, [training_temp_stats.prediction], [temp_stats.prediction]);
            for fn = fieldnames(rs)'
                tempStats(i).(fn{1}) = rs.(fn{1});
            end
            
            %             assignin('base','tempStats',tempStats)
        end
        
        fields = {'testAccuracyROCpt','testSensitivityROCpt','testSpecificityROCpt','testAccuracyMaxL','testSensitivityMaxL','testSpecificityMaxL','trainingSetAUC'};
        for(field = 1:length(fields))
            stats(j).(fields{field}) = mean([tempStats.(fields{field})]);
        end
        %         stats(j).testDecisionMaxL = [tempStats.testDecisionMaxL];
        %         stats(j).testDecisionROCpt = [tempStats.testDecisionROCpt];
        stats(j).predictions = predictions;
        [~,~,~,stats(j).testingSetAUC] = perfcurve(dataLabels,predictions,1);
        stats(j).features = featStore;
        
    catch e
        fprintf('%s \n',e.message)
        fprintf('Function: %s \n',e.stack(1).name)
        fprintf('Line: %d \n',e.stack(1).line)
    end
    
end

end

function sigFeats = getSigFeats(trainingSet,trainingLabels,fs,nFeatures)

if(length(nFeatures) == 1)
    sigFeats = runRankfeatures(trainingSet,trainingLabels,fs,nFeatures);
else
    nFeats = nFeatures(1,:);
    catEdges = [nFeatures(2,:),size(trainingSet,2)+1];
%     cats = {[1:51],[52:152],[153:190],[191:216],[217:242]};
    sigFeats = [];
    for(k = 1:length(nFeatures))
        if(nFeatures(k) ~= 0)            
            sigFeats = [sigFeats; (runRankfeatures(trainingSet(:,catEdges(k):(catEdges(k+1)-1)),trainingLabels,fs,nFeats(k)) + catEdges(k) - 1)];
        end
        
    end
end
end

function sigFeats = runRankfeatures(trainingSet,trainingLabels,fs,nFeatures)

if(nFeatures == size(trainingSet,2))
    sigFeats = 1:nFeatures;
elseif(ismember(lower(fs),{'ttest','entropy','roc','wilcoxon','bhattacharyya','brattacharyya'}))
    sigFeats = rankfeatures(trainingSet',trainingLabels,'Criterion',lower(fs),'NumberOfIndices',nFeatures);
    % sigFeats = getFFSfeatureSetNoStabil(trainingSet,trainingLabels,nFeatures);
elseif(strcmp(lower(fs),'mrmr'))
    sigFeats = getMRMRfeatureSet(trainingSet,trainingLabels,nFeatures)';
elseif(strcmp(lower(fs),'sfs'))
    sigFeats = getSFSfeatureSet(trainingSet,trainingLabels,nFeatures);
end
end