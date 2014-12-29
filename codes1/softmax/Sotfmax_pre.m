clear all;
load dictionary_make;
training_data = zeros(size(dictionary,2),effective_data_cnt);
label_data = zeros(effective_data_cnt,1);
label_matrix = zeros(class_num,effective_data_cnt);
data_idx = 1;
for i = 1:size(pre_data,1),
    training_sample = zeros(size(dictionary,2),1);
    training_text = pre_data(i).text;
    if ~isempty(training_text)
        tokens = strsplit(training_text);
        for k = 1:size(tokens,2),
            if(~strcmp(tokens{k},''))
                idx = find(strcmp(dictionary, tokens{k})); 
                training_sample(idx) = 1;
            end
        end
        label_data(data_idx) = pre_label(i).eid;
        label_matrix(pre_label(i).eid,data_idx) = 1;
        training_data(:,data_idx) = training_sample;
        data_idx = data_idx+1;
    end
end
save('softmax_pre');
