# CEUS Toolbox for Matlab
This CEUS toolbox provides basic import/export, plotting and manipulation methods in Matlab for Bösendorfers CEUS file format (both version 1.0 and 2.0).

The Bösendorfer CEUS system is an embedded recording and reproducing system built into 
acoustic grand pianos of the Viennese piano manufacturer Bösendorfer. 
One such system is situtated at the Department of Music Acoustics – Wiener Klangstil #
of the University of Music and Performing Arts Vienna: https://iwk.mdw.ac.at/ceus-grandpiano/.

Please see the demo files for exemplary use of this toolbox.

`Demo01_openBoefile.m` opens two boe files, shows header info and plots them.
`Demo02_createBoefile.m` creates a boe file with very fast chromatic scales upwards.
`Demo03_midi2boe.m` opens a Midi file and saves it as boe file 
([MidiToolBox](https://github.com/miditoolbox/) required).

[Werner Goebl](https://iwk.mdw.ac.at/goebl), 26. Nov. 2019