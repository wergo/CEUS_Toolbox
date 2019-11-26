function B = findBoeFKB(B,plotIt)
% B = findBoeFKB(B,plotIt) finds the key-bottom (KB) and finger-key (FK)
% contact landmarks for all onsets in the B structure. 
%
% This function combines the landmark search for acceleration peaks with 
% clear predicitions of where these landmarks should occur for keystrokes 
% with a given dynamical value.
%
% For more information, see:
% Goebl &?Palmer 2008, https://dx.doi.org/10.1007/s00221-007-1252-1 and 
% Goebl & Palmer 2009, https://dx.doi.org/10.1525/mp.2009.26.5.427.
%
% WG, 31. Aug 2007; Sept 2007; July 2017
if nargin < 2
    plotIt = false;
end
if isequal(B,-1)
    fprintf('B structure is empty.\n')
    return
end
KBs = NaN(size(B.onsets,1),1);
KBys = NaN(size(B.onsets,1),1);
FKmaxs = NaN(size(B.onsets,1),1);
FK0s = NaN(size(B.onsets,1),1);
FKs = NaN(size(B.onsets,1),1);
FKys = NaN(size(B.onsets,1),1);
KBratings = NaN(size(B.onsets,1),1);
FKratings = NaN(size(B.onsets,1),1);
isRepeated = NaN(size(B.onsets,1),1);
% B needed
before = 300; % ms GENERAL RANGE (plotting reasons) before onset.
after  = 200; % ms
kbafter  = 45; % ms after onset (HS), was 50ms
kbbefore = 06; % ms before onset (HS)
fkbefore = 250; % ms before HSt
fkafter  = -15; % ms after HSt (negative means therefore before HSt)
fkPlateau = 30; % ms when a plateau of 0vel is longer than fkPlateau, it is preferred to FKmax
% calculate note offset time stamps
offsetKeyValue = 90; % key position value (0--250), below which a note offset is determined (July 2017)
B.noteOffs = NaN(size(B.onsets,1),1);
B.offsetKeyValue = offsetKeyValue;

