clc 
clear all;
close all;
load('inputdata.mat','emojis');
load('EmojiCluster');

sort_emoji_ponts = PCA_analysis(compact_mean_vectors,emojis_dic,1);
show_2Demojis(sort_emoji_ponts, emojis);

