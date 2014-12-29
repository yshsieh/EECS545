%1. load database
%2. run dictionary_make.m
%3. run cluster.m
%=========================
%This file will create query of specific emoji class
%=========================
clear;
nn = 7; %class
t = unique_y(find(cluster_idx ==nn));
query = 'select eid,emoji from emoji_text_mapping where ';

for i = 1:size(t,1),
    query = [query 'eid = ' num2str(t(i,1)) ' '];
    if i ~=size(t,1),
       query = [query 'or '];
    end
end

query = [query 'group by eid'];
query