function [thresh, pAll, threshAll, hrAll, statsAll] = findBestThresh(scores,labels,timeToEvent,nThresh)

if(~exist('nThresh','var'))
    nThresh = 1;
end

threshs = (sort(scores(2:end)) + sort(scores(1:end-1)))/2;    
    
labelers = unique(labels);
if(length(labelers) > 1)
    smallerCount = min(sum(labels==labelers(1)),sum(labels==labelers(2)));
else
    smallerCount = length(labels)/2;
end

smallerCount = max(smallerCount,length(labels)/3);

threshs = threshs(round(smallerCount/2):round(length(threshs)-smallerCount/2));

% if(exist('setThreshs','var') && ~isempty(setThreshs))
%     threshs = threshs(threshs>setThreshs(end));
% end

maxNthreshs = 100;
if(length(threshs) > maxNthreshs)
    threshs = linspace(threshs(1),threshs(end),maxNthreshs);
end
    

if(nThresh == 1)
    
    for(k = 1:length(threshs))
        [pval(k),hr(k),stats(k)] = KMcurveFromThreshold(scores,labels,timeToEvent,threshs(k),'groupNames',{'LR','HR'},'MatSurvOpt',{'NoPlot',true,'Print',false},'dotPlot',false);
    end
    
    pAll = pval;
    threshAll = threshs;
    hrAll = hr;
    statsAll = stats;
    
    elig = find(pval < 0.05);
    
    hr(isinf(hr)) = 10000;
    if(isempty(elig))
        [~,best] = max(hr);
    else
        hr = hr(elig);
        threshs = threshs(elig);
        stats = stats(elig);
        
        medDif = [stats.MedianSurvivalTime];
        medDif = abs(medDif(1,:)-medDif(2,:));
        
        if(any(~isnan(medDif)))
            elig = find(medDif == max(medDif));
            hr = hr(elig);
            threshs = threshs(elig);
        end
        
        
        [~,best] = max(hr);
    end
    thresh = threshs(best);
    
elseif(nThresh == 2)
    
    pval = zeros(length(threshs),length(threshs),1);
    hr = zeros(length(threshs),length(threshs),nThresh);
%     stats = zeros(length(threshs),nThreshs);
    
    minThreshDif = round(smallerCount/5);
    for(k = 1:length(threshs))        
        for(b = (k+minThreshDif):length(threshs))
            [pval,hr,stats] = KMcurveFromThreshold(scores,labels,timeToEvent,[threshs(k),threshs(b)],'MatSurvOpt',{'NoPlot',true,'Print',false,'PairWiseP',true},'dotPlot',false);
            pvals(k,b) = max(pval);
            hrs(k,b) = min(hr);
%             medDifs(k,b) = min(stats.MedianSurvivalTime(1:end-1) - stats.MedianSurvivalTime(2:end));
        end        
    end
    
    pAll = pvals;
    threshAll = threshs;
    hrAll = hrs;
    statsAll = stats;
    
    elig = find(pvals < 0.05);
    
    hrs(isinf(hrs)) = 10000;
    if(isempty(elig))
        [~,best] = max(hrs);
    else
%         hrs = hrs(elig);
%         hrs(pvals > 0.05) = 0;
%         threshs = threshs(elig);
%         stats = stats(elig);
        
%         medDif = [stats.MedianSurvivalTime];
%         medDif = medDif(2,:)-medDif(1,:);
%         
%         if(any(~isnan(medDif)))
%             elig = find(medDif == min(medDif));
%             hr = hr(elig);
%             threshs = threshs(elig);
%         end
        [a,b] = find(hrs==max(hrs(:)));
        thresh = [threshs(a(1)),threshs(b(1))];
        
%         [~,best] = max(hr);
    end
%     thresh = threshs(best);
    
    
end

% function [pval,hr,stats] = getThreshsAbove(scores,labels,timeToEvent,currentThreshsIDX,nextNthreshs,threshs)
%
% if(nextNThreshs ~= 1)
%     [pval,hr,stats] = getThreshsAbove(scores,labels,timeToEvent,currentThreshs,nextNthreshs-1);
% end
%
% for(k = (max(currentThreshsIDX)+1):length(threshs))
%     [pval(k),hr(k),stats(k)] = KMcurveFromThreshold(scores,labels,timeToEvent,[threshs(currentThreshsIDX),threshs(k)],'MatSurvOpt',{'NoPlot',true,'Print',false},'dotPlot',false);
% end
%
%
% end
%
%
%
%
%

















