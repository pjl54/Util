    % Calcultes intra- and inter-dataset stability
% Inputs:
% data: Cell array where each cell contains a matrix of feature values from a specific site
% rows of the data are patients, columns are feature values
% nIter: Number of random splits to perform in calculating instability
% Patrick Leo - 2016
function interDifScore = measureInterStability(data,nIter)

% Number of random splits to perform in calculating intra-dataset instability
if(~exist('nIter','var'))
    nIter = 1000;
end

% Number of features is number of columns
featCount = length(data{1}(1,:));
interDifTally = zeros(1,featCount);

parfor(i = 1:featCount)
    fprintf('Inter-Dif feature %d \n',i)
    for(ii = 1:length(data))
        for(r = (ii+1):length(data))
            
            % Store result of each subset comparison
            H = zeros(1,nIter);
            
            % split dataset and tally features different
            for(z = 1:nIter)
    
                % use 3/4 of each dataset per iteration
                B1=datasample(1:size(data{r},1),round(length(data{r}(:,1)) * 3/4),'replace',false);
                B2=datasample(1:size(data{ii},1),round(length(data{ii}(:,1)) * 3/4),'replace',false);
                
                
                % Compare feature across subsets
                if(any(~isnan(data{ii}(B2,i))) && any(~isnan(data{r}(B1,i))))
                [P,H(z)] = ranksum(data{ii}(B2,i),data{r}(B1,i));
                else
                    H(z) = nan;
                end
                
            end
            
            interDifTally(i) = interDifTally(i) +  mean(H);
        end
    end
end

% normalize scores
interDifScore= interDifTally / nchoosek(length(data),2);
