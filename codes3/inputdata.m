%==========================================================================
% 2013/02/20: successfully compile and add path of svm library
% 2013/03/15: train svm with multi-class problems to solve our problem
% 2013/03/29: update the word hash function
% 2013/03/29: update a new way to normized preprocessing data
%==========================================================================
clc
clear all
close all 


%--------------------------------------------------------------------------
% 1. control variables and svm setting
%--------------------------------------------------------------------------

% add path of svm libaray
%addpath(genpath('./libsvm-3.17'));
%addpath('../mksqlite-1.11-src');


NEED_TO_RELOAD_DATA = 1;
NEED_TO_PHRASE = 1;

IS_WORD_NEED_TO_BE_HASHED = 1;

IS_TRACE_NEED_TO_BE_NORMALIZED = 1; % 1 = select eqal size of trace for each emoji

fprintf('RELOAD_DATA = %i \n',NEED_TO_RELOAD_DATA);
fprintf('WORD_HASHED = %i \n',IS_WORD_NEED_TO_BE_HASHED);
fprintf('PHRASE = %i \n',NEED_TO_PHRASE);
fprintf('EMOJI_NORMALIZED = %i \n',IS_TRACE_NEED_TO_BE_NORMALIZED);

%assert(NEED_TO_RELOAD_DATA == 0 || (NEED_TO_RELOAD_DATA == 1 && NEED_TO_SVM == 1),'ERROR: must retran svm if data is reloaded\n');

N_TRAIN = 75000; %default 369500
N_TEST = 25000; %default 158500
N_TOTAL = N_TRAIN + N_TEST;
N_WORD = 4000;  % only use first popuar words, default = 5000
N_PHRASE = 800; % biword words
N_EMOJI = 100; % only use most popular emojis
N_SUGGEST = N_EMOJI; % only use first few emoji to suggests

