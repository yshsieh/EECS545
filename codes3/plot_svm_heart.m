%==========================================================================
% 2013/02/20: successfully compile and add path of svm library
% 2013/03/15: train svm with multi-class problems to solve our problem
% 2013/03/29: update the word hash function
% 2013/03/29: update a new way to normized preprocessing data
% 2013/04/03: this is a specilzied version of svm program that plot the
% result of grouping heart emojis together
%==========================================================================
clc
close all 

%--------------------------------------------------------------------------
% 1. control variables and svm setting
%--------------------------------------------------------------------------

% add path of svm libaray
addpath(genpath('./libsvm-3.17'));
addpath('./mksqlite-1.11-src');


%NEED_TO_RELOAD_DATA = 1 % assign it to 0 for saving time
NEED_TO_RELOAD_DATA = 0

%NEED_TO_SVM = 1; % assign it to 0 for saving time
NEED_TO_SVM = 0

IS_WORD_NEED_TO_BE_HASHED = 1;

IS_TRACE_NEED_TO_BE_NORMALIZED = 1; % 1 = select eqal size of trace for each emoji


assert(NEED_TO_RELOAD_DATA == 0 || (NEED_TO_RELOAD_DATA == 1 && NEED_TO_SVM == 1),'ERROR: must retran svm if data is reloaded\n');

N_TRAIN = 20000;
N_TEST = 10000;
N_TOTAL = N_TRAIN + N_TEST;
N_WORD = 5000;  % only use first popuar words
N_EMOJI = 100; % only use most popular emojis
N_SUGGEST = 20; % only use first few emoji to suggests

%--------------------------------------------------------------------------
% 2. preprocessing data
% *** only reload data if NEED_TO_RELOAD_DATA = 1
% IS_TRACE_NEED_TO_BE_NORMALIZED == 1 -> data is normalized by emoji
% IS_TRACE_NEED_TO_BE_NORMALIZED == 0 -> just read the same amount of data
%--------------------------------------------------------------------------
if NEED_TO_RELOAD_DATA,
    mksqlite('open', 'instagram_sentence_big.sqlite');
    if(IS_WORD_NEED_TO_BE_HASHED==1),
        words_read = mksqlite('SELECT word FROM word_hash ORDER BY wid');
    else
        words_read = mksqlite('SELECT word FROM word ORDER BY wid');
    end
    words = {words_read(1:N_WORD).word};
    
    if IS_TRACE_NEED_TO_BE_NORMALIZED,
        
        % a. find out the msost used 100 emoji
        emojis = mksqlite('SELECT * FROM emoji order by rowid'); % rowid is eid
        emojis_count = mksqlite('select count(*) as c, emoji.rowid from emoji left join emoji_text_mapping on emoji.rowid = emoji_text_mapping.eid group by emoji.rowid order by emoji.rowid'); % rowid is eid
        emojis_count = [emojis_count.c];
        
        % select emojis
        [value_sort, idx_sort] = sort(emojis_count,'descend');
        eids_selected = idx_sort(1:N_EMOJI);
        
        
        N_DATA_READ_PER_EMOJI = floor(N_TOTAL/N_EMOJI);
        N_READ = floor(N_DATA_READ_PER_EMOJI*1.3); % in case there is invlid input
        
        x_idx = 1;
        x_total = zeros(N_WORD, N_TOTAL); % allocate more space
        y_total = zeros(N_TOTAL);
        
        fprintf('WARN: dont consider the last emoji -> need to add the assert back in real');
        assert(value_sort(N_EMOJI) > N_READ, sprintf('ERROR: trace of last selected emoji is not enough = %d',value_sort(N_EMOJI)));
        
        for eids_selected_idx = 1:N_EMOJI,
            eid_selected = eids_selected(eids_selected_idx)
            
            fprintf('----------- read select_idx = %d, eid = %d -------------\n',eids_selected_idx,eid_selected);
            
            data = mksqlite(sprintf('SELECT * FROM emoji_text_mapping where eid = %d order by random() limit %d', eid_selected, N_READ));
            
            use_idx = 1;
            for data_idx = 1:N_READ,
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
        y_total = zeros(N_DATA_TOTAL);
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
end


%--------------------------------------------------------------------------
% 3. begin to make svm model
% *** only retrian SVM if NEED_TO_SVM == 1 ***
%--------------------------------------------------------------------------
%love_eids = [576, 370, 803, 372];  % heart
all_hearts_eids = [369:1:380, 803];  % heart
love_eids = all_hearts_eids(ismember(all_hearts_eids,eids_selected));

