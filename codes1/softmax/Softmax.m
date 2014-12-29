clear all;
load softmax_pre;
[d,data_size] = size(training_data);
d= floor(d /100);
class_num = floor(class_num/100);

train_size = 3000;
test_size = data_size - train_size;

x_train = training_data(1:d,1:train_size);
y_train = label_matrix(1:class_num,1:train_size);
x_test = training_data(1:d,train_size+1:data_size);
y_test = label_matrix(1:class_num,train_size+1:data_size);

w = zeros(d*class_num,1);
H = zeros(d*class_num);
dE = zeros(d*class_num,1);
w_new = zeros(d*class_num,1);
tolerance = 0.2;
diff = realmax;
iter = 10;
cnt = 0;
for i = 1:iter-1,
%while diff > tolerance,
    w = w_new;
    for j = 1:class_num,
       for k = 1:class_num,
           cnt = cnt + 1
           block_H = zeros(d);
           block_dE = zeros(d,1);
           for n = 1:train_size,
               sum = 0;
               for jj = 1:class_num,
                   sum = sum + exp(w(d*(jj-1)+1:d*jj,1)'*x_train(1:d,n));
               end
               I = eye(class_num);
               block_H = block_H + exp(w(d*(k-1)+1:d*k,1)'*x_train(1:d,n))/sum*(I(k,j) - exp(w(d*(j-1)+1:d*j,1)'*x_train(1:d,n))/sum )*x_train(1:d,n)*x_train(1:d,n)';
               block_dE = block_dE + ((exp(w(d*(j-1)+1:d*j,1)'*x_train(1:d,n))/sum) - y_train(j,n))*x_train(1:d,n);
           end
           H(d*(k-1)+1:d*k,d*(j-1)+1:d*j) = block_H;
       end
       dE(d*(j-1)+1:d*j,1) = block_dE;
    end
    w_new = w - pinv(H)*dE;
    diff = norm(w - w_new);
end
save('softmax.mat');

