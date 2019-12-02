function string = t_t(string);
% string = t_t(string) translates a typical file name into
% a Matlab string inserting '\' etc. for special characters
% like '\'; '_'; '^'; '{'; '}'
%
% wg., 21-VIII-2002
whatToChange = '\_^{}';
if nargin < 1
    help t_t
    return
end
for w = 1:length(whatToChange)
    r = findstr(whatToChange(w),string);
    for i = 1:length(r)
        string(r(i)+2:length(string)+1) = string(r(i)+1:end);
        string(r(i):r(i)+1) = strcat('\',whatToChange(w));
        r = r + 1;
    end
end