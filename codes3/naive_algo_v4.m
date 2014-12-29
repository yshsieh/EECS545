clc
clear all
close all

%% Control Parameters 
RE_TRAIN = 0;
SHOW_TESTING = 0;
WORD_TABLE = 1; %0: original; 1: hash table;
PHRASE_TABLE = 1;
NORMALIZED = 0;
WEIGHTING = 1;
TESTING_OR_PREDICT = 0;
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
COMMENT = 'final_WHOLE'; % for output figure name
MAT_FILE = sprintf('naive_var_%s.mat', COMMENT);
SQL_FILE = 'instagram_hyper.sqlite';
DATABASE_UPDATE = 0;

%% TRAINING
if RE_TRAIN ~= 1,
    fprintf('Loading Data: %s\n', MAT_FILE);
    load(MAT_FILE);
else
    %% Initial
    mksqlite('open', SQL_FILE);
    
    if WORD_TABLE == 1,   
        word_collect = mksqlite('SELECT word FROM word_hash ORDER BY wid'); 
    else
        word_collect = mksqlite('SELECT word FROM word ORDER BY wid');  
    end
    
    if PHRASE_TABLE ==1, 
        phrase_collect = mksqlite('SELECT phrase FROM word_phrase_hash ORDER BY pid'); 
        dictionary = [{word_collect(1:WORD_NUM).word}, {phrase_collect(1:PHRASE_NUM).phrase}];
    else
        dictionary = {word_collect(1:WORD_NUM).word};
    end
    
    emoji_dic = mksqlite('SELECT * FROM emoji ORDER BY rowid');
    EMOJI_NUM = size(emoji_dic, 1);
    
    if NORMALIZED ==1,
        data_train = [];
        data_test = [];
        % a. find out the msost used 100 emoji
        emojis = mksqlite('SELECT * FROM emoji order by rowid'); % rowid is eid
        emojis_count = mksqlite('select count(*) as c, emoji.rowid from emoji left join emoji_text_mapping on emoji.rowid = emoji_text_mapping.eid group by emoji.rowid order by emoji.rowid'); % rowid is eid
        emojis_count = [emojis_count.c];
        
        % select emojis
        [value_sort, idx_sort] = sort(emojis_count,'descend');
        eids_selected = idx_sort(1:EMOJI_SELEC);
        if (TEST_NUM == 0)&&(TRAIN_NUM == 0),
            TRAIN_NUM = floor(0.7* value_sort(EMOJI_SELEC))*EMOJI_SELEC;
            TEST_NUM = value_sort(EMOJI_SELEC)*EMOJI_SELEC - TRAIN_NUM;
            TOTAL_NUM = TRAIN_NUM + TEST_NUM;
        end    
        
        N_DATA_READ_PER_EMOJI = floor(TOTAL_NUM/EMOJI_SELEC);
        N_READ = N_DATA_READ_PER_EMOJI*1.3; % in case there is invlid input

        assert(value_sort(EMOJI_SELEC) >= N_READ, sprintf('ERROR: trace of last selected emoji is not enough\n%d < %d', value_sort(EMOJI_SELEC), N_READ));
        assert(TEST_NUM>EMOJI_SELEC, ('TEST_NUM must larger than EMOJI_SELEC'));
        for eids_selected_idx = 1:EMOJI_SELEC,
            data = [];
            eid_selected = eids_selected(eids_selected_idx);
            
            fprintf('Read select_idx = %d, eid = %d\n',eids_selected_idx,eid_selected);
            
            data_emoji = mksqlite(sprintf('SELECT * FROM emoji_text_mapping where eid = %d order by random() limit %d', eid_selected, N_READ));
            
            use_idx = 1;
            for data_idx = 1:N_READ,
                % fetch emoji idex (label)
                eid = data_emoji(data_idx).eid; % select which row(belongs to which emoji)
                text = data_emoji(data_idx).text; % get a string input
                if ~isempty(text); % this is a valid text! -> add to our table
                    % b. update x
                    tokens = strsplit(text); % get a word form string
                    check_word_exists = 0;
                    for k = 1:size(tokens,2);
                        if WORD_TABLE == 1,
                            word_idx = find(ismember(dictionary, word_stem(tokens{k}))); % token is in dictionary or not
                        else
                            word_idx = find(ismember(dictionary, tokens{k})); % token is in dictionary or not
                        end
                        if(~isempty(word_idx)) % exist in our word dictionary
                            check_word_exists = 1;
                            break;
                        end
                    end
                    data = [data; data_emoji(data_idx)];
                    use_idx = use_idx+1;
                    if use_idx > N_DATA_READ_PER_EMOJI,
                        break;
                    end
                end
            end
            data_train = [data_train; data(1:TRAIN_NUM/EMOJI_SELEC)];
            data_test = [data_test; data(TRAIN_NUM/EMOJI_SELEC +1 :end)];
        end
    else
        data_all = mksqlite('SELECT * FROM emoji_text_mapping');
        if TRAIN_NUM==0, TRAIN_NUM = floor(0.7*size(data_all, 1)); end
        if TEST_NUM==0, TEST_NUM = size(data_all, 1) -TRAIN_NUM; end
        data_train = data_all(1:TRAIN_NUM, 1);
        data_test = data_all(TRAIN_NUM+1:TRAIN_NUM+TEST_NUM);
    end

    %% Calculate Probability of Xj give Ck
    fprintf('Start Training\n');
    P_ew_1 = zeros(EMOJI_NUM, WORD_NUM + PHRASE_TABLE*PHRASE_NUM); % e := emoji, w:=words; prbability of word=1 given emoji
    if NORMALIZED, P_ew_1(eids_selected, :) = 1/EMOJI_SELEC; end
    emoji_count = zeros(EMOJI_NUM, 1); % total number of sentences in each emoji    

    for i = 1:TRAIN_NUM,
        
        eid_idx = data_train(i).eid; % select which row(belongs to which emoji)
        emoji_count(eid_idx) = emoji_count(eid_idx) + 1; % sentence number given emoji
        train_text = data_train(i).text; % get a string input
        if ~isempty(train_text);
            train_text = strrep(train_text, ' t ', 't ');
            tokent_splite = strsplit(train_text);
            [~, idx] =  unique(tokent_splite);
            tokens = tokent_splite(sort(idx));

            if(PHRASE_TABLE == 0)
                for k = 1:size(tokens,2),
                    if WORD_TABLE == 1,   token_input = word_stem(tokens{k});
                    else    token_input = tokens{k}; end
                    Xj_idx = find(ismember(dictionary, token_input)); % token is in dictionary or not
                    if(~isempty(Xj_idx)) % exist
                        P_ew_1(eid_idx, Xj_idx) = P_ew_1 (eid_idx, Xj_idx) + 1;
                    end
                end
            else
                word1_idx_now = -1;
                word2_idx_now = -1;
                first_valide_taken = -1;
                for k = 1:size(tokens,2),
                    if WORD_TABLE == 1,   token_input = word_stem(tokens{k});
                    else    token_input = tokens{k};
                    end

                    Xj_idx = find(ismember(dictionary, token_input)); % token is in dictionary or not
                    if(~isempty(Xj_idx)) % exist
                        first_valide_taken = k;
                        word1_idx_now = Xj_idx;
                        word1_now = dictionary(Xj_idx);
                        break;
                    end
                end
                if  first_valide_taken >= 0,
                    phrase_is_hitted = 0;
                    single_word = 1;
                    for k = first_valide_taken+1:size(tokens,2),
                        if WORD_TABLE == 1,   token_input = word_stem(tokens{k});
                        else    token_input = tokens{k}; 
                        end

                        Xj_idx = find(ismember(dictionary, token_input)); % token is in dictionary or not
                        if(~isempty(Xj_idx)) % exist word 2
                            single_word = 0;

                            word2_idx_now = Xj_idx;
                            word2_now = dictionary(Xj_idx);
                            %word1_now
                            %word2_now
                            phrase_now = {[cell2mat(word1_now), cell2mat(word2_now)]};
                            %phrase_now
                            
                            phrase_idx = find(ismember(dictionary(WORD_NUM + 1:end), phrase_now));


                            if ~isempty(phrase_idx) && phrase_idx > WORD_NUM, % find a phrase
                                P_ew_1(eid_idx, phrase_idx) = P_ew_1 (eid_idx, phrase_idx) + 1;
                                phrase_is_hitted = 1;
                            else % don't use phrase
                                P_ew_1(eid_idx, word1_idx_now) = P_ew_1 (eid_idx, word1_idx_now) + 1;
                                phrase_is_hitted = 0;
                            end


                            word1_idx_now = word2_idx_now;
                            word1_now = word2_now;
                        end
                    end
                    if(single_word==1)
                        P_ew_1(eid_idx, word1_idx_now) = P_ew_1 (eid_idx, word1_idx_now) + 1;
                    end

                    if(single_word==0 && phrase_is_hitted == 0),
                        P_ew_1(eid_idx, word2_idx_now) = P_ew_1 (eid_idx, word2_idx_now) + 1;
                    end
                end
            end
            
        end
        if mod(i, 5000)==0
            fprintf('Training: %d%% (%d/%d)\n', int8(100*i/TRAIN_NUM), i, TRAIN_NUM);
        end
    end

    P_emoji = emoji_count./sum(emoji_count);
    P_ew_1 = P_ew_1./repmat(emoji_count, 1, size(P_ew_1, 2));
    P_ew_0 = ones(size(P_ew_1))-P_ew_1;
    P_ew_1((emoji_count==0), :) = 0;
    P_ew_0((emoji_count==0), :) = 0;
    if WEIGHTING == 1,
        [~, idx] = sort(P_emoji, 'descend');
        P_rank = P_emoji;
        for i = 1:EMOJI_PER_PAGE:length(P_emoji),
            window = min(i + EMOJI_PER_PAGE-1, length(P_emoji));
            P_rank(idx(i:window)) = mean(P_emoji(idx(i:window)));
        end
        P_table = prod([P_ew_0 P_rank], 2);
    else
        P_table = prod([P_ew_0 P_emoji], 2);
    end

    %% Database Update
    if DATABASE_UPDATE ==1,
        mksqlite('DROP TABLE IF EXISTS naive');
        mksqlite('CREATE  TABLE naive ("eid" INTEGER, "wid" INTEGER, "p" DOUBLE)');
        mksqlite('DROP TABLE IF EXISTS emoji_prob');
        mksqlite('CREATE  TABLE emoji_prob ("eid" INTEGER, "p" DOUBLE)');
        sqlite_str = 'INSERT INTO naive (eid, wid, p) VALUES ';
        value_insert = '';
        [i_nz, j_nz] = find(P_ew_1~=0);
        for i = 1:size(i_nz, 1) % need further simplified??
            value_insert = sprintf('%s%s', value_insert,  sprintf('(%d, %d, %f), ',i_nz(i), j_nz(i), P_ew_1(i_nz(i), j_nz(i)))); 
            if mod(i, 500)==0
                fprintf('Database Updating: %d%% (%d/%d)\n', int8(100*i/i_nz), i, i_nz);
                mksqlite(sprintf('%s%s',sqlite_str,  value_insert(1:end-2)));
                sqlite_str = 'INSERT INTO naive (eid, wid, p) VALUES ';
                value_insert = '';
            end
        end
        mksqlite(sprintf('%s%s',sqlite_str,  value_insert(1:end-2)));

        sqlite_str = 'INSERT INTO emoji_prob (eid, p) VALUES';
        value_insert = '';
        for i = 1:EMOJI_NUM
            value_insert = sprintf('%s%s', value_insert , sprintf('(%d, %f), ',i,  P_emoji(i)));
            if mod(i, 100)==0
                mksqlite(sprintf('%s%s',sqlite_str,  value_insert(1:end-2)));
                sqlite_str = 'INSERT INTO emoji_prob (eid, p) VALUES';
                value_insert = ''; 
            end
        end
        mksqlite(sprintf('%s%s',sqlite_str,  value_insert(1:end-2)));
    end
  
    save(MAT_FILE, 'P_emoji', 'P_ew_0', 'P_ew_1', 'P_table', 'data_test', 'dictionary', 'emoji_dic', 'EMOJI_NUM', 'TEST_NUM');
    mksqlite('close');
end


    if WEIGHTING == 1,
        [~, idx] = sort(P_emoji, 'descend');
        P_rank = P_emoji;
        for i = 1:EMOJI_PER_PAGE:length(P_emoji),
            window = min(i + EMOJI_PER_PAGE-1, length(P_emoji));
            P_rank(idx(i:window)) = mean(P_emoji(idx(i:window)));
        end
        P_table = prod([P_ew_0 P_rank], 2);
    else
        P_table = prod([P_ew_0 P_emoji], 2);
    end







if TESTING_OR_PREDICT, 
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

else
    %% PREDICT
    while(1)
        data_input = input('Enter a sentance: ', 's');
        close all;
        [emoji_table, word_match] = naive_predict(data_input, dictionary, P_ew_1, P_ew_0, P_table, WORD_TABLE, PHRASE_TABLE);
        word_match
        display_emojis(emoji_table(1:8), emoji_dic);
    end
end