function [B,D] = readBoe(fileName,insertZeros,verbose)
% [B,D] = readBoe(fileName,insertZeros,verbose) reads Boesendorfers .raw and .boe
% file format into Matlab and returns a data structure B.
% D is equivalent to B, but all values in one matrix with time, key, val
% as columns.
%
% Set 'verbose' to false to avoid verbose output.
%
% See also: importBoe.m, plotBoe.m
%
% Note: CEUS format has time in ms; we leave it like this!
%
% Werner Goebl, 7 Aug 2006; 13--20 April 2016
%
if nargin < 1
    fprintf('readBoe() requires a file name of a CEUS file.\n');
    help readBoe
    return;
end
if nargin < 2
    insertZeros = false;
end
if nargin < 3
    verbose = true;
end
if verbose
    startTime = now;
    incr = .025; % for display
end

useNewVersion = true;
pattern = [255 255 255 255 255];

B.headertokens = {'VERNR','CEUSTYPE','CEUSRELNR','COMBORELNR','RECORDDATE','RECORDVERNR',...
    'CONVERTDATE','CONVERTFROM','TITLE','KOMPOSER','INTERPRET','TEXT','BIN'};
B.headercontent = {'','','','','','','','','','','','',''};

fid = fopen(fileName,'r');
if fid < 0
    B = -1; D = -1;
    fprintf('readBoe(): %s file not found.\n',fileName);
    return;
