# CON2PHYS exploratory scripts

Run `analysis/a00_startup.m` to configure portable repository paths. Dataset ingestion is an explicit operation in `digest/ingest_con2phys.m`; repository startup only configures paths.

The Q01--Q15 scripts are preserved research drafts, not validated pipeline entry points. They expect the older in-memory `data` schema, not a catalog record. Q01 contains unfinished catalog migration; `summarize_questionnaire`, `waveform_class`, and `trial_times` are absent, and Q13 references `participation` instead of the available `participation_ratio`. Package-local script invocation also needs adaptation. Do not use their outputs as scientific results until these dependencies, metadata mappings, and end-to-end dataset tests are completed.

The generic event and storage primitives are tested separately by the MATLAB scientific suite. Real-animal ingestion and questionnaire analyses are not covered by that synthetic suite.
