function displayBoeHeader(B)
%
%
%
for i = 1:length(B.headercontent)
    fprintf('%11s: %s\n',B.headertokens{i},B.headercontent{i});
end
