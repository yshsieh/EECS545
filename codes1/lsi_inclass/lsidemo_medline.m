clear all
load Q_med.mat % query matrix
load A_med.mat % term-document matrix
load dict_med.mat % dictionary
load Rel_med.mat % relevant documents (provided by an expert)

idx = 1;  % which query - try idx = 1, 5 and 9
   
query = Q_med(:,idx);
query_ind = find(query);
query_terms = dict_med(query_ind,:)
rel_docs_idxes = Rel_med(find(Rel_med(:,1)==idx),2);
rel_docs = zeros(size(Q_med,1)); rel_docs(rel_docs_idxes) = 1;



k = 100;
[U,S,V] = svds(A_med,k); % only compute top k singular vectors

%figure; plot(svd(full(A_med)),'o')
%%% without SVD
[cosine_dist1] = query2cosinedist(A_med,query);
figure(1), clf
subplot 211, stem(cosine_dist1,'blue'), ylim([0 1]), 
title('cosine distance w/o SVD'), grid on

%%% with SVD
[cosine_dist2] = query2cosinedist(S(1:k,1:k)*V(:,1:k)',U(:,1:k)'*query);
subplot 212,stem(cosine_dist2,'red'), ylim([0 1]) , 
title('cosine distance w SVD'), grid on

figure(2), clf
tol_list = linspace(0,1,50);
[precision,recall] = precision_recall(full(A_med),query,rel_docs,tol_list);
plot(precision,recall,'-rx');, hold on
area_pre_rec_curve_nosvd = trapz(precision,recall);

[precision,recall] = precision_recall(S(1:k,1:k)*V(:,1:k)',U(:,1:k)'*query,rel_docs,tol_list);

plot(precision,recall,'-bo');
xlabel('Precision'), ylabel('Recall'), legend('no SVD',['SVD: k = ' num2str(k)]);

area_pre_rec_curve_svd = trapz(precision,recall);

[area_pre_rec_curve_nosvd area_pre_rec_curve_svd]



