function B = D2Boe(D,insertZeros)
% B = D2Boe(D,insertZeros)
%
% Werner Goebl, 12. Juni 2017

if nargin < 2 
    insertZeros = false;
end
minKeyGap = 100; % ms, time gap in key profiles, within which zero key values are inserted

D(isnan(D(:,1)),:) = [];
D = sortrows(D,1);

% re-arrange data into data structure
idx = (D(:,2) > 128 & D(:,2) < 112+128);
B.onsets = D(idx,:);
B.onsets(:,2) = B.onsets(:,2) - 128;

for k = 12:111
    idx = find(D(:,2)==k);
    if isempty(idx)
        continue
    end
    
    % add zero key pos at boundaries of a time gap (one before, one after).
    if insertZeros
        dk = diff(D(idx,1));
        dkeys = find(dk > minKeyGap);
        j = length(idx);
        K = NaN(j + length(dkeys) * 2 + 4, 3);
        K(1:j,:) = D(idx,:);
        % insertion list: first key value; leading before first key
        % position; zero after last key position; last key value
        %insList = [2, D(idx(1),1)-2, D(idx(1),1)+2, max(fileLength,max(D(:,1)))];
        insList = [2, D(idx(1),1)-2, D(idx(1),1)+2, max(D(:,1)+2)];
        for l = 1:length(insList)
            if isempty(find(K(:,1)==insList(l), 1))
                j = j + 1;
                K(j,:) = [insList(l) k 0]; % first key value
            end
        end
        %             if isempty(find(K(:,1)==D(idx(1),1)-2, 1))
        %                 j = j + 1;
        %                 K(j,:) = [D(idx(1),1)-2 k 0]; % leading before first key position
        %             end
        %             if isempty(find(K(:,1)==D(idx(end),1)+2, 1))
        %                 j = j + 1;
        %                 K(j,:) = [D(idx(end),1)+2 k 0]; % zero after last key position
        %             end
        %             if isempty(find(K(:,1)==max(fileLength,max(D(:,1))), 1))
        %             j = j + 1;
        %             K(j,:) = [max(fileLength,max(D(:,1))) k 0]; % last key value
        %             end
        for i = 1:length(dkeys)
            j = j + 1;
            K(j,:) = [D(idx(dkeys(i)),1)+2 k 0];
            j = j + 1;
            K(j,:) = [D(idx(dkeys(i)+1),1)-2 k 0];
        end
    else
        K = D(idx,:);
    end
    
    K = sortrows(K,1);
    K(isnan(K(:,1)),:) = [];
    B.keyx{k} = K(:,1);
    B.keyy{k} = K(:,3);
    
end
