%1. load database
%2. run init_data.m
%===========================
%This file will cluster emojis based on their dictionary feature vector and
%store 'cluster_idx'
%===========================
clear all;
close all;
load inputdata;

emoji_showed = [803 576 573];
emoji_num = size(emoji_showed,2);
top_k_word = 10;
word_ranks = cell(emoji_num);


%calculate mean vector
for eidx = 1:emoji_num,
    select_x = x_train(:,find(y_train==emoji_showed(eidx)));
    select_x_avg = sum(select_x,2)/size(select_x,2);
    [~,sidx] = sort(select_x_avg,'descend');
    word_ranks{eidx} = words(sidx(1:top_k_word));
end
