function [pval,hr,stats] = KMcurveFromThreshold(scores,labels,timeToEvent,thresholds,varargin)

p = inputParser;
p.addParameter('EventNames',{'No event','Event'});
p.addOptional('MatSurvOpt',[])
p.addParameter('TitleText','Survivorship');
p.addParameter('groupNames',[]);
p.addParameter('dotPlot',true);
p.addParameter('KMPlot',true);
p.addParameter('RiskTableName','Number at risk');
p.addParameter('XLabel','Time (days)');
p.addParameter('linecolors',[]);
% p.addParameter('NoPlot',false);
parse(p,varargin{:});
params = p.Results;

MatSurvOpt = params.MatSurvOpt;

TitleText = params.TitleText;
groupNames = params.groupNames;
dotPlot = params.dotPlot;
% NoPlot = params.NoPlot;
EventNames = params.EventNames;
KMPlot = params.KMPlot;
linecolors = params.linecolors;

% markerColors = [0.294,0.545,0.749;0.905,0.192,0.199];
markerColors = [0.3639, 0.5755, 0.7484; 0.9153, 0.2816, 0.2878];

if(size(scores,1) ~= size(labels,1))
    scores = reshape(scores,[size(labels,1),size(labels,2)]);
end
if(size(labels,1) ~= size(labels,1))
    labels = reshape(scores,[size(labels,1),size(labels,2)]);
end


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
    xlabel('Years to event')
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

if(KMPlot)
    groupLabels = zeros(1,length(scores));
    for(thresh = 1:length(thresholds))
        groupLabels = groupLabels + (scores > thresholds(thresh));
    end
    
    if(isempty(linecolors))
        if(exist('linspecer.m','file'))
            linecolors = linspecer(length(thresholds)+1);
        else
            linecolors = lines(length(thresholds)+1);
        end
        
        % Make sure greenest color is lowest risk
        [~,blueorder] = sort(linecolors(:,2),'descend');
        linecolors = linecolors(blueorder,:);
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
    
    if(numel(unique(groupLabels)) == 1)
        fprintf('Only one group \n')
        hr = nan;
    else
        
        if(~isempty(MatSurvOpt))
            [pval,~,stats] = MatSurv(timeToEvent, labels, tryCell,'PairWiseP',1,'CensorLineColor',censorLineColors,'CensorLineWidth',1,'LineColor',linecolors,'XLabel',params.XLabel,'InvHR',1,'GroupOrder',fliplr(1:length(groupNames)),'Use_HR_MH',false,MatSurvOpt{:});
        else
            [pval,~,stats] = MatSurv(timeToEvent, labels, tryCell,'PairWiseP',1,'CensorLineColor',censorLineColors,'CensorLineWidth',1,'LineColor',linecolors,'XLabel',params.XLabel,'RT_Title','Number at risk','InvHR',1,'GroupOrder',fliplr(1:length(groupNames)),'Use_HR_MH',false);
        end
        
        hr = stats.HR_logrank_Inv;
    end
    
    if(exist('formatFigureMyWay.m','file'))
            formatFigureMyWay;
    end
end