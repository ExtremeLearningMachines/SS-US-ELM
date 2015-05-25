% Semi-supervised ELM (US-ELM) for semi-supervised classification.
% Ref: Huang Gao, Song Shiji, Gupta JND, Wu Cheng, Semi-supervised and
% unsupervised extreme learning machines, IEEE Transactions on Cybernetics, 2014

format compact;
clear; 

addpath(genpath('functions'))

% load data
trial=1; 
load g50c;
l=size(idxLabs,2);
u=ceil(size(y,1)*3/4)-2*l;
Xl=X(idxLabs(trial,:),:);
Yl=y(idxLabs(trial,:),:);

% Creat validation set
labels=unique(y); 
idx_V=[];
for i=1:size(labels)
    idx_V=[idx_V;find(y(idxUnls(trial,:))==labels(i),l/length(labels),'first')];
end
Xv=X(idxUnls(trial,idx_V),:);
Yv=y(idxUnls(trial,idx_V));

% Creat unlabeled and testing set
idxSet=1:size(idxUnls,2);
idx_UT=setdiff(idxSet,idx_V);
idx_rand=randperm(size(idx_UT,2));
Xu=X(idxUnls(trial,idx_UT(idx_rand(1:u))),:);
Yu=y(idxUnls(trial,idx_UT(idx_rand(1:u))),:);
Xt=X(idxUnls(trial,idx_UT(idx_rand(u+1:end))),:);
Yt=y(idxUnls(trial,idx_UT(idx_rand(u+1:end))),:);


%%%%%%%%%%%%%% train ss-elm
% Note that manifold regualarization are sensitive to the hyperparameters of graph Laplacian

% Compute graph Laplacian
options.NN=50;
options.GraphWeights='binary';
options.GraphDistanceFunction='euclidean';

options.LaplacianNormalize=1;
options.LaplacianDegree=5;
L=laplacian(options,[Xl;Xu]);

paras.NumHiddenNeuron=2000;
paras.NoDisplay=1;
paras.Kernel='sigmoid';

% model selection using the validation set
acc_v=zeros(10,10);
acc_test=zeros(10,10);
acc_max=0;
for i=1:10
    paras.C=10^(i-5);
    for j=1:10
        paras.lambda=10^(7-j);
        elmModel=sselm(Xl,Yl,Xu,L,paras);
        [acc_v(i,j),MSE(i,j),~,~]=sselm_predict(Xv,Yv,elmModel);
        [acc_test(i,j),~,~]=sselm_predict(Xt,Yt,elmModel)       
        if acc_v(i,j)>acc_max
            acc_max=acc_v(i,j);
            elmModel_best=elmModel;
        end
    end
end

[acc_tmp,~,~]=sselm_predict(Xu,Yu,elmModel_best);
err_u(trial)=100-acc_tmp
[acc_tmp,~,~]=sselm_predict(Xv,Yv,elmModel_best);
err_v(trial)=100-acc_tmp
[acc_tmp,~,~]=sselm_predict(Xt,Yt,elmModel_best);
err_t(trial)=100-acc_tmp


