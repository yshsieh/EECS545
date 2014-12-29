clc
clear all
close all

%% Control Parameters 
SHOW_TESTING = 0;
WORD_TABLE = 1; %0: original; 1: hash table;
PHRASE_TABLE = 1;
NORMALIZED = 0;
WEIGHTING = 0;
TESTING_OR_PREDICT = 1;
TRAIN_NUM = 0; % 0: defult(70% of data)
TEST_NUM = 0; % 0: defult(30% of data) 

% Constant
WORD_NUM = 5000;
PHRASE_NUM = 1000;
EMOJI_SELEC = 100; 
PREDICT_NUM = 100;
TOTAL_NUM = TRAIN_NUM + TEST_NUM;
EMOJI_PER_PAGE = 24;

% Output File 
COMMENT = 'ORG_NormData'; % for output figure name
MAT_FILE = sprintf('%s.mat', 'naive_var_final_WHOLE');
fprintf('Loading Classifier: %s\n', MAT_FILE);
load(MAT_FILE);

DATA_FILE = sprintf('%s.mat', 'data_test_normalized');
fprintf('Loading Test Data: %s\n', DATA_FILE);
load(DATA_FILE);


if WEIGHTING == 1,
    [~, idx] = sort(P_emoji, 'descend');
    P_rank = P_emoji;
    for i = 1:EMOJI_PER_PAGE:length(P_emoji),
        window = min(i + EMOJI_PER_PAGE-1, length(P_emoji));
        P_rank(idx(i:window)) = mean(P_emoji(idx(i:window)));
    end
    P_table = prod([P_ew_0 P_rank], 2);