%scienceMode = false;
%for k = 12:108
%    if ~isempty(B.keyy{k})
%        scienceMode = ~isempty(find(B.keyy{k}<4 & B.keyy{k}>0));
%        break;
%    end
%end
noDoubleTimestamps = 0; % number of double time values
for o = 1:size(B.onsets,1)
    clear x y
    onset = B.onsets(o,1);
    pitch = B.onsets(o,2);
    hvel = B.onsets(o,3);
    
    prevonset = NaN; % determine a prev onset of same pitch (if there is)
    prevhvel = NaN;
    i = o - 1;
    while i > 1
        if B.onsets(i,2) == pitch
            prevonset = B.onsets(i,1);
            prevhvel = B.onsets(i,3);
            break;
        end
        i = i - 1;
    end
    
    % find general range of keystroke and interpolate data
    idx = find(B.keyx{pitch} < onset+after & B.keyx{pitch} > onset-before);
    % take only that key position data that has a continuous trajectory from FK to onset
    [~,onseti] = min(abs(B.keyx{pitch}(idx) - onset));
    dx = diff(B.keyx{pitch}(idx(1:onseti)));
    gaps = find(dx > 2);
    if ~isempty(gaps)
        idx = idx(gaps(end)+1:end);
    end
       
    x = [B.keyx{pitch}(idx(1)) - 2; B.keyx{pitch}(idx)];
    y = [0; B.keyy{pitch}(idx)]; % insert zero before data begins
    start = ceil((onset-before)/2)*2; % interpolate zeros from start--stopp
    if (min(x) > start)
        x = [start; x];
        y = [0; y]; % y = [y(1); y]; % insert zero before data begins
    end
    stopp = floor((onset+after)/2)*2;
    if (max(x) < stopp)
        x = [x; stopp];
        y = [y; y(end)];
    end
    deleandos = find(diff(x)==0); % remove rep. x-values (they exist!)
    x(deleandos) = [];
    y(deleandos) = [];
    noDoubleTimestamps = noDoubleTimestamps + length(deleandos);
    xn = start:2:stopp;
    yn = interp1(x,y,xn); % interpolate
    x = xn; y = yn;
    % figure; plot(x,y,'.-'); hold on; plot(xn,yn,'r.')
    
    
    % determine KB range
    kbidx = find(x >= onset - kbbefore & x <= onset + kbafter);
    kbx = x(kbidx);
    kby = y(kbidx);
    dx = x(kbidx(1:end-1))+1;
    dy = diff(-y(kbidx)); % key velocity
    
    % first zero crossing
    [y0,x0] = crossing(dy,dx,0,'linear'); % find zero crossings in VEL
    i = 1;
    if false % if more than 1 zero crossing, take average of them
        if length(x0) > 1
            while (x0(i+1)-x0(i) == 2)
                i = i + 1;
                if (i >= length(x0)) break; end
            end
        end
    end
    if isempty(x0)
        KB_0 = NaN;
    else
        KB_0 = mean(x0(1:i));
    end
    
    % min positions
    [minval,minpos] = min(-kby); % take first min position
    i = 1;
    if false % if more than 1 min pos, take average of them
        minpos = find(-kby==minval);
        if length(minpos) > 1
            while (kbx(minpos(i+1))-kbx(minpos(i)) == 2)
                i = i + 1;
                if (i >= length(minpos)) break; end
            end
        end
    end
    if isempty(minpos)
        KB_min = NaN;
    else
        KB_min = mean(kbx(minpos(1:i)));
    end
    
    % combine two measures
    if abs(KB_min - KB_0) < 2
        %KB = (KB_min + KB_0) / 2; % mean
        KB = KB_min;
        KBrating = 100;
    else
        alternatives = find(abs(x0-KB_min)<2);
        if ~isempty(alternatives)
            KB = mean(x0(alternatives));
            KBrating = 90;
        else
            KB = KB_0;
            KBrating = 0;
        end
        asdf = 1234;
    end
    
    KBval = y(max(find(x<KB_0)));
    if isempty(KBval); KBval = NaN; end
    
    
    
    % determine FK range (max to previous onset of same pitch)
    fkidx = find(x >= max(onset-fkbefore,prevonset) & x <= onset + fkafter);
    fkx = x(fkidx);
    fky = y(fkidx);
    fkdx = x(fkidx(1:end-1))+1;
    fkdy = diff(-y(fkidx)); % key velocity
    
    if onset-fkbefore < prevonset
        isRepeated(o) = true;
    else
        isRepeated(o) = false;
    end
    
    % determine FK by position (right-most maximum)
    maxpos = find(fky==min(fky));
    FK_max = fkx(max(maxpos));
    FK_maxY= fky(max(maxpos));
    
    % determine right-most continuous zero vel
    velzeros = find(fkdy==0);
    oldval = -1; oldi = 0; streamsi = []; streamsLength = [];
    i = 1;
    while i < length(velzeros) % find continuous parts longer than 3 zeros
        while velzeros(i)==oldval+1
            oldval = velzeros(i);
            if i >= length(velzeros)
                i = i + 1;
                qwer = 1234;
                break;
            end
            i = i + 1;
        end
        if i-1 - oldi + 1 > 3 % plateau found + check out
            streamsi = [streamsi; ...
                [velzeros(oldi) velzeros(min(i-1,length(velzeros)))]];
            streamsLength = [streamsLength i - oldi+1];
            asdf = 1234;
        end
        if i <= length(velzeros)
            oldval = velzeros(i);
        end
        oldi   = i;
        i = i + 1;
    end
    kf0i = max(max(streamsi)) + 1;
    FK_0 = fkx(kf0i);
    FK_0Y= fky(kf0i);
    longPlateaus = find(streamsLength > fkPlateau / 2);
    
    if isempty(FK_0); FK_0 = NaN; end
    if ~isempty(streamsi)
        alternatives = find(abs(fkdx(streamsi(:,2))-FK_max) < 4);
    else
        alternatives = [];
    end
    if abs(FK_0 - FK_max) <= 4 % when both measures tell the same story
        FK = (FK_0 + FK_max) / 2;
        FKy = (FK_0Y + FK_maxY) / 2;
        FKrating = 100;
    elseif FK_max > FK_0 % when MAX earlier to HS than 0vel
        FK = FK_max;
        FKy = FK_maxY;
        FKrating = 70;
    elseif ~isempty(longPlateaus) % prefer long plateaus over max
        FK = fkx(streamsi(max(longPlateaus),2)+1);
        FKy = fky(streamsi(max(longPlateaus),2)+1);
        FKrating = 60;
    elseif ~isempty(alternatives)
        FK = fkdx(streamsi(alternatives,2)+1);
        FKy = fkdy(streamsi(alternatives,2)+1);
        FKrating = 80;
    else
        FK = FK_max; % ATTENTION: changed! Think what to do here....
        FKy = FK_maxY;
        FKrating = 0;
    end
    
    % store values
    if ~isempty(KB);     KBs(o) = KB;        else KBs(o)    = NaN; end
    if ~isempty(KBval);  KBys(o) = KBval;    else KBys(o)   = NaN; end
    if ~isempty(FK_max); FKmaxs(o) = FK_max; else FKmaxs(o) = NaN; end
    if ~isempty(FK_0);   FK0s(o) = FK_0;     else FK0s(o)   = NaN; end
    if ~isempty(FK);     FKs(o) = FK;        else FKs(o)    = NaN; end
    if ~isempty(FKy);    FKys(o) = FKy;      else FKys(o)   = NaN; end
    
    KBratings(o) = KBrating;
    FKratings(o) = FKrating;
    
    
    % find note off time stamp
    offidx = find(B.keyx{pitch} > KBs(o));
    j = 1;
    if ~isempty(offidx)
        while B.keyy{pitch}(offidx(j)) > offsetKeyValue && j < length(offidx)
            j = j + 1;
        end
        B.noteOffs(o) = B.keyx{pitch}(offidx(j));
    end
    
    
    % PLOTTING
    %if false && abs(KB_min - KB_0) >= 2
    if KBval < 160  && plotIt
        %if (onset - FK) < 100 - .5 * midiv % FK test
        %if FKrating < 100
        %if onset-fkbefore < prevonset
        figure(2); clf;
        plot(x,-y,'.-'); hold on;
        yLim = [-256 1];
        set(gca,'xlim',[min(x) max(x)]);
        set(gca,'ylim',yLim);
        line([onset onset],get(gca,'ylim'),'color',[.5 .5 .5]);
        title(sprintf('o=%d; pitch=%d, MV=%d, KBy=%d',o,pitch,hvel,KBval))
        line([KB KB],get(gca,'ylim'),'color','g');
        line([FK_0 FK_0],[yLim(1) yLim(1)+diff(yLim)/2],'color',[.5 .5 .8]);
        plot(FK_0,0,'ro','markersize',10);
        line([FK_max FK_max],[yLim(1) yLim(1)+diff(yLim)/2],'color',[0 0 .9]);
        line([FK FK],[yLim(1)+diff(yLim)/2 yLim(2)],'color',[0 0 .3]);
        line([prevonset prevonset],yLim,'color','r');
        text(prevonset,max(yLim),num2str(prevhvel),...
            'horizontalAlignment','center','verticalalignment','top');
        text(onset,-40,sprintf('FKrating=%3d',FKrating));
        text(onset,-50,sprintf('KBrating=%3d',KBrating));
        
        plot(x(2:end-1),-230+10*diff(diff(-y)),'m.-','clipping','off');
        
        lambda = '10^-18'; denom = 5;
        xknots = x(1:denom:end);
        if xknots(end) ~= x(end); xknots = [xknots x(end)]; end
        xknots = sort([xknots KB KB KB]);
        xknots = sort([xknots FK FK FK]);
        %xknots = sort([xknots FK+2 FK+2 FK+2]);
        [y_fd,df,gcv] = makeFDA(x, -y, lambda, denom, xknots);
        X = min(x):diff(x)/5:max(x);
        y0_sm      = eval_fd(X,y_fd,int2Lfd(0));
        y2_sm      = eval_fd(X,y_fd,int2Lfd(2));
        plot(X,y0_sm,'r-');
        plot(X,-230+10*y2_sm,'r-','linewidth',2);
        
        qwer = 1234;
        if false
            figure(3); clf;
            line([min(dx) max(dx)],[0 0],'color',[.8 .8 .8]); hold on;
            line([onset onset],[-10 10],'color','r');
            plot(dx,dy,'r.-');
            plot(x0,zeros(length(x0)),'y*');
            line([KB_0 KB_0],get(gca,'ylim'),'color','y');
            plot(kbx(minpos),ones(length(minpos)),'mv');
            line([KB_min KB_min],get(gca,'ylim'),'color','m');
            line([KB KB],[0 10],'color','g');
            if ~isempty(streamsi)
                plot(fkdx(velzeros(streamsi(:,2))),ones(size(streamsi)),'bd');
            end
            
            plot(fkdx,fkdy,'.-');
            line([FK_0 FK_0],get(gca,'ylim'),'color',[.5 .5 .8]);
            line([FK_max FK_max],get(gca,'ylim'),'color',[0 0 .7]);
            if KBrating == 0
                title('Attention: KB conflict!');
                qwer = 1234;
            else
                title('');
            end
            %set(gca,'xlim',[min(x) max(x)]);
            
            %figure(4); clf;
            %plot(dx(1:end-1)+1,diff(dy),'.-');
            %line([onset onset],get(gca,'ylim'),'color','r');
            %line([KB KB],get(gca,'ylim'),'color','g');
            %line([min(dx) max(dx)],[0 0],'color',[.8 .8 .8]); hold on;
            
            figure(5); clf;
            plot(B.onsets(1:length(KBs),3),...
                -B.onsets(1:length(KBs),1)+KBs','.','color',[.8 .8 .8]);
            hold on;
            plot(midiv,KB - onset,'.');
            axis([0 255 -10 55]);
            
            figure(2);
        end
        qwer = 1234;
    end
    
    
    qwer = 1234;
end

B.KBs = KBs;
B.KBys = KBys;
B.KBratings = KBratings;

B.FKs = FKs;
B.FKys = FKys;
B.FK0s = FK0s;
B.FKmaxs = FKmaxs;
B.FKratings = FKratings;
B.isRepeated = isRepeated;
B.noDoubleTimestamps = noDoubleTimestamps;


if false
    figure; clf; hold on;
    for i = 1:length(B.KBs)
        if ~isnan(B.KBys(i))
            props = [B.KBys(i)/255 0 0];
            if B.KBys(i) < 200
                props = 'b';
            end
            h(1)=plot(B.onsets(i,3),B.KBs(i)-B.onsets(i,1),...
                'color',props,'marker','.');
            if B.KBratings(i) == 0
                h(2) = plot(B.onsets(i,3),B.KBs(i)-B.onsets(i,1),'go');
            elseif B.KBratings(i) == 90
                h(3) = plot(B.onsets(i,3),B.KBs(i)-B.onsets(i,1),'yo');
            end
        end
    end
    legend(h,'KBpos lower','no result','alternative');
    xlabel('MIDI vels');
    ylabel('KB-HS (ms)');
    
    figure; clf; hold on;
    for i = 1:length(B.FKs)
        if isnan(B.FK0s(i)) || B.FKratings(i) == 0
            plot(B.onsets(i,3),B.onsets(i,1)-B.FKmaxs(i),'.','color','r');
        elseif B.FKratings(i) < 100
            %plot(B.onsets(i,3),B.onsets(i,1)-B.FKmaxs(i),'.','color',[0 0 .7]);
            %plot(B.onsets(i,3),B.onsets(i,1)-B.FK0s(i),'.','color',[.5 .5 .8]);
            plot(B.onsets(i,3),B.onsets(i,1)-B.FKs(i),'.','color',[.2 .6 .2]);
        else
            plot(B.onsets(i,3),B.onsets(i,1)-B.FKs(i),'.','color',[0 1 0]);
            %plot([B.onsets(i,3) B.onsets(i,3)],...
            %[B.onsets(i,1)-B.FKmaxs(i) B.onsets(i,1)-B.FK0s(i)],'-','color',[0 0 .7]);
        end
    end
    set(gca,'xlim',[0 255]);
    xx = [0 200]; yy = 100 + -.5 * xx; line(xx,yy)
    xlabel('MIDI vels'); ylabel('HS-FK (ms)');
    axis([0 250 0 160])
end
