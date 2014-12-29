%1. load database
%2. run init_data.m
%===========================
%This file will cluster emojis based on their dictionary feature vector and
%store 'cluster_idx'
%===========================
clear all;
close all;
load('inputdata.mat');


training_feature_vector = x_train;
training_target_vector = zeros(N_WORD,N_TRAIN);
for i = 1:N_TRAIN,
    training_target_vector(y_train(i),i) = 1;
end
training_target_value = y_train;
testing_feature_vector = x_test;
testing_target_vector = zeros(N_WORD,N_TRAIN);
for i = 1:N_TEST,
    testing_target_vector(y_test(i),i) = 1;
end
train_num = N_TRAIN;
dictionary = words;
emojis_dic = eids_selected;

%calculate mean vector
num_emoji = size(training_target_vector,1);
num_word = size(training_feature_vector,1);
num_data = size(training_target_vector,2);
sum_vector = zeros(num_word,num_emoji);
mean_vector = zeros(num_word,num_emoji);
cnt_vector = zeros(1,num_emoji);


for i = 1:num_data,
    eid_idx = find(training_target_vector(:,i) == 1);
    if ~isempty(eid_idx),
        sum_vector(:,eid_idx) = sum_vector(:,eid_idx) + training_feature_vector(:,i);
        cnt_vector(:,eid_idx) = cnt_vector(:,eid_idx) + 1;
    end
end

for j = 1: num_emoji,
    if (cnt_vector(:,j) ~= 0),
        mean_vector(:,j) = sum_vector(:,j)/cnt_vector(:,j);
    end
end
    
%compacting vectors 
compact_mean_vectors = zeros(num_word, size(emojis_dic,1));
compact_mean_vectors = mean_vector(:,emojis_dic');
    
%K-means algorithm
k = 8;

cluster_idx = kmeans(compact_mean_vectors',k,'distance','correlation','replicates',500);

%draw figure
%mksqlite('open', '/Users/sammui/Documents/MATLAB/EECS545_Final_Project/mksqlite-1.11-src/instagram_sentence_big.sqlite');
%emojis = mksqlite('SELECT * FROM emoji');
%save('cluster','cluster_idx','compact_mean_vectors','emojis_dic','emojis','-v7.3');
%mksqlite('close');

%draw clustering results
%=====================
top_feature_num = 10;    

word_ranks = find_word_rank(cluster_idx,emojis_dic,sum_vector,dictionary,top_feature_num);

save('EmojiCluster');

for i = 1:k,
    elist = emojis_dic(find(cluster_idx==i));
    word_ranks(:,i)    
    show_emojis(elist, emojis);
end

%sort_emoji_ponts = PCA_analysis(compact_mean_vectors,emojis_dic,1);
%show_emojis(sort_emoji_ponts(1:size(sort_emoji_ponts,1)/2,2)', emojis);
%show_emojis(sort_emoji_ponts(size(sort_emoji_ponts,1)/2+1:end,2)', emojis);
