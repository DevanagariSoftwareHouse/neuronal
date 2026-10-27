# Third-party MATLAB code

`eegfilt.m` was formerly in `matlab/path`. Its embedded copyright notice identifies Scott Makeig, Arnaud Delorme and Clemens Brunner (SCCN/INC/UCSD, 1997) and expressly grants redistribution under **GPL version 2 or any later version**; the file therefore is **not MIT-licensed** under the root repository `LICENSE`.

The code was moved unchanged to `matlab/third_party/eegfilt.m` to avoid making it part of the default public `matlab/path` API. The corresponding GPLv2 license text is in [GPL-2.0.txt](GPL-2.0.txt). For GPL-2.0-or-later, recipients may elect GPLv2 or a later GPL version according to the upstream header.

To use this legacy function, add this directory to the MATLAB path explicitly. The project's `filter_windowed_fir` and `filter_forward_backward` provide project-native design and application primitives, but their parameters, epoch support, and numerical results must not be claimed identical to `eegfilt` without separate tests.
