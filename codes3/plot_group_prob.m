function [  ] = plot_group_prob( group_prob, y_test, eids_in_group )
% 2014/03/23: yctung: a function to plot only emoji in a group

y_test_in_group = zeros(length(y_test),1)';
for i=1:length(y_test),
    % mark any emoji in the group to 1, else to 0
    y_test_in_group(i) = sum(eids_in_group==y_test(i));
end


figure; hold on;
plot(group_prob(y_test_in_group==1),'r');
plot(group_prob(y_test_in_group==0),'b');
legend('in','out');


end

