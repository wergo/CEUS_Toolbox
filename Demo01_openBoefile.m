% Open example files and plot them
%

% read a Version 1.0 file:
B = readBoe('examples/Brahms_Op118-2.boe');
displayBoeHeader(B); % no header info
plotBoe(B);

% read a Version 2.0 binary file:
B = readBoe('examples/SchumannClara_Romanze-WG-20190911-1.boe', true);
displayBoeHeader(B)
B = findBoeFKB(B); % find kinematic landmarks in key position trajectories
plotBoe(B); % plot B structure. Zoom in to see details.


% cut out part of a file: here we keep section B
BB = cutBoe(B, 122700, 175850, true); % time values in milliseconds
BB = findBoeFKB(BB);
plotBoe(BB);
% write BOE file from BB structure
writeBoe(BB,'test.boe',false)
