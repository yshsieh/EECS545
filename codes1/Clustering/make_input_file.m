clear all;
close all;

load init_data;
%training_feature_vector,
%training_target_vector,
%training_target_value,
%testing_feature_vector,
%testing_target_vector,
%train_num,
%dictionary,
%emojis_dic
load cluster;
%cluster_idx,
%compact_mean_vectors,
%emojis_dic (100),
%emojis (821)

%for emoji k, rank them and write to input data:
fid = fopen('input.txt', 'w');
[~,idx] = sort(emojis_dic,'ascend');
emojis_dic = emojis_dic(idx);
compact_mean_vectors = compact_mean_vectors(:,idx);

for k = 1:size(emojis_dic,1),
    
    data_per_emoji = training_feature_vector(:, find (training_target_value == emojis_dic(k)));
    distance_vector = zeros(1,size(data_per_emoji,2));
    
    for i = 1:size(data_per_emoji,2),
        distance_vector(i) = norm(data_per_emoji(:,i)-compact_mean_vectors(:,k));
    end
    
    [~,rank_idx] = sort(distance_vector,'ascend');
    
    for i = size(data_per_emoji,2):-1:1,
        %  3 qid:1 1:1 2:1 3:0 4:0.2 5:0 # 1A
        fprintf(fid, '%d qid:%d ',i,emojis_dic(k));
        nonZeroIdx = find(data_per_emoji(:,i) ~= 0);
        nonZeroSize = size(nonZeroIdx,1);
    
        for j = 1:nonZeroSize,
            fprintf(fid, '%d:%d ',nonZeroIdx(j),1);
        end
        
        fprintf(fid,'\n');
    end
end

fclose(fid);
