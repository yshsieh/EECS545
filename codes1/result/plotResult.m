clc
clear all;
close all;

N_SUGGEST = 100;
N_TEST = 10000;

load('NAIVEresulsFile_samll','rank_result','rank_prior_base');
load('SVMresultsFile_samll','SVMresults');
load('kNNresultsFile_samll','kNNresults');
%load('reSVMresultsFile_samll','reSVMresults');

SVMhist = 100*histc(SVMresults,1:N_SUGGEST)'/N_TEST;
NAIVEhist = 100*rank_result(2:101)/sum(rank_result);
kNNhist = 100*histc(kNNresults,1:N_SUGGEST)'/N_TEST;
RANDhist = 100*rank_prior_base(2:101)/sum(rank_prior_base);
%SVMhist = 100*histc(SVMresults,1:N_SUGGEST)'/N_TEST;
%reSVMhist = 100*histc(reSVMresults,1:N_SUGGEST)'/N_TEST;


figure;
LINE_WIDTH = 1.5;
set(0,'DefaultAxesFontSize',18,'DefaultTextFontSize',14);
%Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperPosition', [0 0 7 5]); 
%Set the paper to have width 5 and height 5.
set(gcf, 'PaperSize', [7 5]); 
N_SUGGEST = 20;
plot(1:N_SUGGEST, NAIVEhist(1:N_SUGGEST),'r-', 1:N_SUGGEST, kNNhist(1:N_SUGGEST),'b--', 1:N_SUGGEST, SVMhist(1:N_SUGGEST),'m',1:N_SUGGEST,RANDhist(1:N_SUGGEST),'k:','linewidth',LINE_WIDTH);
%plot(1:N_SUGGEST,SVMhist, 'r-', 1:N_SUGGEST, reSVMhist, 'b--');
xlabel('Prediction ranking');
ylabel('Selected probability (%)');
legend('Naive Bayes','kNN','SVM','Random');
saveas(gcf,'poster_svm_result.pdf');