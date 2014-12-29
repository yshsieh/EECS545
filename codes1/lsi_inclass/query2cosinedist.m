function [cosine_dist] = query2cosinedist(A,q,tol)

n = size(A,2); % number of columns in A
cosine_dist = zeros(n,1);
for idx = 1 : n,
    cosine_dist(idx,1) = q'*A(:,idx)/(norm(q,2)*norm(A(:,idx)));
end

    