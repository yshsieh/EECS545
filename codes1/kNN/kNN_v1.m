%==========================================================================
% 2013/02/20: successfully compile and add path of svm library
% 2013/03/15: train svm with multi-class problems to solve our problem
% 2013/03/29: update the word hash function
% 2013/03/29: update a new way to normized preprocessing data
%==========================================================================
clc
clear all;
close all;
load('inputdata.mat');

NEED_TO_KNN = 1;


%--------------------------------------------------------------------------
% 3. begin to make svm model
% *** only retrian SVM if NEED_TO_SVM == 1 ***
%--------------------------------------------------------------------------
if NEED_TO_KNN==1,
    
    fprintf('---- start ---- K nearest neighbor algorithm \n');
    kNN_k = 4500;
        
    %kNN  [D,I] = pdist2(X,Y,distance,'Smallest',K)
    [kDist, kIndx] = pdist2(x_train', x_test','cosine','Smallest',kNN_k);
    voteTarget = zeros(N_SUGGEST,N_TEST);
    for i = 1:N_TEST,
        
        if (mod(i, (N_TEST/100)) == 0)
            fprintf('test case %i',i);
        end
        target_k = y_train(kIndx(:,i)); 
        uniqueTarget = unique(target_k);            
        histTarget = histc(target_k,uniqueTarget);
        [~,idx] = sort(histTarget,'descend');
        
        if size(uniqueTarget,2) < N_SUGGEST,
            uniqueTarget = [uniqueTarget repmat(uniqueTarget(end),1,N_SUGGEST-size(uniqueTarget,2))];
        end
        if size(histTarget,2)  < N_SUGGEST,
            histTarget = [histTarget repmat(histTarget(end),1,N_SUGGEST-size(histTarget,2))];
        end
        if size(idx,2) < N_SUGGEST,
            idx = [idx repmat(idx(end),1,N_SUGGEST-size(idx,2))];
        end    
        voteTarget(:,i) = uniqueTarget(idx)';
    end
    
    fprintf('---- finish ---- K nearest neighbor algorithm \n');

    
end

ranks = voteTarget;

%--------------------------------------------------------------------------
% 4. begin to evaluate results
%--------------------------------------------------------------------------
%[value_sort, idx_sort] = sort(probs, 1, 'descend');
%idx_sort = idx_sort(1:N_SUGGEST, :); % only fetch first N_SUGGEST prediction
%ranks = eids_selected(idx_sort);

results = zeros(N_TEST,1);
for x_idx = 1:N_TEST,
    find_result = find(ranks(:,x_idx)==y_test(x_idx),1);
    if(isempty(find_result)), % unmatch!
        results(x_idx) = 0;
    else
        results(x_idx) = find_result;
    end
end
plot(histc(results,1:N_SUGGEST)'/N_TEST);
title('kNN');
kNNresults = results;
save('kNNresultsFile','kNNresults');

