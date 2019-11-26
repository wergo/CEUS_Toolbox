function plotBoe(B,showInfo)
% plotBoe(B) plots a quick graphical representation
% of the data structure 'B'.
%
% See also: readBoe.m, importBoe.m
%
% WG, Aug. 7, 2006 (2017)
if nargin < 2
    showInfo = false;
end
vels = 255;
intColor = [ones(vels,1) linspace(0,1,vels)' zeros(vels,1)];

hold on;
xlabel('Time (s)');
ylabel('MidiPitch (C4=60)');

%keyboard(2,[1 0],[1 0],[.6 .6 .6],[.6 .6 .6]);

% plot key positions
for key = 12:length(B.keyx)
    if ~isempty(B.keyx{key})
        if     key == 109; col = [1 0 0];
        elseif key == 110; col = [0 1 0];
        elseif key == 111; col = [0 0 1];
        else               col = [.6 .9 .6];
        end
        line([min(B.keyx{key}/1000) max(B.keyx{key}/1000)],[key key],...
            'color',[.8 .8 .8]);
        plot(B.keyx{key}/1000,key-B.keyy{key}/vels,'.-',...
            'color',col);
    end
end

yLim = get(gca,'yLim');
pianoKeyboard(2,[1 0],[1 0]);
set(gca,'yLim',yLim);
% plot onsets
for i = 1:length(B.onsets)
    line([B.onsets(i,1)/1000 B.onsets(i,1)/1000],...
        [B.onsets(i,2) B.onsets(i,2)-(B.onsets(i,3)/255)],...
        'color',intColor(max(B.onsets(i,3),1),:));
    line([B.onsets(i,1)/1000 B.onsets(i,1)/1000],...
        [B.onsets(i,2)-(B.onsets(i,3)/255) B.onsets(i,2)-1],...
        'color',[.8 .8 .8]);
    if isfield(B,'isRepeated')
        if B.isRepeated(i)
            text(B.onsets(i,1)/1000,B.onsets(i,2),'R',...
                'horizontalAlignment','center','verticalAlignment','bottom');
        end
    end
    if isfield(B,'noteOffs')
        line([B.noteOffs(i)-50 B.noteOffs(i)+50]/1000,...
            [B.onsets(i,2)-B.offsetKeyValue/255 B.onsets(i,2)-B.offsetKeyValue/255],...
            'color',[.7 .7 .7]);
        plot(B.noteOffs(i)/1000,B.onsets(i,2)-B.offsetKeyValue/255,'go');
    end
    if isfield(B,'KBlevels')
        line([B.KBs(i) B.noteOffs(i)]/1000,...
            [B.onsets(i,2)-B.KBlevels(i)/255 B.onsets(i,2)-B.KBlevels(i)/255],...
            'color',[.7 .7 .7]);
    end
end

if isfield(B,'FKs') % plot FKs
    for i = 1:length(B.onsets)
        pitch = B.onsets(i,2);
        plot(B.FKs(i)/1000,pitch,'bo');
        y = pitch-B.keyy{pitch}(find(B.keyx{pitch}<=B.KBs(i), 1, 'last' ))/vels;
        if ~isempty(y)
            plot(B.KBs(i)/1000,y,'c.');
            if B.FKratings(i) < 100 && B.FKratings(i) > 0
                text(B.FKs(i)/1000,pitch,num2str(B.FKratings(i)),...
                    'horizontalAlignment','center','verticalAlignment','bottom');
            end
        end
    end
    noFKs = find(B.FKratings==0);
    for i = 1:length(noFKs)
        plot(B.onsets(noFKs(i),1)/1000,B.onsets(noFKs(i),2),'ro','markerSize',10);
    end
end

if showInfo
    for i = 1:length(B.onsets)
        text(B.onsets(i,1)/1000,B.onsets(i,2),num2str(i),...
            'horizontalAlignment','center')
    end
end

if isfield(B,'fileName')
    title(t_t(B.fileName));
end
