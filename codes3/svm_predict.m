function [  ] = svm_predict( sentence , IS_GROUP_MODEL)
% 2014/03/29: predict emoji in real time
% 2014/04/07: update group models
    close all;

    SVM_MODEL_NAME = 'svm_model_small';
    SVM_GROUP_MODEL_NAME = 'svm_model_group'
    
    if IS_GROUP_MODEL == 0,
        load(SVM_MODEL_NAME);
    elseif IS_GROUP_MODEL == 1,
        load(SVM_GROUP_MODEL_NAME);
    else
        assert(1==0, 'ERROR: wrong value of IS_GROUP_MODEL\n');
    end

    text = lower(sentence);

    x_now = zeros(N_WORD, 1);

    % 1. parse text
    tokens = unique(strsplit(text)); % get a word form string
    for k = 1:size(tokens,2);
        if IS_WORD_NEED_TO_BE_HASHED == 1,
            word_idx = find(ismember(words, word_hash(tokens{k}))); % token is in dictionary or not
        else
            word_idx = find(ismember(words, tokens{k})); % token is in dictionary or not
        end

        if(~isempty(word_idx)) % exist in our word dictionary
            x_now(word_idx) = 1;
        end
    end

    if(sum(x_now) == 0),
        fprintf('WARN: no matched words\n');
        return
    end
    

    % predict based on svm
    if IS_GROUP_MODEL == 0,
        probs_now = zeros(N_EMOJI);
        neg_probs_now = zeros(N_EMOJI);
        for model_idx = 1:N_EMOJI,
            fprintf('---------- svm predict of model = %d ----------\n',model_idx);
            model = models{model_idx};
            [result, acc, prob]  = svmpredict([1],x_now',model,'-b 1');
            probs_now(model_idx) = prob(:,model.Label==1);
            neg_probs_now(model_idx) = prob(:,model.Label==0);
        end

        [value_sort, idx_sort] = sort(probs_now, 'descend');
        idx_sort = idx_sort(1:N_SUGGEST); % only fetch first N_SUGGEST prediction
        ranks = eids_selected(idx_sort);


        figure; hold on;
        plot(probs_now);

        show_emojis([1,ranks], emojis);

        words(x_now(:)==1)
    elseif IS_GROUP_MODEL == 1,
        probs_now = zeros(N_GROUP,1);
        neg_probs_now = zeros(N_GROUP,1);
        for model_idx = 1:N_GROUP,
            fprintf('---------- svm predict of model = %d ----------\n',model_idx);
            model = group_models{model_idx};
            [result, acc, prob]  = svmpredict([1],x_now',model,'-b 1');
            probs_now(model_idx) = prob(:,model.Label==1);
            neg_probs_now(model_idx) = prob(:,model.Label==0);
        end

        [value_sort, idx_sort] = sort(probs_now, 'descend');
        %group_idx_sort = idx_sort(1); % only use the first group
        ranks = [eids_groups{idx_sort}];
        ranks = ranks(1:N_SUGGEST);


        figure; hold on;
        plot(probs_now);

        show_emojis([1,ranks], emojis);

        words(x_now(:)==1)    
    else
        
    end
    
end