N_LOVE_EMOJI = length(love_eids);


if NEED_TO_SVM==1,
    % partition to train/test data
    x_train = x_total(:,1:N_TRAIN);
    y_train = y_total(1:N_TRAIN);
    % ----- just for debug!!! ---------
    
    x_test = x_total(:,1:N_TRAIN);
    y_test = y_total(1:N_TRAIN);
    N_TOTAL = N_TRAIN*2;
    N_TEST = N_TRAIN;
    %{
    x_test = x_total(:,N_TRAIN+1:N_TRAIN+N_TEST);
    y_test = y_total(N_TRAIN+1:N_TRAIN+N_TEST);
    %}
    
    
    % get the traiing model form svm
    love_models = cell(N_LOVE_EMOJI,1);
    for model_idx = 1:N_LOVE_EMOJI,
        fprintf('---------- svm train of love_model = %d ----------\n',model_idx);
        eid = love_eids(model_idx);
        %models{model_idx} = svmtrain(double(y_train==eid)', x_train','-t 2 -c 1 -g 1 -h 0 -b 1');
        love_models{model_idx} = svmtrain(double(y_train==eid)', x_train','-t 2 -c 1 -h 0 -b 1');
    end
    
    
    % predict based on svm
    probs = zeros(N_LOVE_EMOJI, N_TEST);
    neg_probs = zeros(N_LOVE_EMOJI, N_TEST);
    for model_idx = 1:N_LOVE_EMOJI,
        fprintf('---------- svm predict of love_model = %d ----------\n',model_idx);
        model = love_models{model_idx};
        [result, acc, prob]  = svmpredict(double(y_test==eid)',x_test',model,'-b 1');
        probs(model_idx,:) = prob(:,model.Label==1);
        neg_probs(model_idx,:) = prob(:,model.Label==0);
    end
    
    

    
    eids_groups{1} = love_eids;
    
    N_GROUP = length(eids_groups);
    
    % get the traiing model form svm
    group_models = cell(N_GROUP,1);
    for group_idx = 1:N_GROUP,
        fprintf('---------- svm train of group model = %d ----------\n',group_idx);
        eids_in_group = eids_groups{group_idx};
        
        y_train_in_group = zeros(N_TRAIN,1)';
        for i=1:N_TRAIN,
            % mark any emoji in the group to 1, else to 0
            y_train_in_group(i) = sum(eids_in_group==y_train(i));
        end
        group_models{group_idx} = svmtrain(double(y_train_in_group)', x_train','-t 2 -c 1 -h 0 -b 1');
    end
    
    % predict based on svm
    group_probs = zeros(N_GROUP, N_TEST);
    for group_idx = 1:N_GROUP,
        fprintf('---------- svm predict of group model = %d ----------\n',group_idx);
        eids_in_group = eids_groups{group_idx};
        
        y_test_in_group = zeros(N_TEST,1)';
        for i=1:N_TEST,
            % mark any emoji in the group to 1, else to 0
            y_test_in_group(i) = sum(eids_in_group==y_test(i));
        end
        
        model = group_models{group_idx};
        [result, acc, prob]  = svmpredict(double(y_test_in_group)',x_test',model,'-b 1');
        group_probs(group_idx,:) = prob(:,model.Label==1);
    end 
end



%--------------------------------------------------------------------------
% 4. begin to evaluate results
%--------------------------------------------------------------------------
figure; hold on;
plot_probs = [probs; group_probs]; % concate the last one
plot_probs(:,y_test_in_group==1); % only select the one assciate in the group


plot(mean(plot_probs,2),'-bo');
%plot(prctile(plot_probs,99,2),'-ro');

ylabel('Average probability estimate');


for i = 1:N_LOVE_EMOJI,
    label_to_show{i} = sprintf('%d',love_eids(i));
end

label_to_show{N_LOVE_EMOJI+1} = 'group';
xlim([0,N_LOVE_EMOJI+1+1]);


set(gca,'XTick',1:(N_LOVE_EMOJI+1))
%set(gca,'XTickLabel',{'-pi','-pi/2','0','pi/2','pi'})
set(gca,'XTickLabel',label_to_show)

xlabel('Eids of hearts emojis');











%{
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

