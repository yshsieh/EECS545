clc
close all 
clear all

num_word = 1000;
num_emoji = 100;

%get data from database
mksqlite('open', '/Users/sammui/Documents/MATLAB/EECS545_Final_Project/mksqlite-1.11-src/instagram_sentence_big.sqlite');
total_emoji = size(mksqlite('SELECT COUNT(*) FROM EMOJI'),1);
emoji_dic = mksqlite(['SELECT eid FROM emoji_text_mapping GROUP BY eid ORDER BY count(eid) DESC LIMIT ' num2str(num_emoji)]);
emojis_dic = zeros(size(emoji_dic,1),1);
for i = 1:size(emoji_dic,1),
    emojis_dic(i) = emoji_dic(i).eid;
end
data = mksqlite(['SELECT * FROM emoji_text_mapping WHERE eid IN (SELECT eid FROM emoji_text_mapping GROUP BY eid ORDER BY count(eid) DESC LIMIT ' num2str(num_emoji) ')']);
word_collect = mksqlite('SELECT word FROM word ORDER BY wid');
dictionary = {word_collect(1:num_word).word};

%get training/testing data
train_num = size(data,1);
test_num = size(data,1) - train_num;

data_train = data(1:train_num, 1);
data_test = data((train_num+1):(train_num + test_num), 1);

small_portion = 0;
training_feature_vector = zeros(num_word,train_num) + small_portion;
training_target_vector = zeros(total_emoji,train_num);
testing_feature_vector = zeros(num_word,test_num) + small_portion;
testing_target_vector = zeros(total_emoji,test_num);

%construct training/traget vectors
for i = 1:train_num,
    eid_idx = data_train(i).eid; % select which row(belongs to which emoji)
    training_target_vector(eid_idx,i) = 1;
    train_text = data_train(i).text; % get a string input
    if ~isempty(train_text);
        tokens = unique(strsplit(train_text)); % get a word form string
        for k = 1:size(tokens,2),
            Xj_idx = find(ismember(dictionary, tokens{k})); % token is in dictionary or not
            if(~isempty(Xj_idx)) % exist
                %training_feature_vector(Xj_idx,i) = training_feature_vector(Xj_idx,i)+1;
                training_feature_vector(Xj_idx,i) = 1;
            end
        end
    end
    %if (sum(training_feature_vector(:,i)) ~= 0),
    %    training_feature_vector(:,i) = training_feature_vector(:,i)/sum(training_feature_vector(:,i));
    %end
end

%construct testing/traget vectors
for i = 1:test_num,
    eid_idx = data_test(i).eid; % select which row(belongs to which emoji)
    testing_target_vector(eid_idx,i) = 1;
    test_text = data_test(i).text; % get a string input
    if ~isempty(test_text);
        tokens = unique(strsplit(test_text)); % get a word form string
        for k = 1:size(tokens,2),                
            Xj_idx = find(ismember(dictionary, tokens{k})); % token is in dictionary or not
            if(~isempty(Xj_idx)) % exist
                testing_feature_vector(Xj_idx,i) = 1;
            end
        end
    end
end

save('init_data','training_feature_vector','training_target_vector','testing_feature_vector','testing_target_vector','train_num','dictionary','emojis_dic','-v7.3');
mksqlite('close');


