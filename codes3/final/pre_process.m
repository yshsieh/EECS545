clc
close all
clear all

%% Control Parameters 
TEST_NUM = 0;
TRAIN_NUM = 0;
NORMALIZED = 1;
% Constant
WORD_NUM = 5000;
PHRASE_NUM = 1000;
EMOJI_SELEC = 100; 
PREDICT_NUM = 100;

% Output File 
COMMENT = 'fianl'; % for output figure name
MAT_FILE = sprintf('data_%s.mat', COMMENT);
SQL_FILE = '../instagram.sqlite';

%% Data select
mksqlite('open', SQL_FILE);

word_collect = mksqlite('SELECT word FROM word_hash ORDER BY wid');  
phrase_collect = mksqlite('SELECT phrase FROM word_phrase_hash ORDER BY pid'); 
dictionary = [{word_collect(1:WORD_NUM).word}, {phrase_collect(1:PHRASE_NUM).phrase}];
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
        TRAIN_NUM = floor(0.7* value_sort(EMOJI_SELEC)*EMOJI_SELEC);
        TEST_NUM = value_sort(EMOJI_SELEC)*EMOJI_SELEC - TRAIN_NUM;
    end
    TOTAL_NUM = TRAIN_NUM + TEST_NUM;
    N_READ = floor(TOTAL_NUM/EMOJI_SELEC);

    assert(value_sort(EMOJI_SELEC) >= N_READ, sprintf('ERROR: trace of last selected emoji is not enough\n%d < %d', value_sort(EMOJI_SELEC), N_READ));
    assert(TEST_NUM>EMOJI_SELEC, ('TEST_NUM must larger than EMOJI_SELEC'));
    for eids_selected_idx = 13,
        data = [];
        eid_selected = eids_selected(eids_selected_idx);

        fprintf('Read select_idx = %d, eid = %d\n',eids_selected_idx,eid_selected);

        data_emoji = mksqlite(sprintf('SELECT * FROM emoji_text_mapping where eid = %d order by random() limit %d', eid_selected, N_READ));

        use_idx = 1;
        for data_idx = 1:N_READ,
            % fetch emoji idex (label)
            eid = data_emoji(data_idx).eid; % select which row(belongs to which emoji)
            text = data_emoji(data_idx).text % get a string input
            if ~isempty(text); % this is a valid text! -> add to our table
                % b. update x
                tokens = strsplit(text); % get a word form string
                check_word_exists = 0;
                for k = 1:size(tokens,2);
                    word_idx = find(ismember(dictionary, word_stem(tokens{k}))); % token is in dictionary or not
                    if(~isempty(word_idx)) % exist in our word dictionary
                        check_word_exists = 1;
                        break;
                    end
                end
                data = [data; data_emoji(data_idx)];
                use_idx = use_idx+1;
            end
        end
        data_train = [data_train; data(1:TRAIN_NUM/EMOJI_SELEC)];
        data_test = [data_test; data(TRAIN_NUM/EMOJI_SELEC +1 :end)];
    end
    data_all = [data_train; data_test];
else
    data_all = mksqlite('SELECT * FROM emoji_text_mapping');
    if (TEST_NUM == 0)&&(TRAIN_NUM == 0),
        TRAIN_NUM = floor(0.7* size(data_all, 1));
        TEST_NUM = size(data_all, 1) - TRAIN_NUM;
    end
    data_train = data_all(1:TRAIN_NUM, 1);
    data_test = data_all(TRAIN_NUM+1:TRAIN_NUM+TEST_NUM);
end


%% Pre-processing
TOTAL_NUM = TRAIN_NUM + TEST_NUM;
x = zeros(TOTAL_NUM, WORD_NUM + PHRASE_NUM);
y = zeros(TOTAL_NUM,1);

for i = 1:TOTAL_NUM,
    y(i) = data_all(i).eid; % select which row(belongs to which emoji)moji
    train_text = data_all(i).text; % get a string input
    if ~isempty(train_text);
        tokent_splite = strsplit(train_text);
        [~, idx] =  unique(tokent_splite);
        tokens = tokent_splite(sort(idx));

        word1_idx_now = -1;
        word2_idx_now = -1;
        first_valide_taken = -1;
        for k = 1:size(tokens,2),
            token_input = word_stem(tokens{k});
            Xj_idx = find(ismember(dictionary(1:WORD_NUM), token_input)); % token is in dictionary or not
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
                token_input = word_stem(tokens{k});
                Xj_idx = find(ismember(dictionary, token_input)); % token is in dictionary or not
                if(~isempty(Xj_idx)) % exist word 2
                    single_word = 0;

                    word2_idx_now = Xj_idx;
                    word2_now = dictionary(Xj_idx);
                    %word1_now
                    %word2_now
                    phrase_now = {[cell2mat(word1_now), cell2mat(word2_now)]};
                    %phrase_now

                    phrase_idx = find(ismember(dictionary(5001:end), phrase_now));


                    if ~isempty(phrase_idx) && phrase_idx > WORD_NUM, % find a phrase
                        x(i, phrase_idx) = 1;
                        phrase_is_hitted = 1;
                    else % don't use phrase
                        x(i, phrase_idx) = 1;
                        phrase_is_hitted = 0;
                    end
                    word1_idx_now = word2_idx_now;
                    word1_now = word2_now;
                end
            end
            if(single_word==1)
                x(i, word1_idx_now) =  1;
            end

            if(single_word==0 && phrase_is_hitted == 0),
                x(i, word2_idx_now) =  1;
            end
        end
    end
    if mod(i, 5000)==0
        fprintf('Processing: %d%% (%d/%d)\n', int8(100*i/TOTAL_NUM), i, TOTAL_NUM);
    end
end
x_train = x(1:TRAIN_NUM, :);
y_train = y(1:TRAIN_NUM, 1);
x_test = x(TRAIN_NUM+1:TOTAL_NUM, :);
y_test = y(TRAIN_NUM+1:TOTAL_NUM, 1);
