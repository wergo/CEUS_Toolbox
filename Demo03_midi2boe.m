% Read MIDI file with Midi Toolbox
% (https://www.jyu.fi/hytk/fi/laitokset/mutku/en/research/materials/miditoolbox)
% and save as CEUS file.

% import midi data (pedals not imported)
nmat = readmidi('examples/Brahms_Op118-2.boe.mid');

% convert to B structure
B = data2ceus(nmat); 

plotBoe(B)

writeBoe(B,'Brahms_Op118-2.boe.boe', false);