end
ff = fread(fid,1); % read first number to find out the file version of file
fseek(fid,0,'bof');
if ff == 255
    fileVersion = 2;
    DD = fread(fid); % DD is hex stream
    fclose(fid);
    idx = strfind(DD',pattern);
    if ~isempty(idx)
        if isequal(DD(end-7:end-3), pattern') && length(idx) >= 2 % apparently footer there
            footerLength = DD(end-11) * 22^24 + DD(end-10) * 2^16 + DD(end-9) * 2^8 + DD(end-8);
            if length(DD) - footerLength + 1 == idx(end-1) + 8
                % footer = DD(end-footerLength+1:end-12);
                if verbose
                    fprintf('correct footer with length: %d.\n', footerLength);
                end
                % read header info at end of file
                metaInfoD = char(DD(idx(end-1)+8:idx(end)-1))';
                semicolons = findstr(metaInfoD, ';');
                for i = 1:length(B.headertokens)
                    s = findstr(metaInfoD, [B.headertokens{i} ':']);
                    if ~isempty(s)
                        B.headercontent{i} = metaInfoD(s+length(B.headertokens{i})+1:min(semicolons(semicolons>s))-1);
                    else
                        B.headercontent{i} = [];
                    end
                end
                %
            end
            fileLength = DD(idx(end-1)+7) + DD(idx(end-1)+6)*256 + DD(idx(end-1)+5)*65536;
            DD = DD(1:idx(1)-1);  % remove timestamp from back
        elseif length(idx) == 1 && isequal(DD(end-7:end-3), pattern')
            fileLength = DD(idx+7) + DD(idx+6)*256 + DD(idx+5)*65536;
            DD = DD(1:idx-1);     % remove timestamp from back
            fprintf('No footer, fileLength: %5.3f s.\n', fileLength / 1000);
        else % truncated
            fileLength = -1;
            fprintf('file truncated.\n', fileLength / 1000);
        end
    else % truncated
        fileLength = -1;
        fprintf('file truncated.\n', fileLength / 1000);
    end
else
    fileVersion = 1;
    DD = fscanf(fid,'%2X');
    fclose(fid);
    idx = strfind(DD',pattern);
    if ~isempty(idx)
        fileLength = DD(idx(1)+7) + DD(idx(1)+6)*256 + DD(idx(1)+5)*65536;
        DD = DD(1:idx(1)-1);     % remove timestamp from back
    else % truncated
        fileLength = -1;
    end
end
szD = size(DD);


if useNewVersion % new input function (much faster)
    
    if verbose
        fprintf('readBoe(%s)\nFileVersion: %.1f, FileLength: %DD ms, ',...
            fileName, fileVersion, fileLength);
    end
    ffs = find(DD==255);
    idx = mod(ffs,2)==0; % remove even indices (FFs must be at odd indices)
    ffs(idx) = [];
    idx = find(diff(ffs)<4); % remove FFs that are within the timestamp values
    ffs(idx+1) = [];
    % figure; hist(diff(ffs),0:100)
    %ts = DD(ffs+1)*65536 + DD(ffs+2)*256 + DD(ffs+3); % time stamp
    
    % construct D array
    D = NaN((max(szD) - 4*length(ffs)) / 2, 3); % create general data array
    
    bins = 0:2:394-2; % max possible values per timestamp: 97 keys + 97 + 3 key/pedal position x 2
    % bin = 0 means zero pair of info after timestamp (theoretically not
    % possible)
    diffs = diff(ffs) - 4; % index distance between timestamps
    % figure; hist(diffs,bins)
    counts = hist(diffs,bins); % how many are there
    cz = counts == 0; % remove value index distances that are not present
    bins(cz) = [];
    
    ddi = 0; % index of new data array
    for bin = min(bins):2:max(bins)
        ffsi = ffs(diffs>=bin); % find all key/val combinations this index distance or larger
        ts = DD(ffsi+1)*65536 + DD(ffsi+2)*256 + DD(ffsi+3); % time stamp
        keys = DD(ffsi+2+bin); % key numbers (hammer, pedals)
        vals = DD(ffsi+3+bin); % values
        D(ddi+1:ddi + length(ffsi),:) = [ts keys vals];
        ddi = ddi + length(ffsi);
    end
    
    tmp = D2Boe(D,insertZeros);
    B.onsets = tmp.onsets;
    B.keyx = tmp.keyx;
    B.keyy = tmp.keyy;
    
else % old version
    
    onsets = sparse(fileLength,108);
    keys = sparse(fileLength,111);
    
    perc = 0;
    if verbose
        fprintf('Loading %s\n',fileName);
        fprintf('FileVersion: %d; File length: %d ms.\n|',fileVersion,fileLength);
        fprintf('*****************************************|\n|');
    end
    
    i = 1;
    while i < length(DD)
        key = DD(i);
        if key == 255 % FF indicates a time stamp
            i = i + 1;
            time = DD(i) * 65536; % 24-bit timestamp in ms
            i = i + 1;
            time = time + DD(i) * 256; % 24-bit timestamp in ms
            i = i + 1;
            time = time + DD(i); % 24-bit timestamp in ms
            
            if verbose && time/fileLength >= perc
                fprintf('*');
                perc = perc + incr;
            end
            
            if time == 16777215 % maximal time value in ms of over 4 hours
                break
            end
        else
            i = i + 1;
            value = DD(i);
            if key < 127 % store key and pedal position
                %fprintf('%09d   K:%s   %3d\n',time,midiNoteName(key),value);
                keys(time,key) = value;
            else % values larger than 127 are note onsets with pitch-128
                %fprintf('%09d   Onset:%s   %3d\n',time,midiNoteName(key-128),value);
                onsets(time,key-128) = value;
            end
        end
        i = i + 1;
    end
    
    if verbose
        fprintf('|\n|');
        perc = 0;
    end
    
    for k = 12:111 % reorganize key position data
        [x,y] = desparsePedal(keys(:,k));
        if ~isempty(find(y~=0, 1))
            B.keyx{k} = x;
            B.keyy{k} = y;
        end
        if verbose && (k-12)/99 >= perc
            fprintf('*');
            perc = perc + incr;
        end
    end
    
    % desparse onset matrix
    [i,j,s] = find(onsets);
    onsets = [i,j,s];
    B.onsets = sortrows(onsets,1);
    
    if verbose
        fprintf('*|\n');
    end
    
end

if fileLength < 0
    B.fileTruncated = true;
    B.fileLength = max(D(:,1));
else
    B.fileTruncated = false;
    B.fileLength = fileLength;
end
B.fileName = fileName;

if verbose
    fprintf('%d onsets, meanHV: %.1f (%d--%d), ',length(B.onsets),...
        mean(B.onsets(:,3)),min(B.onsets(:,3)),max(B.onsets(:,3)));
    fprintf('readBoe() needed %s to read.\n',datestr(now-startTime,13));
end





function [x,y] = desparsePedal(X) % only for old version!
% finds all non-zero elements areas and frames them with a zero
% element. Made for reading in Boesendorfer data.
% See readBoe.m
%
% WG, Aug. 7, 2006
% is it buggy? Check again... (July 2007)
x = 0;
y = 0;
oldi = 0;
for i = 1:length(X)
    if X(i) ~= 0 % if there is non-zero data
        if i > oldi + 2 % insert a zero before movement
            x = [x; i - 2];
            y = [y; 0];
        end
        x = [x; i];
        y = [y; X(i)];
        oldi = i;
    else % if it's zero,
        if i == oldi + 2 %|| i == oldi + 4;
            x = [x; i]; % insert zero after movement
            y = [y; 0];
        end
    end
end
x = [x; i];
y = [y; 0];
