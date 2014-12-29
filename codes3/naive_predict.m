function [emoji_table, word_matched] = naive_predict(input, dictionary, P_ew_1, P_ew_0, P_table, WORD_TABLE, PHRASE_TABLE)
WORD_NUM = 5000;
input = strrep(input, ' t ', 't ');
input = strrep(input, '''', '');
input = strrep(input, ',', '');
input = strrep(input, '.', '');
input = strrep(input, '~', '');
input = strrep(input, '!', '');
input = strrep(input, '?', '');
input_splite = strsplit(input);
[~, idx] =  unique(input_splite);
tokens = input_splite(sort(idx));
match_idx  = zeros(size(dictionary));
if(PHRASE_TABLE == 1)    
    word1_idx_now = -1;
    word2_idx_now = -1;
                
    first_valide_taken = -1;
    for k = 1:size(tokens,2),
        if WORD_TABLE == 1,   token_input = word_stem(tokens{k});
        else    token_input = tokens{k}; end
    
        Xj_idx = find(ismember(dictionary, token_input)); % token is in dictionary or not
        if(~isempty(Xj_idx)) % exist
            first_valide_taken = k;
            word1_idx_now = Xj_idx;
            word1_now = dictionary(Xj_idx);
            break;
        end
    end
    if first_valide_taken >=0,          
        phrase_is_hitted = 0;
        single_word = 1;
        for k = first_valide_taken+1:size(tokens,2),
            if WORD_TABLE == 1,   token_input = word_stem(tokens{k});
            else    token_input = tokens{k}; end

            Xj_idx = find(ismember(dictionary, token_input)); % token is in dictionary or not
            if(~isempty(Xj_idx)) % exist word 2
                single_word = 0;

                word2_idx_now = Xj_idx;
                word2_now = dictionary(Xj_idx);

                phrase_now = {[cell2mat(word1_now), cell2mat(word2_now)]};

                phrase_idx = find(ismember(dictionary(WORD_NUM+1:end), phrase_now));


                if ~isempty(phrase_idx), % find a phrase
                    match_idx(phrase_idx) = 1;
                    phrase_is_hitted = 1;
                else % don't use phrase
                    match_idx(word1_idx_now) = 1;
                    phrase_is_hitted = 0;
                end

                word1_idx_now = word2_idx_now;
                word1_now = word2_now;
            end
        end
        if(single_word==1)
            match_idx(word1_idx_now) = 1;
        end

        if(single_word==0 && phrase_is_hitted == 0),
            match_idx(word2_idx_now) = 1;
        end
    end
else
    for k = 1:size(tokens,2), %find the index of matched words
        if WORD_TABLE == 1,   token_input = word_stem(tokens{k});
        else    token_input = tokens{k}; end
        Xj_idx = find(ismember(dictionary, token_input)); % token is in dictionary or not
        if(~isempty(Xj_idx)), 
            match_idx(Xj_idx) = 1;
        end
    end
end
pro_c = P_table;
pro_c(P_table~=0) = pro_c(P_table~=0) .* prod(P_ew_1((P_table~=0), (match_idx==1)), 2);
pro_c(P_table~=0) = pro_c(P_table~=0) ./ prod(P_ew_0((P_table~=0), (match_idx==1)), 2);
word_matched =  dictionary(match_idx==1);
[~, emoji_table] = sort(pro_c,'descend');
return
