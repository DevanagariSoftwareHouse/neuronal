function [score,detail] = decode_trials(x,y,seed)
%DECODE_TRIALS Contiguous five-fold multiclass ridge decoder of trial labels.
% [SCORE, DETAIL] = DECODE_TRIALS(X, Y, SEED)
% X is trials x features; Y is a column of finite numeric class labels.
% Rows with any nonfinite feature or label are dropped first.
% Folds are five contiguous blocks in row order; z-scoring and the ridge
% one-vs-rest least-squares fit (penalty 1, intercept unpenalized) are
% learned on the training rows only. SCORE is balanced accuracy (mean
% per-class recall), NaN with < 2 classes, < 25 rows or a missing recall.
% Folds whose training rows lack two examples of every class are SKIPPED
% silently; their rows keep predicted = NaN.
% DETAIL.probability is a softmax of least-squares scores, NOT calibrated.
% SEED is recorded as metadata only: the procedure is deterministic.
% See also decoded_mi, crossvalidated_ridge_decoder, blocked_cross_validation.
    % Five contiguous held-out folds; preprocessing learned on training only.
    % Fixed ridge one-vs-rest model, no tuned hyperparameters.
%
%   SYNTAX
%     [score,detail] = decode_trials(x,y,seed)
%
%   INPUTS
%     x: Trials-by-features matrix; rows with nonfinite features/labels are removed.
%     y: Trials-by-1 numeric class labels; use a column vector.
%     seed: Required metadata value stored in detail; the fixed contiguous folds do not use it
%       for randomization.
%
%   OUTPUTS
%     score: Balanced accuracy across classes with finite predictions, or NaN when insufficient
%       data.
%     detail: Struct with observed, predicted and probability (softmax-transformed ridge
%       scores, not calibrated probabilities); on the full path also classes, fold,
%       retained_rows and seed.
%
%   EXAMPLE
%     rng(7); y = repmat([0;1],30,1); x = [y+randn(60,1),randn(60,2)];
%     [score, detail] = decode_trials(x,y,7);
%     coverage = mean(isfinite(detail.predicted));
%     % Check coverage: folds lacking training examples can remain unpredicted.
%
    keep=all(isfinite(x),2) & isfinite(y); x=x(keep,:); y=y(keep);
    classes=unique(y); n=numel(y); pred=nan(n,1); prob=nan(n,numel(classes));
    score=nan; detail=struct('observed',y,'predicted',pred,'probability',prob);
    if numel(classes)<2 || n<25 || isempty(x), return; end
    fold=min(5,ceil((1:n)'*5/n));
    for f=1:5
        test=fold==f; train=~test;
        if any(arrayfun(@(c)sum(y(train)==c)<2,classes)), continue; end
        mu=mean(x(train,:),1); sd=std(x(train,:),0,1); sd(sd==0)=1;
        a=[ones(sum(train),1) (x(train,:)-mu)./sd];
        b=[ones(sum(test),1) (x(test,:)-mu)./sd];
        target=double(y(train)==classes');
        penalty=eye(size(a,2)); penalty(1,1)=0;
        w=(a'*a+penalty)\(a'*target);
        z=b*w; z=exp(z-max(z,[],2)); z=z./sum(z,2);
        prob(test,:)=z; [~,ii]=max(z,[],2); pred(test)=classes(ii);
    end
    recalls=nan(numel(classes),1);
    for k=1:numel(classes)
        ix=y==classes(k) & isfinite(pred);
        if any(ix), recalls(k)=mean(pred(ix)==y(ix)); end
    end
    if all(isfinite(recalls)), score=mean(recalls); end
    detail=struct('observed',y,'predicted',pred,'probability',prob, ...
        'classes',classes,'fold',fold,'retained_rows',find(keep),'seed',seed);
end
