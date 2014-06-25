import Include::*;
import Sortable::*;
import SortReg::*;

import Vector :: *;
import Connectable::*;

typedef SortReg#(Packet_in) SorterNode;
interface Sorter;
	method Action flush(Packet_in stream_in);
	method Action _write(Packet_in stream_in);
	method Packet_in _read;
	method Bool flushing;
endinterface

(*synthesize*)
module mkSortRegImpl#(parameter int r_index) (SorterNode);
	SorterNode sort_reg <- mkSortReg(r_index);
	return sort_reg;
endmodule

(*synthesize*)
module mkDoubleSorter(Sorter);
	Sorter sorter0 <- mkSorter;
	Sorter sorter1 <- mkSorter;
	Reg#(Bool) read0 <- mkReg(True);
	Reg#(Bool) write0 <- mkReg(True);
	Wire#(Packet_in) read_value <- mkWire;
	Wire#(Bool) flushing_read <- mkWire;
	
	rule read_from_0 ( read0 );
		let f = sorter0.flushing;
		if ( f )
			read0 <= !read0;
		flushing_read <= f;
		read_value <= sorter0;
	endrule

	rule read_from_1 ( !read0 );
		let f = sorter1.flushing;
		if ( f )
			read0 <= !read0;
		flushing_read <= f;
		read_value <= sorter1;
	endrule

	method Action flush(Packet_in stream_in);
		if ( write0 )
			sorter0.flush(stream_in);
		else
			sorter1.flush(stream_in);
		write0 <= !write0;
	endmethod
	
	method Action _write(Packet_in stream_in);
		if ( write0 )
			sorter0 <= stream_in;
		else
			sorter1 <= stream_in;
	endmethod

	method Packet_in _read;
		return read_value;
	endmethod
	
	method Bool flushing;
		return flushing_read;
	endmethod
endmodule

(*synthesize*)			
module mkSorter(Sorter);
	Vector#(NumNodes, SortReg#(Packet_in)) node;
	Wire#(Packet_in) read_value <- mkWire;
	Wire#(Bool) flushing_read <- mkWire;

	for(Integer i=valueOf(NumNodes)-1; i>=0; i=i-1)
		node[i] <- mkSortRegImpl(fromInteger(i));

	for(Integer i=valueOf(NumNodes)-2; i>=0; i=i-1)
		rule connect;
			node[i+1] <= node[i];
		endrule

	rule read;
		let v = node[(valueof(NumNodes) -1)];
		flushing_read <= isFlushing(v);
		read_value <= fromSortable(v);
	endrule

	method Action flush(Packet_in stream_in);
		node[0] <= toSortable(stream_in, True);
	endmethod
	
	method Action _write(Packet_in stream_in);
		node[0] <= toSortable(stream_in, False);
	endmethod

	method Packet_in _read;
		return read_value;
	endmethod
	
	method Bool flushing;
		return flushing_read;
	endmethod
endmodule