mksqlite('open', 'instagram_hyper.sqlite');
%--------------------------------------------------------------------------
% 2. preprocessing data
% *** only reload data if NEED_TO_RELOAD_DATA = 1
% IS_TRACE_NEED_TO_BE_NORMALIZED == 1 -> data is normalized by emoji
% IS_TRACE_NEED_TO_BE_NORMALIZED == 0 -> just read the same amount of data
%--------------------------------------------------------------------------
if NEED_TO_RELOAD_DATA,
    if(IS_WORD_NEED_TO_BE_HASHED==1),
        words_read = mksqlite('SELECT word FROM word_hash ORDER BY wid');
    else
        words_read = mksqlite('SELECT word FROM word ORDER BY wid');
    end
    %addd
    if NEED_TO_PHRASE ==1, 
        phrase_read = mksqlite('SELECT phrase FROM word_phrase_hash ORDER BY pid'); 
        words = [{words_read(1:N_WORD).word}, {phrase_read(1:N_PHRASE).phrase}];
    else
        words = {words_read(1:N_WORD).word};
    end
    
    
    if IS_TRACE_NEED_TO_BE_NORMALIZED,
        %mksqlite('open', '/Users/sammui/Documents/MATLAB/EECS545_Final_Project/database/instagram_hyper.sqlite');
        % a. find out the msost used 100 emoji
        emojis = mksqlite('SELECT * FROM emoji order by rowid'); % rowid is eid
        emojis_count = mksqlite('select count(*) as c, emoji.rowid from emoji left join emoji_text_mapping on emoji.rowid = emoji_text_mapping.eid group by emoji.rowid order by emoji.rowid'); % rowid is eid
        emojis_count = [emojis_count.c];
        
        % select emojis
        [value_sort, idx_sort] = sort(emojis_count,'descend');
        eids_selected = idx_sort(1:N_EMOJI);
        %eids_selected = [300 149 608 146 576];
        %eids_selected = [608 583 604 148 149];
        
        if (N_TEST == 0)&&(N_TRAIN == 0),
            N_TRAIN = floor(0.7* value_sort(N_EMOJI))*N_EMOJI;
            N_TEST = value_sort(N_EMOJI)*N_EMOJI - N_TRAIN;
            N_TOTAL = N_TRAIN + N_TEST;
        end
        
        
        N_DATA_READ_PER_EMOJI = floor(N_TOTAL/N_EMOJI);
        N_READ = floor(N_DATA_READ_PER_EMOJI*1.3); % in case there is invlid input
        
        x_idx = 1;
        x_total = zeros(N_WORD, N_TOTAL); % allocate more space
        y_total = zeros(N_TOTAL,1);
        
        fprintf('WARN: dont consider the last emoji -> need to add the assert back in real');
        assert(value_sort(N_EMOJI) >= N_READ, sprintf('ERROR: trace of last selected emoji is not enough = %d',value_sort(N_EMOJI)));
        
        for eids_selected_idx = 1:N_EMOJI,
            eid_selected = eids_selected(eids_selected_idx)
            
            fprintf('----------- read select_idx = %d, eid = %d -------------\n',eids_selected_idx,eid_selected);
            
            data = mksqlite(sprintf('SELECT * FROM emoji_text_mapping where eid = %d order by random() limit %d', eid_selected, N_READ));
            
            use_idx = 1;
            for data_idx = 1:N_READ,
                % fetch emoji idex (label)
                eid = data(data_idx).eid; % select which row(belongs to which emoji)
                text = data(data_idx).text; % get a string input
                text = strrep(text, ' t ', 't ');
                if ~isempty(text); % this is a valid text! -> add to our table
                    % b. update x
                    
                    tokens = unique(strsplit(text)); % get a word form string
                    %addd
                    if(NEED_TO_PHRASE == 0)
                        for k = 1:size(tokens,2);
                            if IS_WORD_NEED_TO_BE_HASHED == 1,
                                word_idx = find(ismember(words, word_stem(tokens{k}))); % token is in dictionary or not
                            else
                                word_idx = find(ismember(words, tokens{k})); % token is in dictionary or not
                            end

                            if(~isempty(word_idx)) % exist in our word dictionary
                                x_total(word_idx, x_idx) = 1;
                            end
                        end
                    else
                        word1_idx_now = -1;
                        word2_idx_now = -1;
                        first_valide_taken = -1;
                        for k = 1:size(tokens,2),
                            if IS_WORD_NEED_TO_BE_HASHED == 1,
                                word_idx = find(ismember(words, word_stem(tokens{k}))); % token is in dictionary or not
                            else
                                word_idx = find(ismember(words, tokens{k})); % token is in dictionary or not
                            end
                            if(~isempty(word_idx)) % exist
                                first_valide_taken = k;
                                word1_idx_now = word_idx;
                                word1_now = words(word_idx);
                                break;
                            end
                        end
                        if  first_valide_taken >= 0,
                            phrase_is_hitted = 0;
                            single_word = 1;
                            for k = first_valide_taken+1:size(tokens,2),
                                if IS_WORD_NEED_TO_BE_HASHED == 1,
                                    word_idx = find(ismember(words, word_stem(tokens{k}))); % token is in dictionary or not
                                else
                                    word_idx = find(ismember(words, tokens{k})); % token is in dictionary or not
                                end
                                if(~isempty(word_idx)) % exist word 2
                                    single_word = 0;

                                    word2_idx_now = word_idx;
                                    word2_now = words(word_idx);
                                    %word1_now
                                    %word2_now
                                    phrase_now = {[cell2mat(word1_now), cell2mat(word2_now)]};
                                    %phrase_now

                                    phrase_idx = find(ismember(words(N_WORD+1:end), phrase_now));


                                    if ~isempty(phrase_idx) && phrase_idx > N_WORD, % find a phrase
                                        x_total(phrase_idx, x_idx) = 1;
                                        phrase_is_hitted = 1;
                                    else % don't use phrase
                                        x_total(word_idx, x_idx) = 1;
                                        phrase_is_hitted = 0;
                                    end


                                    word1_idx_now = word2_idx_now;
                                    word1_now = word2_now;
                                end
                            end
                            if(single_word==1)
                                x_total(word1_idx_now, x_idx) = 1;
                            end

                            if(single_word==0 && phrase_is_hitted == 0),
                                x_total(word2_idx_now, x_idx) = 1;
                            end
                        end
                    end 
                    % only admit this data if it contains any selected words
                    if(sum(x_total(:,x_idx))>0),
                        emojis_count(eid) = emojis_count(eid) +1;
                        y_total(x_idx) = eid;
                        x_idx = x_idx+1;
                        use_idx = use_idx+1;
                        if use_idx > N_DATA_READ_PER_EMOJI,
                            fprintf('gather enough data we need\n');
                            break;
                        end
                    end
                end
            end

            assert(use_idx>N_DATA_READ_PER_EMOJI,'ERROR: Size of read data is not big enought\n');

            % release memory of data (no longer used!)            
            clear data;
        end
                    

        assert(x_idx > N_TOTAL);
        
        % need to shuffle before assign data
        p = randperm(N_TOTAL);
        x_total = x_total(:,p);
        y_total = y_total(p);
        
        % partition to two data set
        x_train = x_total(:,1:N_TRAIN);
        y_train = y_total(1:N_TRAIN);

        x_test = x_total(:,N_TRAIN+1:end);
        y_test = y_total(N_TRAIN+1:end);
    end
    %{
    else
        % control of data loaded
        N_READ = (N_TRAIN+N_TEST)*2; % read more data in case some data is not valid



        % read data from sql
        mksqlite('open', 'instagram_sentence_big.sqlite');


        data = mksqlite(sprintf('SELECT * FROM emoji_text_mapping order by random() limit %d', N_READ));
        emojis = mksqlite('SELECT * FROM emoji order by rowid'); % rowid is eid

        words = {words_read(1:N_WORD).word};

        N_DATA_TOTAL = size(data, 1);
        N_EMOJI_TOTAL = size(emojis, 1);


        % modify it to travese all data, then divide the data into two sets
        x_total = zeros(N_WORD, N_DATA_TOTAL); % allocate more space
        y_total = zeros(N_DATA_TOTAL,1);
        emojis_count = zeros(N_EMOJI_TOTAL,1);

        x_idx = 1; % x_idx is the data index after preprocessing
        for data_idx = 1:N_DATA_TOTAL,
            % fetch emoji idex (label)
            eid = data(data_idx).eid; % select which row(belongs to which emoji)
            text = data(data_idx).text; % get a string input

            if ~isempty(text); % this is a valid text! -> add to our table


                % b. update x
                tokens = unique(strsplit(text)); % get a word form string
                for k = 1:size(tokens,2);
                    if IS_WORD_NEED_TO_BE_HASHED == 1,
                        word_idx = find(ismember(words, word_hash(tokens{k}))); % token is in dictionary or not
                    else
                        word_idx = find(ismember(words, tokens{k})); % token is in dictionary or not
                    end

                    if(~isempty(word_idx)) % exist in our word dictionary
                        x_total(word_idx, x_idx) = 1;
                    end
                end

                % only admit this data if it contains any selected words
                if(sum(x_total(:,x_idx))>0),
                    emojis_count(eid) = emojis_count(eid) +1;
                    y_total(x_idx) = eid;
                    x_idx = x_idx+1;
                    if x_idx > N_TOTAL,
                        fprintf('gather enough data we need\n');
                        break;
                    end
                end
            end
            if mod(data_idx, 5000)==0
                % used to dump progress
                data_idx
            end
        end

        % update size of x,y due to invalid data
        N_TOTAL_READ = x_idx;

        assert(N_TOTAL_READ>N_TRAIN+N_TEST,'ERROR: Size of read data is not big enought\n');
        x_total = x_total(:,1:N_TOTAL);
        y_total = y_total(1:N_TOTAL);


        % partition to two data set
        x_train = x_total(:,1:N_TRAIN);
        y_train = y_total(1:N_TRAIN);

        x_test = x_total(:,N_TRAIN+1:end);
        y_test = y_total(N_TRAIN+1:end);

        % select emojis
        [value_sort, idx_sort] = sort(emojis_count,'descend');
        eids_selected = idx_sort(1:N_EMOJI);
        
        % release memory of data (no longer used!)
        clear data;
    end
    %}
end

% partition to train/test data
x_train = x_total(:,1:N_TRAIN);
y_train = y_total(1:N_TRAIN);
% ----- just for debug!!! ---------
%{
    x_test = x_total(:,1:N_TRAIN);
    y_test = y_total(1:N_TRAIN);
    N_TOTAL = N_TRAIN*2;
    N_TEST = N_TRAIN;
%}
x_test = x_total(:,N_TRAIN+1:N_TRAIN+N_TEST);
y_test = y_total(N_TRAIN+1:N_TRAIN+N_TEST);

%normalized data
for i = 1:N_TRAIN,
    x_train(:,i) = x_train(:,i)/norm(x_train(:,i));
end
for i = 1:N_TEST,
    x_test(:,i) = x_test(:,i)/norm(x_test(:,i));
end

save('inputdata_medium','-v7.3');