%% Full-recording area rates: animal is the outer sampling unit.
% Requires records to represent DISTINCT animals; verify source_id metadata.
% Columns are numerical area codes, not guessed anatomical identities.
assert(numel(unique({records.source_id}))==numel(records),'battle:skip','Repeated source IDs: aggregate sessions by animal before inference.');
r=struct('mode','real / animal-level'); area_codes=unique(c.area);
assert(numel(area_codes)>=2,'battle:skip','Need two areas.');
A=nan(numel(records),numel(area_codes)); nested=cell(numel(records),1);
for j=1:numel(records)
    rec=records(j); fsj=double(rec.file(1).sampling_rate_hz);
    duration=double(rec.n_lfp_samples)/fsj;
    m=neuronal_memmap(rec.file(4),repo); times=double(m.Data.x(:));
    m=neuronal_memmap(rec.file(5),repo); ids=double(m.Data.x(:));
    valid=isfinite(times)&times>=0&times<duration;
    cluster_ids=double(rec.brain_areas.cluster_id(:)); areas=double(rec.brain_areas.brain_area(:));
    [known,idx]=ismember(ids(valid),cluster_ids);
    rates=accumarray(idx(known),1,[numel(cluster_ids),1])/duration;
    for k=1:numel(area_codes)
        if any(areas==area_codes(k)), A(j,k)=mean(rates(areas==area_codes(k))); end
    end
    nested{j}=rates(areas==area_codes(1));
end
clear m times ids
valid=all(isfinite(A),2); A=A(valid,:); nested=nested(valid);
assert(size(A,1)>=6,'battle:skip','Need >=6 complete independent animals.');
r.animal_ids={records(valid).id}; r.area_codes=area_codes; r.rates=A;
v=A(:,1); B=cfg.draws;
r.percentile=bootstrap_percentile(v,B,.95,cfg.seed);
r.bootstrap=bootstrap_ci(v,@mean,B,.95,'bca',cfg.seed);
r.studentized=bootstrap_t_ci(v,@mean,@(z)std(z)/sqrt(numel(z)),B,.95,cfg.seed);
r.jackknife=jackknife_estimate(v,@mean);
r.jackknife_ci=jackknife_ci(v,@mean,.95);
r.delete_animal=delete_group_jackknife(v,(1:numel(v))',@mean);
r.hierarchical=hierarchical_bootstrap_ci(nested,[],B,.95,cfg.seed);
r.subsample=subsampling_ci(v,@mean,floor(numel(v)/2),B,.95);
[r.paired_ci,r.delta]=paired_difference_ci(A(:,1),A(:,2),B,.95,'percentile',cfg.seed);
r.signflip=paired_signflip_test(A(:,1),A(:,2),B,cfg.seed);
% The callback receives the already-paired difference B-A (one argument).
r.paired=paired_permutation_test(A(:,1),A(:,2),@mean,B,'two-sided');
r.group_folds=group_cross_validation((1:numel(v))',3);
% Temporal bins need blocks, unlike independent animals above.
[r.block_ci,r.block_mean,r.block_draws]=block_bootstrap_ci(c.C,@(z)mean(z,1),10,B,.95,cfg.seed,false);
[r.simultaneous,r.critical]=simultaneous_confidence_band(r.block_mean,r.block_draws,.95);
r.stability=stability_selection(A,@(z)mean(z,1)>median(mean(z,1)),B,.7);
