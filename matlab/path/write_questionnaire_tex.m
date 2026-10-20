function write_questionnaire_tex(results,filename)
%WRITE_QUESTIONNAIRE_TEX Export recorded q01:q15 outputs without inventing answers.
% RESULTS.qNN: status='completed', result=qNN; or status='failed', message=... .
% Empty results render every question as not executed. NaN renders unavailable.
% Intervals retain their actual coverage and confidence/credible interpretation.
% Example: write_questionnaire_tex(struct(),'questionarie.tex').
spec=questionnaire_spec();
fid=fopen(filename,'w','n','UTF-8'); assert(fid>=0,'Cannot open report output.');
cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
put(fid,'\documentclass[11pt,a4paper]{article}');
put(fid,'\usepackage[T1]{fontenc}\usepackage[utf8]{inputenc}');
put(fid,'\usepackage[margin=22mm]{geometry}\usepackage{booktabs,tabularx}');
put(fid,'\usepackage[hidelinks]{hyperref}');
put(fid,'\setlength{\parindent}{0pt}\setlength{\parskip}{6pt}\begin{document}\raggedright');
put(fid,'\title{CON\textsuperscript{2}PHYS questionnaire: analytical answers}\author{Neuronal analysis}\date{}\maketitle');
put(fid,['This report transcribes script outputs for one recording. Missing estimates are not evidence of equality. ' ...
    'No winning area is inferred from marginal interval overlap. Population-level claims require paired animal contrasts.']);
if isfield(results,'meta')
    for key={'generated_at','matlab_version','revision','scope','source'}
        if isfield(results.meta,key{1})
            value=results.meta.(key{1});
            if (ischar(value)||isstring(value)) && ~isempty(char(value))
                put(fid,[tex(key{1}) ': \texttt{' tex(char(value)) '}\par']);
            end
        end
    end
end
for k=1:numel(spec)
    item=spec(k); put(fid,'\clearpage');
    put(fid,['\section*{' upper(item.id) '. ' tex(item.question) '}']);
    complete=isfield(results,item.id)&&strcmp(results.(item.id).status,'completed');
    if complete
        result=results.(item.id).result;
        put(fid,['\textbf{Answer.} ' tex(result.answer)]);
        put(fid,'\textbf{Execution status.} Completed; interval availability is listed below.');
    else
        put(fid,'\textbf{Answer.} Not determined: a completed analysis result is unavailable.');
        if isfield(results,item.id)
            put(fid,['\textbf{Execution failure.} ' tex(results.(item.id).message)]);
        else
            put(fid,'\textbf{Execution status.} Not executed.');
        end
    end
    put(fid,'\begin{tabularx}{\linewidth}{XrrX}\toprule Group & Estimate & Interval & Units \\\midrule');
    for g=1:3
        estimate='--'; interval='--'; label=item.labels{g}; units=item.units;
        if complete
            summary=result.summary; label=summary.group{g}; units=result.units;
            estimate=number(summary.mean(g));
            interval=['[' number(summary.ci_low(g)) ', ' number(summary.ci_high(g)) ']'];
        end
        put(fid,[tex(label) ' & ' estimate ' & ' interval ' & ' tex(units) ' \\']);
    end
    put(fid,'\bottomrule\end{tabularx}');
    put(fid,['\textbf{Analytical approach.} ' tex(item.method)]);
    put(fid,['\textbf{Interpretation and limitations.} ' tex(item.limitations)]);
    put(fid,['\textbf{Source.} \path{' ['analysis/+con2phys/' item.script '.m'] '}']);
    if complete
        if isfield(result,'decision')
            put(fid,['\textbf{Decision scope.} ' tex(result.decision.scope) '. ' tex(result.decision.status)]);
            for choice=1:4
                if choice<=3, label=item.labels{choice}; else, label='Not enough data / no differences'; end
                selected=(isempty(result.decision.winner)&&choice==4)||isequal(result.decision.winner,choice);
                if selected, mark='X'; else, mark='\phantom{X}'; end
                put(fid,['\fbox{' mark '} ' tex(label) '\quad']);
            end
            put(fid,'\par');
            contrasts=result.decision.contrasts;
            if ~isempty(contrasts)
                put(fid,'\begin{tabularx}{\linewidth}{Xrrr}\toprule Pair & Difference & Simultaneous interval & Holm p \\\midrule');
                for pair=1:height(contrasts)
                    put(fid,sprintf('%d vs %d & %s & [%s, %s] & %s \\\\', ...
                        contrasts.group_a(pair),contrasts.group_b(pair),number(contrasts.difference(pair)), ...
                        number(contrasts.simultaneous_low(pair)),number(contrasts.simultaneous_high(pair)), ...
                        number(contrasts.p_holm(pair))));
                end
                put(fid,'\bottomrule\end{tabularx}');
                put(fid,'All three pairs form the family. Intervals use Bonferroni basic bootstrap; p-values use centered bootstrap with Holm adjustment.');
            end
        end
        for g=1:numel(result.inference)
            interval_info=result.inference{g};
            detail=sprintf('%s: %s; %.1f percent %s interval; axis=%s; n=%d; status=%s; scope=%s.', ...
                item.labels{g},interval_info.method,100*interval_info.level,interval_info.interval_kind,interval_info.axis,interval_info.n,interval_info.status,interval_info.scope);
            if ~isempty(interval_info.block_length), detail=[detail sprintf(' Block length=%g input rows.',interval_info.block_length)]; end %#ok<AGROW>
            put(fid,[tex(detail) '\par']);
        end
        put(fid,['Configuration: B=' num2str(result.config.bootstrap) ', seed=' num2str(result.config.seed) '.']);
        if isfield(result,'provenance')
            prov=result.provenance;
            if isfield(prov,'duration_seconds')
                put(fid,sprintf('Recording duration: %.6g s. LFP sampling rate: %.6g Hz.',prov.duration_seconds,prov.lfp_srate));
            end
        end
        if isfield(result,'limitations'), put(fid,tex(result.limitations)); end
    end
end
put(fid,'\clearpage\section*{Section 2: participant meta-information}');
put(fid,['For each question, confidence in the answer, prior experience, and expected consensus ' ...
    'must be rated by the participant on the original 1--10 scales. These personal ratings are left unfilled.']);
put(fid,'\end{document}');
end
function put(fid,s)
fprintf(fid,'%s\n',s);
end
function s=number(x)
if isnan(x), s='--'; elseif isinf(x)
    if x>0, s='$\infty$'; else, s='$-\infty$'; end
else, s=sprintf('%.6g',x); end
end
function out=tex(s)
% Escape character-by-character so inserted LaTeX commands are not reescaped.
s=char(s); out='';
for k=1:numel(s)
    switch s(k)
        case '\', token='\textbackslash{}';
        case {'&','%','$','#','_','{','}'}, token=['\' s(k)];
        case '~', token='\textasciitilde{}';
        case '^', token='\textasciicircum{}';
        case '<', token='\textless{}';
        case '>', token='\textgreater{}';
        otherwise, token=s(k);
    end
    out=[out token]; %#ok<AGROW>
end
end
