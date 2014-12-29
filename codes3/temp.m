FILE_NAME = 'survey_data';
IN_FILE = sprintf('%s_sentence.txt', FILE_NAME);
OUT_FILE = sprintf('%s_predict.txt', FILE_NAME);
fin = fopen(IN_FILE);
fout = fopen(OUT_FILE, 'w');
tline = fgetl(fin);
%track = {}
while ischar(tline)
    data = regexp(tline, '(?<mid>\d+)\|(?<eid>\d+)\|(?<sentence>.*)', 'names');
    data.sentence
    tline = fgetl(fin);
end
fclose(fin);
fclose(fout);
%[mid, eid, sentence]    = textscan(fin, '%d|%d|%\r\n');