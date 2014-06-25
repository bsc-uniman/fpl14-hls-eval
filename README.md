
==============

This sources have been used for the publication in FPL'14:

O. Arcas-Abella et al., "An empirical evaluation of high-level synthesis languages and tools for database acceleration", Field-Programmable Logic and Applications, 2014, Munich.

This is a collaborative work of the Barcelona Supercomputing Center and the University of Manchester.

Algorithms studied:

* Bitonic sorter: a 16-input sorting network.
* Spatial sorter: a 16-input sorting FIFO.
* Median operator: calculates the median using a sliding window of 16 values over the input stream.
* Hash probe: filters the input stream using a hash table (used in hash join operations).

Languages and tools:

* Bluespec SystemVerilog: a rule-based hardware description language.
* Altera OpenCL: converts OpenCL data-flow kernels to hardware.
* LegUp: a high-level synthesis tool to convert regular C into Verilog.
* Chisel: a high-level hardware description language based on Scala.
