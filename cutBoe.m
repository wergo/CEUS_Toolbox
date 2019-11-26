function B = cutBoe(B, beginTime, endTime, normalizeTime)
% B = cutBoe(B, beginTime, endTime, normalizeTime)
%
% B ......................... the CEUS structure
% beginTime ................. events at and after this time kept (in ms)
% endTime ................... events until and at that time kept (in ms)
% normalizeTime (boolean) ... true: starts relative to beginTime,
%                             false: time unchanged (default)
%
% W.G., 24. April 2017
if nargin < 2
    return
end
if nargin < 3
    endTime = B.fileLength;
end
if nargin < 4
    normalizeTime = false;
end
idx = B.onsets(:,1) <= beginTime | B.onsets(:,1) >= endTime;
B.onsets(idx,:) = [];

if normalizeTime
    B.onsets(:,1) = B.onsets(:,1) - beginTime;
    B.fileLength = endTime - beginTime;
end
for key = 12:111
    if isempty(B.keyx{key})
        continue
    end
    idx = B.keyx{key} <= beginTime | B.keyx{key} >= endTime;
    B.keyx{key}(idx) = [];
    B.keyy{key}(idx) = [];
    if normalizeTime
        B.keyx{key} = B.keyx{key} - beginTime;
    end
end
% header TEXT
B.headercontent{12} = sprintf('cutBoe.m %s: %d-%d ms',B.headercontent{9},beginTime,endTime);

