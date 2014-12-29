
clc
clear all
close all

% Constant
EMOJI_SELEC = 100; 
PREDICT_NUM = 100;
SENTENCE_NUM = 10;
N_READ = SENTENCE_NUM*1.5;

% Output File 
COMMENT = 'PHASE'; % for output figure name
MAT_FILE = sprintf('Naive_%s.mat', COMMENT);
SQL_FILE = 'instagram.sqlite';
DATABASE_UPDATE = 0;

%% Gethering Data
fprintf('Loading Data: %s\n', MAT_FILE);
load(MAT_FILE);
%% Initial
mksqlite('open', SQL_FILE);

emoji_dic = mksqlite('SELECT * FROM emoji ORDER BY rowid');
EMOJI_NUM = size(emoji_dic, 1);

data_survey = cell(EMOJI_SELEC*N_READ, 1);
id_survey = zeros(EMOJI_SELEC*N_READ, 2);
predict_sruvey = zeros(EMOJI_SELEC*N_READ, PREDICT_NUM);
% a. find out the msost used 100 emoji
emojis = mksqlite('SELECT * FROM emoji order by rowid'); % rowid is eid
emojis_count = mksqlite('select count(*) as c, emoji.rowid from emoji left join emoji_text_mapping on emoji.rowid = emoji_text_mapping.eid group by emoji.rowid order by emoji.rowid'); % rowid is eid
emojis_count = [emojis_count.c];

% select emojis
[value_sort, idx_sort] = sort(emojis_count,'descend');
eids_selected = idx_sort(1:EMOJI_SELEC);



assert(value_sort(EMOJI_SELEC) >= N_READ, sprintf('ERROR: trace of last selected emoji is not enough\n%d < %d', value_sort(EMOJI_SELEC), N_READ));
assert(TEST_NUM>EMOJI_SELEC, ('TEST_NUM must larger than EMOJI_SELEC'));
survey_idx = 1;
for eids_selected_idx = 1:EMOJI_SELEC,
    eid_selected = eids_selected(eids_selected_idx);

    fprintf('Read select_idx = %d, eid = %d\n',eids_selected_idx,eid_selected);

    data_emoji = mksqlite(sprintf('SELECT * FROM emoji_text_mapping where eid = %d order by random() limit %d', eid_selected, N_READ*20));

    use_idx = 1;
    for data_idx = 1:N_READ*20,
        
        % fetch emoji idex (label)
        mid = data_emoji(data_idx).mid;
        eid = data_emoji(data_idx).eid; % select which row(belongs to which emoji)
        text = data_emoji(data_idx).text; % get a string input
        if ~isempty(text); % this is a valid text! -> add to our table
            % b. update x
            tokens = unique(strsplit(strtrim(text))); % get a word form string
            check_word_exists = 0;
            for k = 1:size(tokens,2),
                word_idx = find(ismember(dictionary, word_hash(tokens{k}))); % token is in dictionary or not
                if(~isempty(word_idx)) % exist in our word dictionary
                    check_word_exists = 1;
                    break;
                end
            end
            if size(tokens, 2)>4,
                id_survey(survey_idx, 1) = mid;
                id_survey(survey_idx, 2) = eid;
                data_survey(survey_idx, 1) = cellstr(text);
                use_idx = use_idx+1;
                survey_idx = survey_idx +1;
            end
            if use_idx > N_READ,
                use_idx
                break;
            end
        end
    end
end

%% Text File
FILE_NAME = 'survey_data';
SURVEY_FILE = sprintf('%s_sentence.txt', FILE_NAME);
fid = fopen(SURVEY_FILE, 'w');
if fid~=-1,
    for i = 1:EMOJI_SELEC*N_READ,
        fprintf(fid, '%d|%d|%s\r\n', id_survey(i, 1), id_survey(i, 2), cell2mat(data_survey(i)));
    end
end
