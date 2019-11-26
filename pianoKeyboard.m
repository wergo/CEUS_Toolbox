function pianoKeyboard(option,wFacts,hPos,edgeColor,faceColor);
% pianoKeyboard(option,wFacts,hPos,edgeColor,faceColor)
%
% option      1 ... x axis
%             2 ... y axis
% wFacts      width factors (mult, additive)
% hPos        position of keyboard height (e.g., [0 20])
%
% Werner Goebl, November 2006
if nargin < 1
    option = 2;
end
if nargin < 2
    wFacts = [1 0];
end
if nargin < 3
    hPos = [0 20];
end


keyRange1 = 12; % Boesendorfer Imperial (Steinway 21)
keyRange2 = 108; % upper end
bkInd   = 0.5;
if nargin < 4
    edgeColor = [bkInd bkInd bkInd];
end
if nargin < 5
    faceColor = [bkInd bkInd bkInd];
end
greyInd = .7;

%if keyRange1 < 21 % lower keys at Boesendorfer grey
%    x = [11.5 11.5 20 20];
%    y = [ylwkey ytop ytop ylwkey];
%    fill(x,y,[greyInd greyInd greyInd]);
%end
black_key = [2 4 7 9 11];
white_key = [1 3 5 6 8 10 12];

htop   = hPos(1);
hupkey = hPos(1) + .35 * diff(hPos);
hlwkey = hPos(2);
hold on;
if option == 1     % x axis
    line([keyRange1-.5 keyRange2+1],[htop htop],'color',edgeColor);
    line([keyRange1-.5 keyRange2+1],[hlwkey hlwkey],'color',edgeColor);
elseif option == 2 % y axis
    line([htop htop],[keyRange1-.5 keyRange2+1]*wFacts(1)+wFacts(2),'color',edgeColor);
    line([hlwkey hlwkey],[keyRange1-.5 keyRange2+1]*wFacts(1)+wFacts(2),'color',edgeColor);
end
for octs = 11:12:96 % 1:8 = 12 to 108
    for i = 1:5 % draw black keys
        % black keys are .84 of one tone (~half of the width of a white
        % key)
        if option == 1 % BUGGGGGGGYYYYY!
            h = htop-hupkey;
            if h < 0
                y = hupkey + h;
            else
                y = hupkey;
            end
            r= rectangle('position',...
                [octs + black_key(i)-.42 hupkey .84 abs(h)]);
            set(r,'facecolor',faceColor);
            set(r,'edgecolor',edgeColor);
        elseif option == 2
            w = hupkey-hlwkey;
            if w > 0
                x = (hupkey - w);
            else
                x = hupkey;
            end
            r= rectangle('position',...
                [x (octs + black_key(i)-.42)*wFacts(1)+wFacts(2) abs(w) .84*wFacts(1)]);
            set(r,'facecolor',faceColor);
            set(r,'edgecolor',edgeColor);
        end
    end
    c = 1;
    for w = (octs+.5 : 5/3 : octs+5.5)*wFacts(1)+wFacts(2)
        if option == 1
            line([w w],[htop hlwkey],'color',edgeColor);
        elseif option == 2
            if c == 2 || c == 3
                line([htop hupkey],[w w],'color',edgeColor);
            else
                line([htop hlwkey],[w w],'color',edgeColor);
            end
        end
        c = c + 1;
    end
    c = 1;
    for w = (octs+5.5 : 7/4 : octs+12.5)*wFacts(1)+wFacts(2)
        if option == 1
            line([w w],[htop hlwkey],'color',edgeColor);
        elseif option == 2
            if c == 2 || c == 3 || c == 4
                line([htop hupkey],[w w],'color',edgeColor);
            else
                line([htop hlwkey],[w w],'color',edgeColor);
            end
        end
        c = c + 1;
    end
    %for w = octs+.5 : 12/7 : octs+12.5
    %    line([w w],[ytop ylwkey],'color',edgeColor);
    %end
end
w = (w + 1.2)*wFacts(1)+wFacts(2);
if option == 1
    line([w w],[htop hlwkey],'color',edgeColor);
    set(gca,'xlim',[keyRange1-.5 keyRange2+.7]);
    %set(gca,'xTick',(12:12:108)*wFacts(1)+wFacts(2));
elseif option == 2
    line([htop hlwkey],[w w],'color',edgeColor);
    set(gca,'ylim',[keyRange1-.5 keyRange2+.7]*wFacts(1)+wFacts(2));
    %set(gca,'yTick',(12:12:108)*wFacts(1)+wFacts(2));
end
%text(69,ylwkey + abs(ytop-ylwkey)/24,'440 Hz','rotation',90);