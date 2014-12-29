function [sort_emoji_ponts] = PCA_analysis(compact_mean_vectors2,emojis_dic2,dictionary)
    avg_vector = sum(compact_mean_vectors2,2)/size(compact_mean_vectors2,2);
    compact_mean_vectors2 = compact_mean_vectors2 - repmat(avg_vector,1,size(compact_mean_vectors2,2));

    compact_mean_vectors = [];
    emojis_dic = [];
    
    %choose only the face emoji
    for i = 1:size(compact_mean_vectors2,2),
        %if (emojis_dic2(i) <= 618 & emojis_dic2(i) >= 563),
            compact_mean_vectors = [compact_mean_vectors compact_mean_vectors2(:,i)];
            emojis_dic = [emojis_dic emojis_dic2(i)];
        %end
    end
    
    [U D] = eig(compact_mean_vectors*compact_mean_vectors');
    [D_val, D_idx] = sort(diag(D),'descend');

    prinComp1 = U(:,D_idx(1));
    prinComp2 = U(:,D_idx(2));
    
    inner_proX = prinComp1'*compact_mean_vectors;
    inner_proY = prinComp2'*compact_mean_vectors;
    emoji_points = [emojis_dic;inner_proX;inner_proY]';
    %sort_emoji_ponts = sortrows(emoji_points,1);
    sort_emoji_ponts = emoji_points;
    [ww ii] = sort(U(:,4),'descend');
    %dictionary(ii(1:20))
    %plot(D_val);
    
    %to show 2D pictire, run:
    %show_2Demojis( sort_emoji_points, emojis );me
    
end
