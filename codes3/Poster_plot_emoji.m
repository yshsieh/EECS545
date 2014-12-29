%==========================================================================
% 2014/04/26: update for plot figures at posters
% 2014/04/29: add the figure of words in dictionary
%==========================================================================
clc
close all 


addpath('./mksqlite-1.11-src');
mksqlite('open', 'instagram_hyper.sqlite');
emojis_count = mksqlite('select count(*) as c, emoji.rowid from emoji left join emoji_text_mapping on emoji.rowid = emoji_text_mapping.eid group by emoji.rowid order by emoji.rowid'); % rowid is eid
emojis_count = [emojis_count.c];

DATA_SIZE = 10000;
data = mksqlite(sprintf('SELECT text FROM emoji_text_mapping limit %d', DATA_SIZE));
x = zeros(DATA_SIZE, 1);
x_dic = zeros(DATA_SIZE, 1);


word_collect = mksqlite('SELECT word FROM word_hash ORDER BY wid'); 
dictionary = {word_collect(1:5000).word};


for i = 1:DATA_SIZE,
    text = data(i).text;
    text = strrep(text, ' t ', 't ');
    tokens = unique(strsplit(text));
    if ~isempty(text), % this is a valid text! -> add to our table
        %tokens = strsplit(text); % get a word form string
        
        check_word_exists = 0;
        for k = 1:size(tokens,2);
            word_idx = find(ismember(dictionary, word_stem(tokens{k}))); % token is in dictionary or not
            if(~isempty(word_idx)) % exist in our word dictionary
                x_dic(i) = x_dic(i)+1;
            end
        end
    end
    
    x(i) = length(tokens);
end



[emojis_count_sorted, sort_idx] = sort(emojis_count,'descend');

figure; hold on;
plot_config;
plot(emojis_count./sum(emojis_count).*100,'linewidth',LINE_WIDTH);
ylabel('Selected probability (%)');
xlabel('Emojis')
xlim([0,850]);
saveas(gcf, 'poster_emoji_distribution.pdf');



figure; hold on;
plot_config;
h_cdf = cdfplot(x); set(h_cdf, 'linewidth', LINE_WIDTH);
h_cdf = cdfplot(x_dic); set(h_cdf, 'LineStyle', '--', 'color', 'r', 'linewidth', LINE_WIDTH);
title('')
ylabel('CDF probability');
xlabel('Number of words');
xlim([0, 50]);
legend('Words','Words in our dictionary','location','southeast');
saveas(gcf, 'poster_word_cdf.pdf');


