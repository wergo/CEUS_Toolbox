function B = data2ceus(nmat)
% B = data2ceus(data) creates a CEUS B structure from the nmat array 
% imported by readmidi.m of the Midi Toolbox 
% (https://github.com/miditoolbox/).
%
% As the Miditoolbox is ignoring pedal data, this will not be parsed to the
% CEUS file at the moment. Pedals info should be written to 
% B.keyx{109,110,111} and B.keyy{109,110,111} for left, middle, and right
% pedal, respectively.
%
% Werner Goebl, 19. Sept 2017 / 26. Nov. 2019

onsets  = nmat(:,6) * 1000; % to ms
pitches = nmat(:,4);
dyns    = nmat(:,5);
offsets = (nmat(:,6) + nmat(:,7)) * 1000; % to ms

onsetdur = 50; % ms, duration of onset ramp (before HSt) (even number)
offsetdur = 100; % ms, duration of offset ramp (even number)
minKeyVal = 0;
maxKeyVal = 240;


for k = 21:111
    B.keyx{k} = [0 max(offsets) + offsetdur];
    B.keyy{k} = [0 0];
end

B.onsets = [onsets, pitches, dyns];
for i = 1:length(pitches)
    
    % onset ramp (simply linear)
    onset = round(onsets(i)/2)*2; % round to nearest multiple of 2
    x = max(0,onset - onsetdur) : 2 : onset;
    B.keyx{pitches(i)} = [B.keyx{pitches(i)} x];
    B.keyy{pitches(i)} = [B.keyy{pitches(i)} round(linspace(minKeyVal,maxKeyVal,length(x)))];
    
    % note duration down values
    off1 = round(offsets(i)/2)*2 - offsetdur / 2;
    off2 = off1 + offsetdur;
    x = onset + 2 : 2 : off1;
    B.keyx{pitches(i)} = [B.keyx{pitches(i)} x];
    B.keyy{pitches(i)} = [B.keyy{pitches(i)} ones(1,length(x))*maxKeyVal];
    %BB.keyy{pitches(i)}(end) = minKeyVal; % set last to offset
    
    % offset ramp
    x = off1 + 2 : 2 : off2;
    B.keyx{pitches(i)} = [B.keyx{pitches(i)} x];
    B.keyy{pitches(i)} = [B.keyy{pitches(i)} round(linspace(maxKeyVal,minKeyVal,length(x)))];
    
end

for k = 21:111
    [~,si] = sort(B.keyx{k});
    B.keyx{k} = B.keyx{k}(si);
    B.keyy{k} = B.keyy{k}(si);
    
    idx = find(diff(B.keyx{k})==0);
    i = 1;
    while i < length(idx)
        %figure; plot(BB.keyx{k},'.-'); hold on; t
        
        if (B.keyy{k}(idx(i)) < B.keyy{k}(idx(i)+1))
            B.keyx{k}(idx(i)) = [];
            B.keyy{k}(idx(i)) = [];
        else
            B.keyx{k}(idx(i)+1) = [];
            B.keyy{k}(idx(i)+1) = [];
        end
        idx = find(diff(B.keyx{k})==0);
    end
end
