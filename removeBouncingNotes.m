function B = removeBouncingNotes(B,threshold, verbose)
% B = removeBouncingNotes(B,threshold) detects bouncing notes, that is
% notes that repeat within a given threshold (default = 20 ms), and removes
% the softer of the two. Only affects content of B.onsets, not the key
% trajectories.
%
% Werner Goebl, 18. Juli 2019
if nargin < 1
    fprintf('removeBouncingNotes() requires a CEUS file structure.\n');
    help removeBouncingNotes
    return;
end
if nargin < 2
    threshold = 30; % ms
end
if nargin < 3
    verbose = false;
end
for pitch = 12:108
    onsIdx = find(B.onsets(:,2) == pitch);
    onsets = B.onsets(onsIdx);
    iois = diff(onsets);
    bounces = find(iois <= threshold);
    removeIdx = zeros(size(bounces));
    for i = 1:length(bounces)
        if bounces(i)+1 <= size(onsIdx,1)
            if verbose
                fprintf('Bounce %d removed (pitch: %d, onset: ',i, pitch);
            end
            if B.onsets(onsIdx(bounces(i)),3) < B.onsets(onsIdx(bounces(i)+1),3)
                if verbose
                    fprintf('%5.3f\n',B.onsets(onsIdx(bounces(i)),1)/1000);
                end
                removeIdx(i) = onsIdx(bounces(i));
            else
                if verbose
                    fprintf('%5.3f\n',B.onsets(onsIdx(bounces(i)+1),1)/1000);
                end
                removeIdx(i) = onsIdx(bounces(i)+1);
            end
        end
    end
    B.onsets(removeIdx,:) = [];
end

