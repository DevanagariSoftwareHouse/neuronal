function score = questionnaire_balanced_accuracy(x,classes,column)
%QUESTIONNAIRE_BALANCED_ACCURACY Fixed-class mean recall, no dropped classes.
% x(:,1): observed labels; x(:,column): fixed held-out predictions.
r=nan(numel(classes),1);
for k=1:numel(classes)
    ix=x(:,1)==classes(k);
    if any(ix), r(k)=mean(x(ix,column)==classes(k)); end
end
score=mean(r); % Missing classes remain undefined; never silently change target.
end
