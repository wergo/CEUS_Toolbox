% Demo 02: Create artificial BOE file: chromatic scale upwards repeated
% eight times, starting in ppp (vel = 30) to mf (vel = 100).
%
% Werner Goebl, 2016

clear; clc

ioi = 020; % ms
dur = 024; % ms always even numbers!!

minKeyVal = 0;
maxKeyVal = 240;
initpause = 200;

ps = 21:108;
pitches = []; dyns = [];
ds = 30:10:100;
for d = ds
    pitches = [pitches ps];
    dyns = [dyns ones(size(ps))*d];
end
% create key position
for k = 21:111
    BB.keyx{k} = [0 ioi*(length(pitches)+10)+initpause];
    BB.keyy{k} = [0 0];
end

BB.onsets = zeros(length(pitches),3);
onset = initpause;
for i = 1:length(pitches)
    onset = onset + ioi;
    %ONSETS: time; key; value;
    BB.onsets(i,:) = [onset pitches(i) dyns(i)];
    
    % onset ramp (simply linear)
    onset = round(onset/2)*2; % round to nearest multiple of 2
    x = onset - 50 : 2 : onset;
    BB.keyx{pitches(i)} = [BB.keyx{pitches(i)} x];
    BB.keyy{pitches(i)} = [BB.keyy{pitches(i)} round(linspace(minKeyVal,maxKeyVal,length(x)))];
    
    % note duration down values
    x = onset + 2 : onset + dur;
    BB.keyx{pitches(i)} = [BB.keyx{pitches(i)} x];
    BB.keyy{pitches(i)} = [BB.keyy{pitches(i)} ones(1,length(x))*maxKeyVal];
    %BB.keyy{pitches(i)}(end) = minKeyVal; % set last to offset
    
    % offset ramp
    x = onset + dur + 2 : 2 : onset + dur + 30;
    BB.keyx{pitches(i)} = [BB.keyx{pitches(i)} x];
    BB.keyy{pitches(i)} = [BB.keyy{pitches(i)} round(linspace(maxKeyVal,minKeyVal,length(x)))];
    
end

for k = 21:111
    [y,si] = sort(BB.keyx{k});
    BB.keyx{k} = BB.keyx{k}(si);
    BB.keyy{k} = BB.keyy{k}(si);
    
    idx = find(diff(BB.keyx{k})==0);
    i = 1;
    while i < length(idx)
        %figure; plot(BB.keyx{k},'.-'); hold on; t
        
        if (BB.keyy{k}(idx(i)) < BB.keyy{k}(idx(i)+1))
            BB.keyx{k}(idx(i)) = [];
            BB.keyy{k}(idx(i)) = [];
        else
            BB.keyx{k}(idx(i)+1) = [];
            BB.keyy{k}(idx(i)+1) = [];
        end
        idx = find(diff(BB.keyx{k})==0);
    end
end

figure(1); clf;
plotBoe(BB)
writeBoe(BB,'scaleup-30-100.boe',false)

