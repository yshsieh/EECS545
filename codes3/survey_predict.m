
clc
clear all
close all

COMMENT = 'PHASE'; % for output figure name
MAT_FILE = sprintf('Naive_%s.mat', COMMENT);
load(MAT_FILE);
EMOJI_SELEC = 100; 
PREDICT_NUM = 100;
SENTENCE_NUM = 10;
WORD_TABLE=1;
PHRASE_TABLE=1;
%% Gethering Data
fprintf('Loading Data: %s\n', MAT_FILE);
load(MAT_FILE);
FILE_NAME = 'survey_data';
IN_FILE = sprintf('%s_sentence_reconstruct.txt', FILE_NAME);
OUT_FILE = sprintf('%s_predict_reconstruct.txt', FILE_NAME);
fin = fopen(IN_FILE);
fout = fopen(OUT_FILE, 'w');
tline = fgetl(fin);
while ischar(tline)
    tline
    data = regexp(tline, '(?<mid>\d+)\|(?<eid>\d+)\|(?<sentence>.*)\|(?<sentence_rec>.*)', 'names');
    [emoji_table, word_match] = naive_predict(data.sentence, dictionary, P_ew_1, P_ew_0, P_table, WORD_TABLE, PHRASE_TABLE);
    fprintf(fout, '%s|%s|%s|', data.mid, data.eid,data.sentence_rec);
    for i = 1:100
        if i~=100, fprintf(fout, '%d, ', emoji_table(i)); 
        else fprintf(fout, '%d\r\n', emoji_table(i)); end
    end
    tline = fgetl(fin);
end
fclose(fin);
fclose(fout);
