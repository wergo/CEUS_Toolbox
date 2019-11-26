function D = boe2D(B)
% D = boe2D(B) converts the B structure (with separate keys and note onset 
% arrays) into a double array D (onset, tone/key, pos/vel), as for the 
% CEUS data format.
%
% Werner Goebl, 12. Juni 2017

% count size of each key/pedal
lo = length(B.onsets);
idx = lo;
for key = 12:111
    idx = idx + length(B.keyx{key});
end

% input onsets
D = zeros(idx,3);
D(1:lo,:) = B.onsets;
D(1:lo,2) = B.onsets(:,2) + 128; % onset pitch info stored one bit higher

% input keys and pedal values
for key = 12:111
    if ~isempty(B.keyx{key})
        sz = size(B.keyx{key});
        if sz(1) > sz(2) % correct file format
            tmp = [B.keyx{key} key*ones(sz) B.keyy{key}];
        else
            tmp = [B.keyx{key}' key*ones(sz)' B.keyy{key}'];
        end
        D(lo+1:lo+max(sz),:) = tmp;
        lo = lo + max(sz);
    end
end
D = sortrows(D,[1,2]); % sort onsets, key and pedal values by time stamp
