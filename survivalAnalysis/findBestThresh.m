function [thresh, threshAll, hrAll, statsAll] = findBestThresh(scores,labels,timeToEvent)

threshs = (sort(scores(2:end)) + sort(scores(1:end-1)))/2;

labelers = unique(labels);
if(length(labelers) > 1)
    smallerCount = min(sum(labels==labelers(1)),sum(labels==labelers(2)));
else
    smallerCount = length(labels)/2;
end

% threshs = threshs(round(length(threshs)/3):round(length(threshs)*2/3));
threshs = threshs(round(smallerCount)/2:round(length(threshs)-smallerCount/2));

for(k = 1:length(threshs))
    [pval(k),hr(k),stats(k)] = KMcurveFromThreshold(scores,labels,timeToEvent,threshs(k),'MatSurvOpt',{'NoPlot',true,'Print',false},'dotPlot',false);
end

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
    medDif = medDif(2,:)-medDif(1,:);
    
    if(any(~isnan(medDif)))
        elig = find(medDif == min(medDif));
        hr = hr(elig);
        threshs = threshs(elig);
    end
    
    
    [~,best] = max(hr);
end
thresh = threshs(best);