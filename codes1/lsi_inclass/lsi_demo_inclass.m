A = [0 0 0 1 0;
     0 0 0 0 1;
     0 0 0 0 1;
     1 0 1 0 0;
     1 0 0 0 0;
     0 1 0 0 0;
     1 0 1 1 0;
     0 1 1 0 0;
     0 0 1 1 1;
     0 1 1 0 0];% enter the matrix here

q =  ;% enter query vector here
 
desired_ans = % enter what should best answre be for above query

[cosine_dist] = query2cosinedist(A,q);
tol = 0.1;
rel_idxes = find(cosine_dist > tol);

tol_list = linspace(0,0.999,100);
 
[precision,recall] = precision_recall(A,q,desired_ans,tol_list);
plot(recall,precision,'red-x'), hold on
 
%%% Using SVD

[U,S,V] = svd(A); k = 2; 
[cosine_dist_svd] = query2cosinedist(S(1:k,1:k)*V(:,1:k)',U(:,1:k)'*q);
[precision,recall] = precision_recall(S(1:k,1:k)*V(:,1:k)',U(:,1:k)'*q,desired_ans,tol_list);
plot(recall,precision,'black-o')
legend('w/o SVD','w SVD'), xlabel('Recall'), ylabel('Precision')

figure; subplot(2,1,1), stem(cosine_dist), title('cosine distance w/o SVD')
subplot(2,1,2), stem(cosine_dist_svd), title('cosine distance w/ SVD')