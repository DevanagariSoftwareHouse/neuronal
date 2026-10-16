%% Run every analysis SCRIPT and persist results plus honest execution status.
% From repository root: run('analysis/+con2phys/path/z00_run_all.m')
% Set cfg before running. No clear/clc, no source catalog writes.
battle_path=fileparts(mfilename('fullpath'));
run(fullfile(battle_path,'a00_prepare.m'));
output_dir=fullfile(repo,'analysis','results',['con2phys_battle_' datestr(now,'yyyymmdd_HHMMSS')]);
if exist(output_dir,'dir'), output_dir=tempname(fullfile(repo,'analysis','results')); end
mkdir(output_dir);
files=dir(fullfile(battle_path,'a*.m')); files(strcmp({files.name},'a00_prepare.m'))=[];
ledger=struct('script',{},'status',{},'seconds',{},'message',{},'identifier',{});
for module_index=1:numel(files)
    module_name=files(module_index).name; rng(cfg.seed+module_index,'twister');
    r=struct(); clock_start=tic; status='passed'; message=''; identifier='';
    try
        run(fullfile(battle_path,module_name));
    catch err
        identifier=err.identifier; message=err.message;
        if strcmp(identifier,'battle:skip'), status='skipped'; else, status='failed'; end
    end
    ledger(end+1)=struct('script',module_name,'status',status, ...
        'seconds',toc(clock_start),'message',message,'identifier',identifier); %#ok<SAGROW>
    provenance=struct('session',c.session,'origin_s',c.origin,'duration_s',c.T, ...
        'config',cfg,'matlab_version',version,'module_seed',cfg.seed+module_index);
    save(fullfile(output_dir,[module_name(1:end-2) '.mat']),'r','provenance','status','message','identifier','-v7.3');
    fprintf('%s: %s %s\n',module_name,status,message);
end
save(fullfile(output_dir,'ledger.mat'),'ledger','cfg');
writetable(struct2table(ledger),fullfile(output_dir,'ledger.csv'));
disp(struct2table(ledger)); fprintf('Results: %s\n',output_dir);
assert(~any(strcmp({ledger.status},'failed')),'battle:failed','Some modules failed: inspect ledger.csv.');
