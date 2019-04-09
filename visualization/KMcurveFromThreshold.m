function [pval,hr,stats] = KMcurveFromThreshold(scores,labels,timeToEvent,thresholds,varargin)

p = inputParser;
p.addParameter('EventNames',{'No event','Event'});
p.addOptional('MatSurvOpt',[])
p.addParameter('TitleText','Survivorship');
p.addParameter('groupNames',[]);
p.addParameter('dotPlot',true);
% p.addParameter('NoPlot',false);
parse(p,varargin{:});
params = p.Results;

MatSurvOpt = params.MatSurvOpt;

TitleText = params.TitleText;
groupNames = params.groupNames;
dotPlot = params.dotPlot;
% NoPlot = params.NoPlot;
EventNames = params.EventNames;

markerColors = [0.294,0.545,0.749;0.905,0.192,0.199];

if(dotPlot)
% markerColors = linspecer(2)
figure
hold on

uLabs = sort(unique(labels),'descend');

for(k = uLabs)
    cls{k+1} = find(labels == k);
end
uLabs = fliplr(uLabs);
tte = timeToEvent;

plots = [];
for(z = uLabs)
    plots(end+1) = scatter(tte(cls{z+1}),scores(cls{z+1}),25,'filled','MarkerFaceColor',markerColors(z+1,:),'MarkerEdgeColor','k')
end
xlabel('Days to event')
ylabel('Risk score')
title(TitleText);

for(thresh = 1:length(thresholds))
    plot([0,max(tte)],[thresholds(thresh),thresholds(thresh)],'LineWidth',2,'Color','k')
end
xlim([0,max(tte)]);
legend(plots,EventNames)

%     plot([0,max(testTimeToEvent)],[median(riskScores),median(riskScores)],'-r','LineWidth',2)


if(exist('formatFigureMyWay.m','file'))
    formatFigureMyWay
end
hold off
end

groupLabels = zeros(length(scores),1);
for(thresh = 1:length(thresholds))
    groupLabels = groupLabels + (scores > thresholds(thresh));
end

if(exist('linspecer.m','file'))
    linecolors = linspecer(length(thresholds)+1);
else
    linecolors = lines(length(thresholds)+1);
end

censorLineColors = repmat([0,0,0],[length(thresholds)+1,1]);

groups = unique(groupLabels);
tryCell = cell(1,length(groups));
for(k = 1:length(groups))
    if(isempty(groupNames))
    tryCell(groupLabels == groups(k)) = {[num2str(groups(k))]};
    else
        tryCell(groupLabels == groups(k)) = groupNames(k);
    end
end

% [pval,~,stats] = MatSurv(timeToEvent, labels, tryCell,'PairWiseP',1,'CensorLineColor',censorLineColors,'CensorLineWidth',1,'LineColor',linecolors,'Xlabel','Time (days)','Title',TitleText,'RT_Title','Number at risk','InvHR',1,'GroupOrder',fliplr(1:length(groupNames)),'Use_HR_MH',false,'NoPlot',NoPlot);
if(~isempty(MatSurvOpt))
[pval,~,stats] = MatSurv(timeToEvent, labels, tryCell,'PairWiseP',1,'CensorLineColor',censorLineColors,'CensorLineWidth',1,'LineColor',linecolors,'Xlabel','Time (days)','RT_Title','Number at risk','InvHR',1,'GroupOrder',fliplr(1:length(groupNames)),'Use_HR_MH',false,MatSurvOpt{:});
else
    [pval,~,stats] = MatSurv(timeToEvent, labels, tryCell,'PairWiseP',1,'CensorLineColor',censorLineColors,'CensorLineWidth',1,'LineColor',linecolors,'Xlabel','Time (days)','RT_Title','Number at risk','InvHR',1,'GroupOrder',fliplr(1:length(groupNames)),'Use_HR_MH',false);
end

hr = stats.HR_logrank_Inv;