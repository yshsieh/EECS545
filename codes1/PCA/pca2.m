clc
clear all;
close all;

load('inputdata');

emoj_showed = [803 576 573];

emoji_data_aggre = [];
emoji_dic = [];

for i = 1:size(emoj_showed,2),
    emoji_data = [];
    emoji_idx = find(y_train == emoj_showed(i));
    emoji_data = x_train(:,emoji_idx);
    emoji_data_aggre = [emoji_data_aggre emoji_data];
    emoji_dic = [emoji_dic repmat(emoj_showed(i),1,size(emoji_idx,2))];
end
        
[U, D] = eig(emoji_data_aggre*emoji_data_aggre');
[D_val, D_idx] = sort(diag(D),'descend');

prinComp1 = U(:,D_idx(1));
prinComp2 = U(:,D_idx(2));

inner_proX = prinComp1'*emoji_data_aggre;
inner_proY = prinComp2'*emoji_data_aggre;
emoji_points = [emoji_dic;inner_proX;inner_proY]';


show_2Demojis(emoji_points, emojis);
