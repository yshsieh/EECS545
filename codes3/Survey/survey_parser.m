%==========================================================================
% 2014/04/21: file to plot survey data
%==========================================================================

IDX_Q_CNT       = 1;
IDX_ALGO_IDX    = 2;
IDX_Q_IDX       = 3;
IDX_EID_SELECT  = 4;
IDX_EID_IDX     = 5;
IDX_PAGE_CNT    = 6;
IDX_RATING      = 7;
IDX_TIME        = 8; % ms
IDX_SIZE        = 8; % total size of all index

ALGO_RANDOM = 0;
ALGO_NAIVE = 1;
ALGO_GROUPS = 2; 

QUESTION_SIZE = 30;
QUESTION_IGNORE_PER_ALGO = 1;
QUESTION_IGNORE = QUESTION_IGNORE_PER_ALGO*3;
QUESTION_SIZE_PER_ALGO = QUESTION_SIZE/3 - QUESTION_IGNORE_PER_ALGO;

USER_MAX = 1000;

%BASE_FOLDER = 'result_14_04_22_4';
BASE_FOLDER = 'result_twoday_all';

files = dir(BASE_FOLDER);

user_cnt = 1;

trace_full = zeros(QUESTION_SIZE,IDX_SIZE, USER_MAX);

for file_idx=1:length(files),    
    if (files(file_idx).isdir), continue; end
    if (files(file_idx).name()=='.'), continue; end
    
    if (size(strfind(files(file_idx).name(),'survey_'))==0), continue; end
    
    files(file_idx);
    
    file_path = [BASE_FOLDER, '/', files(file_idx).name];
    
    fin = fopen(file_path);
    
    
    trace_now = zeros(QUESTION_SIZE, IDX_SIZE);
    
    q_cnt = 1;
    tline = fgetl(fin);
    while ischar(tline)
        parts = strsplit(tline,' ');
        data_now = cellfun(@str2num,parts,'UniformOutput',0);
        data_now = cell2mat(data_now);
        
        trace_now(q_cnt, :) = data_now;
        
        tline = fgetl(fin);
        q_cnt = q_cnt+1;
    end

    
    if q_cnt > QUESTION_SIZE, % only take data when 30 questions are answered
        %fprintf('This is the right trace (%d)\n', user_cnt);
        
        trace_full(:,:,user_cnt) = trace_now;
        
        user_cnt = user_cnt + 1;
    end
end


% process the data set 
USER_CNT = user_cnt - 1; % last one is useless
trace_full = trace_full(:,:,1:USER_CNT);

algo_group_trace = zeros(QUESTION_SIZE_PER_ALGO*USER_CNT, IDX_SIZE );
algo_random_trace = zeros(QUESTION_SIZE_PER_ALGO*USER_CNT, IDX_SIZE );
algo_naive_trace = zeros(QUESTION_SIZE_PER_ALGO*USER_CNT, IDX_SIZE );
fprintf('total %d valid trace\n', USER_CNT);


trace_idx = 1;
for user_idx = 1:USER_CNT,
    trace_now = trace_full(:,:,user_idx);
    trace_now = trace_now(QUESTION_IGNORE+1:end, :);
    
    algo_group_trace(trace_idx:trace_idx+QUESTION_SIZE_PER_ALGO-1, :) = trace_now(trace_now(:,IDX_ALGO_IDX)==ALGO_GROUPS,:);
    algo_random_trace(trace_idx:trace_idx+QUESTION_SIZE_PER_ALGO-1, :) = trace_now(trace_now(:,IDX_ALGO_IDX)==ALGO_RANDOM,:);
    algo_naive_trace(trace_idx:trace_idx+QUESTION_SIZE_PER_ALGO-1, :) = trace_now(trace_now(:,IDX_ALGO_IDX)==ALGO_NAIVE,:);
    
    trace_idx = trace_idx+QUESTION_SIZE_PER_ALGO;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% begin to analuze data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% plot average time
figure; hold on;
h_cdf = cdfplot(algo_group_trace(:,IDX_TIME)); set(h_cdf, 'color','k');
h_cdf = cdfplot(algo_random_trace(:,IDX_TIME)); set(h_cdf, 'color','b');
h_cdf = cdfplot(algo_naive_trace(:,IDX_TIME)); set(h_cdf, 'color','r');
legend('group','random','naive');
ylabel('cdf distribution');
xlabel('time');
fprintf('avg time = (%f, %f, %f)\n',mean(algo_group_trace(:,IDX_TIME)),mean(algo_random_trace(:,IDX_TIME)),mean(algo_naive_trace(:,IDX_TIME)) );
title('');

% plot average rating
figure; hold on;
h_cdf = cdfplot(algo_group_trace(:,IDX_RATING)); set(h_cdf, 'color','k');
h_cdf = cdfplot(algo_random_trace(:,IDX_RATING)); set(h_cdf, 'color','b');
h_cdf = cdfplot(algo_naive_trace(:,IDX_RATING)); set(h_cdf, 'color','r');
legend('group','random','naive');
ylabel('cdf distribution');
xlabel('rating');
fprintf('avg rating = (%f, %f, %f)\n',mean(algo_group_trace(:,IDX_RATING)),mean(algo_random_trace(:,IDX_RATING)),mean(algo_naive_trace(:,IDX_RATING)) );
title('');

% plot average time
figure; hold on;
h_cdf = cdfplot(algo_group_trace(:,IDX_EID_IDX)); set(h_cdf, 'color','k');
h_cdf = cdfplot(algo_random_trace(:,IDX_EID_IDX)); set(h_cdf, 'color','b');
h_cdf = cdfplot(algo_naive_trace(:,IDX_EID_IDX)); set(h_cdf, 'color','r');
legend('group','random','naive');
ylabel('cdf distribution');
xlabel('rank');
fprintf('avg rank = (%f, %f, %f)\n',mean(algo_group_trace(:,IDX_EID_IDX)),mean(algo_random_trace(:,IDX_EID_IDX)),mean(algo_naive_trace(:,IDX_EID_IDX)) );
title('');

% plot average page
figure; hold on;
h_cdf = cdfplot(algo_group_trace(:,IDX_PAGE_CNT)); set(h_cdf, 'color','k');
h_cdf = cdfplot(algo_random_trace(:,IDX_PAGE_CNT)); set(h_cdf, 'color','b');
h_cdf = cdfplot(algo_naive_trace(:,IDX_PAGE_CNT)); set(h_cdf, 'color','r');
legend('group','random','naive');
ylabel('cdf distribution');
xlabel('page');
fprintf('avg page = (%f, %f, %f)\n',mean(algo_group_trace(:,IDX_PAGE_CNT)),mean(algo_random_trace(:,IDX_PAGE_CNT)),mean(algo_naive_trace(:,IDX_PAGE_CNT)) );
title('');


figure; hold on;
plot_config;
plot(histc(algo_random_trace(:,IDX_EID_IDX),1:100)'.*100/(USER_CNT*QUESTION_SIZE_PER_ALGO),'b--','linewidth',LINE_WIDTH);
plot(histc(algo_group_trace(:,IDX_EID_IDX),1:100)'.*100/(USER_CNT*QUESTION_SIZE_PER_ALGO),'r','linewidth',LINE_WIDTH);
xlabel('Position of presented emojis');
ylabel('User selection probability (%)');
legend('Random order', 'Emoji prediction');
saveas(gcf, 'survey_time.pdf');