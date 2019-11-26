function writeBoe(B,outFile,writeBinary,D)
% writeBoe(B,outFile,writeBinary,D)
%
% WG, 11 OCt 2007; 12--20 April 2016; 20. April 2017
%
% BUG: saving binary does not work (or at least is not accepted by Corella...)
% Update 20 April 2017: reading BOE without inserting zeros lets me write
% boe-files that can be read by Corella...
%
% if D is parsed, all performance data from B will be ignored.

startTime = now;

if nargin < 2
    warning('writeBoe(): Please specify output file.');
    return;
end
if nargin < 3
    writeBinary = true; % boe format version 2.0 in binary format (as opposed to hex text).
end
if nargin < 4
    D = [];
end
precision = 'uint8';

% Header fields, defined by Boesendorfer (sorry for the typos, not my fault)
headertokens = {'VERNR','CEUSTYPE','CEUSRELNR','COMBORELNR','RECORDDATE','RECORDVERNR',...
    'CONVERTDATE','CONVERTFROM','TITLE','KOMPOSER','INTERPRET','TEXT','BIN'};
headercontent = {'','','','','','','','','','','','',''};
if isfield(B,'headercontent')
    for i = 1:length(B.headercontent)
        if ~isempty(B.headercontent{i})
            headercontent{i} = B.headercontent{i};
        end
    end
end
% overwrite some fields:
if writeBinary
    headercontent{1} = '2.00';
else
    headercontent{1} = '1.00';
end
headercontent{7} = datestr(now); % convertdate
headercontent{8} = 'created by writeBoe.m (Werner Goebl, 2007-2017)'; % convertfrom
headercontent{9} = fileNameName(outFile,2); % title

if isempty(D)
    D = boe2D(B); % outsourced into separate function (12. June 2017)
    D(:,1) = round(D(:,1));
end

%if isfield(B,'fileLength')
%    fileLength = B.fileLength;
%else
fileLength = max(D(:,1));
%end

% find location of time stamps
ti = [0; find(diff(D(:,1)) > 0)] + 1;
timeStamps = D(ti);

% final data array
DD = NaN(2*length(D) + length(timeStamps)*4,1);
tti = (ti-1)*2+1 + (0:length(ti)-1)'*4;  % idx for each new event

% write time stamps
ht = dec2hex(timeStamps,6);
DD(tti) = 255;
DD(tti+1) = hex2dec(ht(:,1:2));
DD(tti+2) = hex2dec(ht(:,3:4));
DD(tti+3) = hex2dec(ht(:,5:6));

bins = 2:2:394-2; % max possible values per timestamp: 97 keys + 97 + 3 key/pedal position x 2
% bin = 0 means zero pair of info after timestamp (not possible and should not be written)

diffs = [diff(tti) - 4; 2*(length(D)-ti(end)+1)]; %
% figure; hist(diffs,bins)
counts = hist(diffs,bins); % how many are there
cz = counts == 0; % remove value index distances that are not present
bins(cz) = [];

for bin = min(bins):2:max(bins)
    i = find(diffs>=bin); % find all key/val combinations this index distance or larger
    DD(tti(i)+2+bin) = D(ti(i)-1+bin/2,2);
    DD(tti(i)+3+bin) = D(ti(i)-1+bin/2,3);
end
idx = isnan(DD);
DD(idx) = [];

% write final time stamp (=file length)
ht = dec2hex(fileLength,6);
FF(1:8) = 255;
FF(end-2) = hex2dec(ht(:,1:2));
FF(end-1) = hex2dec(ht(:,3:4));
FF(end)   = hex2dec(ht(:,5:6));

% write file
fid = fopen(outFile,'w+');
if writeBinary
    fwrite(fid,DD,precision);
    fwrite(fid,FF',precision); % file length
    % write header information to the end of the file
    % e.g., 000B VERNR:2.00;0013 CEUSTYPE:K290S0108;000F CEUSRELNR:2.03;0013 COMBORELNR:2.06.01;001B RECORDDATE:2013-01-04 1551;0018 TITLE:REC026 01-04 1551;
    lotokens = 12; % length of tokens + 12 (see CEUS File Format Manual, Jan 2013)
    for i = 1:length(headertokens)
        if ~isempty(headercontent{i})
            str = sprintf('%s:%s;',headertokens{i},headercontent{i});
            fprintf(fid,'%04X %s',length(str),str);
            lotokens = lotokens + length(str) + 5; % length of string plus 4 plus blank
        end
    end
    tmpstr = dec2hex(lotokens,8);
    LL = zeros(4,1); % length of header tokens in 4 byte HEX (added 1. June 2017)
    LL(1) = hex2dec(tmpstr(1:2));
    LL(2) = hex2dec(tmpstr(3:4));
    LL(3) = hex2dec(tmpstr(5:6));
    LL(4) = hex2dec(tmpstr(7:8));
    fwrite(fid,LL,precision);
    fwrite(fid,FF',precision); % file length again
else
    hx = reshape(dec2hex(DD,2).',length(DD)*2,1).';
    fprintf(fid,'%s',hx);
    fprintf(fid,'FFFFFFFFFF%s',ht); % file length
end
fclose(fid);

fprintf('*\nwriteBoe(%s) needed %s to finish.\n',outFile,datestr(now-startTime,13));