end



    %% TESTING
    fprintf('Start Testing\n');
    P_table = prod([P_ew_0 P_emoji], 2);
    result = zeros(PREDICT_NUM+3, TEST_NUM);
    hit_result = zeros(6, EMOJI_NUM);
    hit_feature = zeros(5, EMOJI_NUM);
    hit_prior_base = zeros(1, EMOJI_NUM);
    rank_result = zeros(1, PREDICT_NUM+1);
    rank_prior_base = zeros(1, PREDICT_NUM+1);
    each_class = zeros(4, EMOJI_NUM);
    each_class(4, :) = 1:EMOJI_NUM;
    [~, emoji_prob] = sort(P_emoji,'descend');
    for idx = 1:TEST_NUM
        
        [emoji_table, word_match] = naive_predict(data_test(idx).text, dictionary, P_ew_1, P_ew_0, P_table, WORD_TABLE, PHRASE_TABLE);
        if length(word_match)<5 && ~isempty(word_match)
            hit_feature(length(word_match), :) =  hit_feature(length(word_match), :) + ones(1, EMOJI_NUM);
        elseif length(word_match)>5  
            hit_feature(5, :) =  hit_feature(5, :) + ones(1, EMOJI_NUM);
        end
        if ismember(data_test(idx).eid, emoji_table)
            result(1, idx) = data_test(idx).eid; % target value
            result(2, idx) = find(emoji_table==data_test(idx).eid); % success at n_th prediction in Naive Bayes
            result(3, idx) = find(emoji_prob==data_test(idx).eid); % success at n_th prediction in Prior Base
            result(4:PREDICT_NUM+3, idx) = emoji_table(1:PREDICT_NUM); % first 20 prediction
            
            hit_result(1, :) = hit_result(1, :) + [zeros(1, result(2, idx)-1) ones(1, EMOJI_NUM-result(2, idx)+1)];
            if length(word_match)<5 && ~isempty(word_match), 
                hit_result(length(word_match)+1, :) = hit_result(length(word_match)+1, :) + [zeros(1, result(2, idx)-1) ones(1, EMOJI_NUM-result(2, idx)+1)];
            elseif length(word_match)>5
                hit_result(6, :) = hit_result(6, :) + [zeros(1, result(2, idx)-1) ones(1, EMOJI_NUM-result(2, idx)+1)];
            end
            hit_prior_base = hit_prior_base + [zeros(1, result(3, idx)-1) ones(1, EMOJI_NUM-result(3, idx)+1)];
            
            if result(2, idx)<PREDICT_NUM+1
                each_class(1, data_test(idx).eid) = each_class(1, data_test(idx).eid) +1;
                rank_result(1, result(2, idx)+1) = rank_result(1, result(2, idx)+1) +1;
            else
                rank_result(1, 1) = rank_result(1, 1) +1;
            end
            
            if result(3, idx)<PREDICT_NUM+1
                each_class(2, data_test(idx).eid) = each_class(2, data_test(idx).eid) +1;
                rank_prior_base(1, result(3, idx)+1) = rank_prior_base(1, result(3, idx)+1) +1;
            else
                rank_prior_base(1, 1) = rank_prior_base(1, 1) +1;
            end
            each_class(3, data_test(idx).eid) = each_class(3, data_test(idx).eid)+1;
            
        end
        
        if mod(idx, 5000)==0
            fprintf('Testing: %d%% (%d/%d)\n', int8(100*idx/TEST_NUM), idx, TEST_NUM)
        end
        if SHOW_TESTING, 
            word_match
            show_emojis([data_test(idx).eid; emoji_table(1:20)], emoji_dic);
            pause;
        end   
    end
    save(sprintf('naive_result_%s.mat', COMMENT), 'result', 'hit_result', 'hit_prior_base', 'rank_result', 'rank_prior_base', 'each_class');

    %% Plot
    fig_1 = figure(1);
    plot(1:EMOJI_NUM, hit_result(1, 1:EMOJI_NUM)./TEST_NUM.*100, 'b')
    hold on
    plot(1:EMOJI_NUM, hit_prior_base(1:EMOJI_NUM)./TEST_NUM.*100, '-r')
    title('Hitting Rate')
    legend('Naive Bayes','Prior Based')
    xlabel('Number of suggested emojis')
    ylabel('Successful Suggestion Rate(%)')
    
    fig_2 = figure(2);
    each_class = sortrows(each_class', 3)';
    plot(1:EMOJI_NUM, each_class(1, :)./each_class(3, :), '-o')
    hold on
    plot(1:EMOJI_NUM, each_class(2, :)./each_class(3, :), '-rx')
    title(sprintf('Successful Rate in each emoji(within %d predtion)', PREDICT_NUM));
    legend('Naive Bayes', 'Prior Based')
    xlabel('Number of suggested emojis')
    ylabel('Successful Suggestion Rate(%)')
    
    fig_3 = figure(3);
    plot(0:PREDICT_NUM, rank_result(1:PREDICT_NUM+1)./TEST_NUM.*100, '-o')
    hold on
    plot(0:PREDICT_NUM, rank_prior_base(1:PREDICT_NUM+1)./TEST_NUM.*100, '-rx')
    title('Rank')
    legend('Naive Bayes', 'Prior Based')
    xlabel('i^{th} Suggestion')
    ylabel('Successful Suggestion Rate(%)')
   
    fig_4 = figure(4);
    plot(1:EMOJI_NUM, hit_result(2:6, 1:EMOJI_NUM)./hit_feature.*100)
    hold on
    title('Relation bewteen success rate and feature')
    legend('feature: 1','feature: 2','feature: 3','feature: 4', 'feature: >=5')
    xlabel('Number of suggested emojis')
    ylabel('Successful Suggestion Rate(%)')
    
    saveas(fig_1,sprintf('Hit_%s_%s',date, COMMENT), 'fig') 
    saveas(fig_2,sprintf('eachClass_%s_%s',date, COMMENT), 'fig') 
    saveas(fig_3,sprintf('Rank_%s_%s',date, COMMENT), 'fig') 
    saveas(fig_4,sprintf('Feature_%s_%s',date, COMMENT), 'fig') 
