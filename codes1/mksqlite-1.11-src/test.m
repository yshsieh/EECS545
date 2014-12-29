clc
NEED_TO_RELOAD_DATA = 0

NEED_TO_SVM = 1
NEED_TO_reSVM = 1
%NEED_TO_GROUP = 0

for lll = 1:10,
    f = lll/10;
    svm_v1;
    cdfplot(results);hold on;
    outputString = sprintf('CDFplot of f = %f ', f);
    title(outputString);
end
    