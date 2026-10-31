function test_spike_lfp_summarize_band
%TEST_SPIKE_LFP_SUMMARIZE_BAND Synthetic PPC and missing-data contracts.
a = spike_lfp_summarize_band([0;pi/2], [1;1], [2;4], ...
    uint32([10;20]), uint32([12;25]), 2, 10);
assert(a.units_total == 2 && a.units_eligible == 2);
assert(abs(a.median_ppc-1) < 1e-12);
assert(abs(a.mean_amplitude-(10*2+20*4)/30) < 1e-12);
assert(abs(a.phase_valid_fraction-30/37) < 1e-12);
assert(abs(a.eligible_rate_hz-30/4) < 1e-12);
assert(abs(a.pooled_plv-abs((10+20i)/30)) < 1e-12);

b = spike_lfp_summarize_band([NaN;0], [NaN;1], [NaN;3], ...
    uint32([0;1]), uint32([0;1]), 1, 2);
assert(b.units_eligible == 0 && isnan(b.mean_ppc));

% Four evenly spaced phases have zero resultant and PPC=-1/(n-1).
c = spike_lfp_summarize_band(NaN,0,1,uint32(4),uint32(4),1,2);
assert(abs(c.mean_ppc+1/3) < 1e-12);
assert(c.pooled_plv == 0 && isnan(c.pooled_phase_rad));

caught = false;
try
    spike_lfp_summarize_band(0,1,1,uint32(5),uint32(4),1,2);
catch
    caught = true;
end
assert(caught,'Invalid phase_count should be rejected.');
fprintf('Spike/LFP band statistics contracts passed.\n');
end
