%{
clc
clear all;
close all;
load('inputdata_medium.mat');
%}
NEED_TO_SVM = 0
NEED_TO_reSVM = 0
NEED_TO_GROUP = 1

N_GROUP = 9;


%--------------------------------------------------------------------------
% 3. begin to make svm model
% *** only retrian SVM if NEED_TO_SVM == 1 ***
%--------------------------------------------------------------------------
if NEED_TO_SVM==1,
    
    % get the traiing model form svm
    x_train_tr = x_train';
    y_train_tr = y_train';  
    x_test_tr = x_test';
    y_test_tr = y_test';
    models = cell(N_EMOJI,1);
    for model_idx = 1:N_EMOJI,
        fprintf('---------- svm train of model = %d ----------\n',model_idx);
        eid = eids_selected(model_idx);
        %models{model_idx} = svmtrain(double(y_train==eid)', x_train','-t 2 -c 1 -g 1 -h 0 -b 1');
        models{model_idx} = svmtrain(double((y_train_tr==eid)*2-1), x_train_tr,'-t 3 -c 1 -g 1 -h 0 -b 1');
    end
    
    % predict based on svm
    probs = zeros(N_EMOJI, N_TEST);
    neg_probs = zeros(N_EMOJI, N_TEST);
    for model_idx = 1:N_EMOJI,
        fprintf('---------- svm predict of model = %d ----------\n',model_idx);
        model = models{model_idx};
        eid = eids_selected(model_idx);
        [result, acc, prob]  = svmpredict(double((y_test_tr==eid)*2-1),x_test_tr,model,'-b 1');
        probs(model_idx,:) = prob(:,model.Label==1);
        neg_probs(model_idx,:) = prob(:,model.Label==-1);
    end
    
    
