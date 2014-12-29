clear all
close all
COMMENT = 'PHASE'; % for output figure name
%MAT_FILE = sprintf('Naive_%s.mat', COMMENT);
MAT_FILE = 'naive_normalized_result.mat';
SQL_FILE = 'instagram_app.sqlite';
DATABASE_UPDATE = 0;
load(MAT_FILE);
SQL_FILE = 'instagram_app.sqlite';
mksqlite('open', SQL_FILE);

mksqlite('DROP TABLE IF EXISTS naive');
mksqlite('CREATE  TABLE naive ("eid" INTEGER, "wid" INTEGER, "p" DOUBLE)');
mksqlite('DROP TABLE IF EXISTS emoji_prob');
mksqlite('CREATE  TABLE emoji_prob ("eid" INTEGER, "p" DOUBLE)');
mksqlite('DROP TABLE IF EXISTS word');
mksqlite('CREATE  TABLE word ("wid" INTEGER, "word" TEXT)');


sqlite_str = 'INSERT INTO naive (eid, wid, p) VALUES ';
value_insert = '';
[i_nz, j_nz] = find(P_ew_1~=0);
for i = 1:size(i_nz, 1) % need further simplified??
    value_insert = sprintf('%s%s', value_insert,  sprintf('(%d, %d, %f), ',i_nz(i), j_nz(i), P_ew_1(i_nz(i), j_nz(i)))); 
    if mod(i, 500)==0
        fprintf('Database Updating(naive): %d%% (%d/%d)\n', int8(100*i/length(i_nz)), i, length(i_nz));
        mksqlite(sprintf('%s%s',sqlite_str,  value_insert(1:end-2)));
        sqlite_str = 'INSERT INTO naive (eid, wid, p) VALUES ';
        value_insert = '';
    end
end
if ~isempty(value_insert), 
    mksqlite(sprintf('%s%s',sqlite_str,  value_insert(1:end-2))); 
    fprintf('Database Updating(naive): Done\n');
end

sqlite_str = 'INSERT INTO emoji_prob (eid, p) VALUES';
value_insert = '';
for i = 1:EMOJI_NUM
    value_insert = sprintf('%s%s', value_insert , sprintf('(%d, %f), ',i,  P_emoji(i)));
    if mod(i, 500)==0
        fprintf('Database Updating(emoji_prob): %d%% (%d/%d)\n', int8(100*i/EMOJI_NUM), i, EMOJI_NUM);
        mksqlite(sprintf('%s%s',sqlite_str,  value_insert(1:end-2)));
        sqlite_str = 'INSERT INTO emoji_prob (eid, p) VALUES';
        value_insert = ''; 
    end
end
if ~isempty(value_insert), 
    mksqlite(sprintf('%s%s',sqlite_str,  value_insert(1:end-2))); 
    fprintf('Database Updating(emoji_prob): Done\n');
end

sqlite_str = 'INSERT INTO word (wid, word) VALUES';
value_insert = '';
for i = 1:length(dictionary)
    value_insert = sprintf('%s%s', value_insert , sprintf('(%d, "%s"), ',i,  cell2mat(dictionary(i))));
    if mod(i, 10)==0
        fprintf('Database Updating(dictionary): %d%% (%d/%d)\n', int8(100*i/length(dictionary)), i, length(dictionary));
        mksqlite(sprintf('%s%s',sqlite_str,  value_insert(1:end-2)));
        sqlite_str = 'INSERT INTO word (wid, word) VALUES ';
        value_insert = ''; 
    end
end
if ~isempty(value_insert), 
    mksqlite(sprintf('%s%s',sqlite_str,  value_insert(1:end-2))); 
    fprintf('Database Updating(word): Done\n');
end
%mksqlite('close');