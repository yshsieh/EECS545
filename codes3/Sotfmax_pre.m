clear all;
mksqlite('open','instagram.sqlite');
training_data = mksqlite('SELECT text FROM EMOJI_TEXT_MAPPING');
%N = 10000;
%dictionary = cell(1,N);
dictionary = [];
for i = 1:size(training_data,1),
    training_text = training_data(i).text;
    if ~isempty(training_text);
        tokens = strsplit(training_text);
        for k = 1:size(tokens,2),
            if(isempty(strmatch(tokens(k), dictionary)))
                dictionary = [dictionary {tokens{k}}];
            end
        end
    end
end
mksqlite('close');