elseif NEED_TO_reSVM==1,
    
    
    f = 0.3;
    % get the traiing model form svm
    models = cell(N_EMOJI,1);
    for model_idx = 1:N_EMOJI,
        fprintf('---------- svm train of model = %d ----------\n',model_idx);
        eid = eids_selected(model_idx);
        models{model_idx} = svmtrain(double((y_train_tr==eid)*2-1), x_train_tr,'-t 3 -c 1 -g 1 -h 0 -b 1');
    end
    
    %extend train data feature
    x_train_extend = zeros(N_WORD + N_EMOJI,N_TRAIN);
    
    for d = 1:N_TRAIN,
        if (mod(d,100)==1), fprintf('extend SVM data %i',d); end
        x = x_train(:,d);
        extend_vector = zeros(1,N_EMOJI);
        score = zeros(1,N_EMOJI);
        for model_idx = 1:N_EMOJI,
            w = (models{model_idx}.sv_coef' * full(models{model_idx}.SVs));
            b = -models{model_idx}.rho;
            score(model_idx) = w*x + b;
            if (score(model_idx) > 0),
                extend_vector(model_idx) = 1;
            else
                extend_vector(model_idx) = -1;
            end
        end
        if (isempty(find(extend_vector == 1)))
            [~, idx] = max(score);
            extend_vector(idx) = 1;
        end
        x_train_extend(:,d) = [(x_train(:,d)*f)' extend_vector*(1-f)]';
        x_train_extend(:,d) = x_train_extend(:,d)/norm(x_train_extend(:,d));
    end
    
    %retrain SVM
    x_train_extend_tr = x_train_extend';
    x_test_extend_tr = x_test_extend';
    
    models_2 = cell(N_EMOJI,1);
    for model_idx = 1:N_EMOJI,
        fprintf('---------- svm re-train of model = %d ----------\n',model_idx);
        eid = eids_selected(model_idx);
        models_2{model_idx} = svmtrain(double((y_train_tr==eid)*2-1), x_train_extend_tr,'-t 3 -c 1 -g 1 -h 0 -b 1');
    end
    
    %extend test data feature
    x_test_extend = zeros(N_WORD + N_EMOJI,N_TEST);
    
    for d = 1:N_TEST,
        if (mod(d,100)==1), fprintf('extend reSVM data %i',d); end    
        x = x_test(:,d);
        extend_vector = zeros(1,N_EMOJI);
        score = zeros(1,N_EMOJI);
        for model_idx = 1:N_EMOJI,
            w = (models{model_idx}.sv_coef' * full(models{model_idx}.SVs));
            b = -models{model_idx}.rho;
            score(model_idx) = w*x + b;
            if (score(model_idx) > 0),
                extend_vector(model_idx) = 1;
            else
                extend_vector(model_idx) = -1;
            end
        end
        if (isempty(find(extend_vector == 1)))
            [~, idx] = max(score);
            extend_vector(idx) = 1;
        end
        x_test_extend(:,d) = [(x_test(:,d)*f)' extend_vector*(1-f)]';
        x_test_extend(:,d) = x_test_extend(:,d)/norm(x_test_extend(:,d));
        
    end
    
    % predict based on svm models_2
    probs = zeros(N_WORD + N_EMOJI, N_TEST);
    neg_probs = zeros(N_WORD + N_EMOJI, N_TEST);
    for model_idx = 1:N_EMOJI,
        fprintf('---------- svm predict of model = %d ----------\n',model_idx);
        model = models_2{model_idx};
        eid = eids_selected(model_idx);
        [result, acc, prob]  = svmpredict(double((y_test==eid)*2-1)',x_test_extend',model,'-b 1');
        probs(model_idx,:) = prob(:,model.Label==1);
        neg_probs(model_idx,:) = prob(:,model.Label==-1);
    end
    
elseif NEED_TO_GROUP == 1,
%{
%{    
    % group predict model - manually grouping
    
    eids_groups{1} = [369:1:380, 803];  % heart
    eids_groups{2} = [534:1:557];       % clock
    eids_groups{3} = [563, 566:1:570, 572:1:574,576, 578, 587:1:592]; % happy
    eids_groups{4} = [565, 578:1:585, 593,594, 597:1:606, 608, 611, 612, 620 ,626]; % sad
    eids_groups{5} = [52:1:63];         % moon
    eids_groups{6} = [69:1:86];         % flower and tree
    eids_groups{7} = [87:1:143];        % food
    eids_groups{8} = [185:1:192];       % music
    eids_groups{9} = [194:1:205];       % sport
    eids_groups{10}= [223:1:284];       % animal
    eids_groups{11}= [291:1:301, 391,786];  % gesture
    eids_groups{12}= [442:1:459];       % TV and mailbox
    eids_groups{13}= [639:1:679];       % traffic
    
%}    
    edis_groups = cell(1,13);
    eids_groups{1}=[300,201];
    eids_groups{2}=[148,149];
    eids_groups{3}=[608,583,604,581,597,593,515];
    eids_groups{4}=[153,152,145,154,146];
    eids_groups{5}=[576,370,759,803,372,377,371,360,379,622,277,285,373,144,352,363,332,302];
    eids_groups{6}=[298,297,396,468,501];
    eids_groups{7}=[572,564,567,295,635,577,787,186,575,386,142,65,737,619];
    eids_groups{8}=[573,587,638,792,566,374,76,376,375,392,563,66,75,365,296,744,589,74,77,378,368,624,634,83,86,82,78]; 
    eids_groups{9}=[565,591,574,631,578,633,612,614,391,592,569,350,509,607,568,590,286,387,786,389];
    
    %N_GROUP = length(eids_groups);
    
    % get the traiing model form svm
    
    x_train_tr = x_train';
    group_models = cell(N_GROUP,1);
    for group_idx = 1:N_GROUP,
        fprintf('---------- svm train of group model = %d ----------\n',group_idx);
        eids_in_group = eids_groups{group_idx};
        
        y_train_in_group = zeros(N_TRAIN,1);
        for i=1:N_TRAIN,
            % mark any emoji in the group to 1, else to 0
            y_train_in_group(i) = sum(eids_in_group==y_train(i));
        end
        group_models{group_idx} = svmtrain(double((y_train_in_group)*2-1), x_train_tr,'-t 2 -c 1 -h 0 -b 1');
    end
%}    
    % predict based on svm
    x_test_tr = x_test';
    probs = zeros(N_GROUP, N_TEST);
    for group_idx = 1:N_GROUP,
        fprintf('---------- svm predict of group model = %d ----------\n',group_idx);
        eids_in_group = eids_groups{group_idx};
        
        y_test_in_group = zeros(N_TEST,1);
        for i=1:N_TEST,
            % mark any emoji in the group to 1, else to 0
            y_test_in_group(i) = sum(eids_in_group==y_test(i));
        end
        
        model = group_models{group_idx};
        [result, acc, prob]  = svmpredict(double((y_test_in_group)*2-1),x_test_tr,model,'-b 1');
        probIdx = find(model.Label==1);
        %negpIdx = (model.Label==-1);
        if probIdx == 0,
            probs(group_idx,:) = 0;
        else
            probs(group_idx,:) = prob(:,probIdx);
        end
        %{
        if negpIdx ==0,
            neg_probs(group_idx,:) = 0;
        else
            neg_probs(group_idx,:) = prob(:,model.Label==-1);
        end
        %}
    end 
end

%}

%--------------------------------------------------------------------------
% 4. begin to evaluate results
%--------------------------------------------------------------------------
if NEED_TO_GROUP,
    [value_sort, idx_sort] = sort(probs, 1, 'descend');
    idx_sort = idx_sort(1:N_GROUP, :); % only fetch first N_SUGGEST prediction
    
    results = zeros(N_TEST,1);
    for x_idx = 1:N_TEST,
        find_result = find(idx_sort(:,x_idx)==y_test(x_idx));
        if(isempty(find_result)), % unmatch!
            results(x_idx) = 0;
        else
            results(x_idx) = 1;
        end
    end
else
    [value_sort, idx_sort] = sort(probs, 1, 'descend');
    idx_sort = idx_sort(1:N_SUGGEST, :); % only fetch first N_SUGGEST prediction
    ranks = eids_selected(idx_sort);
    
    results = zeros(N_TEST,1);
    for x_idx = 1:N_TEST,
        find_result = find(ranks(:,x_idx)==y_test(x_idx));
        if(isempty(find_result)), % unmatch!
            results(x_idx) = 0;
        else
            results(x_idx) = find_result;
        end
    end
end
plot(histc(results,1:N_SUGGEST)'/N_TEST);
if NEED_TO_SVM,
    title('SVM');
    SVMmodels = models;
    SVMresults = results;
    save('SVMresultsFile','SVMresults','SVMmodels');
elseif NEED_TO_reSVM,
    title('reSVM');
    reSVMmodels = models_2;
    reSVMresults = results;
    save('reSVMresultsFile','reSVMresults','reSVMmodels');
elseif NEED_TO_GROUP,
    title('GROUP');
    gSVMmodels = group_models;
    gSVMresults = results;
    save('gSVMresultsFile','gSVMresults','gSVMmodels');
end
%{

%eid_plot = eids_selected(3);
%eid_plot_x = find(y_test==eid_plot);
eid_plot_x = 1:N_TEST;
for x_idx = eid_plot_x,
    eid_truth = y_test(x_idx)
    plot_eid_idx = find(eids_selected==eid_truth);
    words(x_test(:,x_idx)==1)
    %ranks(:,x_idx)
    
    
    figure; hold on;
    plot(probs(:,x_idx));
    %plot(neg_probs(:,x_idx),'g--');
    plot([plot_eid_idx,plot_eid_idx], [0,max(probs(:,x_idx))], 'r');
    
    show_emojis([eid_truth;ranks(:,x_idx)], emojis);
    close;
    close;
end


figure;
%plot_config;
hold on;
plot(sort(results),'b-');

%}

%{

%--------------------------------------------------------------------------
% visulize results
%--------------------------------------------------------------------------

group_idx = 2;
plot_group_prob(group_probs(group_idx,:), y_test,eids_groups{group_idx} );


% 1. plot individual emoji distribution
%eids_plot = [576];
eids_plot = [369:1:380, 803];
%{
y_train_plot = zeros(N_TRAIN,1)';
y_test_plot = zeros(N_TEST,1)';
for i=1:N_TRAIN,
    y_train_plot(i) = sum(eids_plot==y_train(i));
end
for i=1:N_TEST,
    y_test_plot(i) = sum(eids_plot==y_test(i));
end

model_plot = svmtrain(double(y_train_plot)', x_train','-t 0 -c 1 -h 0 -b 1');
[result, acc, prob_plot]  = svmpredict(double(y_test_plot)',x_test',model_plot,'-b 1');
%}
eids_idx_plot = zeros(length(eids_plot),1);
for eid_idx = 1:length(eids_plot),
    find_edi_idx = find(eids_selected==eids_plot(eid_idx))
    if(isempty(find_edi_idx)),
        eids_idx_plot(eid_idx) = -1;
    else
        eids_idx_plot(eid_idx) = find(eids_selected==eids_plot(eid_idx));
    end
end

eids_idx_plot(eids_idx_plot==-1) = []
plot([probs(:,y_test_plot==1); prob_plot(y_test_plot==1,2)']);

plot([probs(eids_idx_plot,y_test_plot==1); prob_plot(y_test_plot==1,2)']);

%{
eid_plot = 576;
eid_idx_plot = find(eids_selected==eid_plot)
plot(probs(:,y_test==587));




figure;
%plot_config;
hold on;
plot(sort(results),'b-');
%}
%xlabel('log(c)')
%ylabel('Accuracy (%)')
%legend('cross validateion','test accuracy','location','South');
%saveas(gcf,'q1_3','pdf');

%}

