new_data = zeros(d,1);
new_data(6,1) = 1;

rst = [];
for mmm = 1:class_num,
    w_new(d*(mmm-1)+1:mmm*d,1)
     rst = [rst w_new(d*(mmm-1)+1:mmm*d,1)'*new_data];
end
rst