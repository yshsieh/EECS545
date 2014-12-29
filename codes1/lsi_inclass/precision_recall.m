function [precision,recall] = precision_recall(A,q,desired_ans,tol_list)

precision = zeros(length(tol_list),1);
recall = precision; 

Nr = length(find(desired_ans>0));

cosine_dist = query2cosinedist(A,q);

for idx = 1 : length(tol_list),
     tol = tol_list(idx);
     rel_idxes = find(cosine_dist > tol);
     
     q_returned = zeros(size(desired_ans));
     q_returned(rel_idxes,1) = 1;
     
     Dt = length(rel_idxes);
     Dr = length(find(desired_ans.*q_returned >0));
	    
     

     % to avoid setting where Dr and Dt = 0
     % in MATLAB 0/0 = NaN and max(NaN,0) = 0
     precision(idx,1) = max(Dr/Dt,0); 
     recall(idx,1) = Dr/Nr;
end

     