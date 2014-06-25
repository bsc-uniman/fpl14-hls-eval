import FIFOF::*;
import Vector::*;
import ConfigReg::*;
import BRAMCore::*;

// 2^19 x 8B = 4 MB (512K buckets)
// 2^18 x 8B = 2 MB (256K buckets)
// 2^17 x 8B = 1 MB (128K buckets)
// 2^16 x 8B = 512 KB (64K buckets)
typedef 16 HTAddrWidth;
typedef Bit#(HTAddrWidth) HTIndex;
typedef 16 HTKeyWidth;
typedef Bit#(HTKeyWidth) HTKey;
typedef Bit#(32) HTData;
typedef Bit#(32) RowData;

typedef TExp#(HTAddrWidth) HTLines;

interface HashProbe;
	method Action put_entry(HTKey key, HTData value, HTIndex index);
	method Action probe(HTKey key, RowData value);
	method ActionValue#(Tuple2#(RowData, HTData)) get_match;
endinterface

interface HTMem;
	method Action read_req(HTIndex addr);
	method ActionValue#(Maybe#(Tuple2#(HTKey, HTData))) read_resp;
	method Action write(HTIndex addr, Tuple2#(HTKey, HTData) value);
endinterface

module mkHTMem(HTMem);
	//RegFile#(HTIndex, Bit#(64)) ht <- mkRegFileFullLoad("ht1.mem");
	BRAM_DUAL_PORT#(HTIndex, Bit#(64)) ht <- mkBRAMCore2(valueOf(HTLines), False);
	
	method Action read_req(HTIndex addr);
		ht.a.put(False, addr, ?);
	endmethod
	method ActionValue#(Maybe#(Tuple2#(HTKey, HTData))) read_resp;
		let v = ht.a.read;
		if ( v[63] == 1'b1 ) begin
			HTKey k = v[47:32];
			HTData d = v[31:0];
			return Valid(tuple2(k, d));
		end else
			return Invalid;
	endmethod
	method Action write(HTIndex addr, Tuple2#(HTKey, HTData) value);
		match {.htk, .htd} = value;
		Bit#(64) v = {1'b1, 15'd0, htk, htd};
		ht.b.put(True, addr, v);
	endmethod
endmodule

(* synthesize *)
module mkHashProbe(HashProbe);
	HTMem ht <- mkHTMem;
	FIFOF#(Tuple3#(HTKey, HTData, HTIndex)) entryQ <- mkLFIFOF;
	FIFOF#(Tuple2#(HTKey, RowData)) rowQ <- mkLFIFOF;
	FIFOF#(Tuple2#(HTKey, RowData)) hashQ <- mkLFIFOF;
	Reg#(HTIndex) currIndexR <- mkRegU;
	PulseWire missW <- mkPulseWire;
	Wire#(Maybe#(HTIndex)) firstReadReqW <- mkDWire(Invalid);
	Wire#(Maybe#(HTIndex)) retryReadReqW <- mkDWire(Invalid);
	Wire#(Maybe#(HTIndex)) newIndexW <- mkDWire(Invalid);
	Wire#(Maybe#(HTIndex)) retryIndexW <- mkDWire(Invalid);
	FIFOF#(Tuple2#(HTData, RowData)) outQ <- mkLFIFOF;
	Vector#(HTKeyWidth, FIFOF#(Tuple3#(HTKey, HTKey, RowData))) lfsrQ <- replicateM(mkLFIFOF);
	let lfsrHeadQ = lfsrQ[0];
	let lfsrTailQ = lfsrQ[valueOf(TSub#(HTKeyWidth, 1))];
	
	rule insert_entry;
		match {.k, .d, .i} = entryQ.first;
		entryQ.deq;
		ht.write(i, tuple2(k, d));
	endrule
	
	rule probe_row ( !missW );
		match {.key, .rdata} = rowQ.first;
		rowQ.deq;
		let h = key;
		lfsrHeadQ.enq(tuple3(h, key, rdata));
	endrule
	
	for (Integer i = 0; i < valueOf(HTKeyWidth) - 1; i = i + 1) begin
		rule lfsr_stage;
			match {.h, .k, .d} = lfsrQ[i].first;
			lfsrQ[i].deq;
			h = {h[14:0], ((h[15] ^ h[13]) ^ h[12]) ^ h[10]};
			lfsrQ[i+1].enq(tuple3(h, k, d));
		endrule
	end
	
	rule ht_first_read;
		match {.h, .k, .d} = lfsrTailQ.first;
		lfsrTailQ.deq;
		h = {h[14:0], ((h[15] ^ h[13]) ^ h[12]) ^ h[10]};
		HTIndex index = truncate(h);
		hashQ.enq(tuple2(k, d));
		newIndexW <= Valid(index);
		firstReadReqW <= Valid(index);
	endrule
	
	rule ht_probe;
		let v <- ht.read_resp;
		if ( isValid(v) ) begin
			let bucket = unJust(v);
			match {.htk, .htd} = bucket;
			match {.k, .d} = hashQ.first;
			if (k != htk) begin
				// Key conflict
				let ni = currIndexR + 1;
				missW.send;
				retryIndexW <= Valid(ni);
				retryReadReqW <= Valid(ni);
			end else begin
				// Key found
				hashQ.deq;
				outQ.enq(tuple2(d, htd));
			end
		end else begin
			// Key not found (empty bucket)
			hashQ.deq;
		end
	endrule
		
	rule update;
		if ( isValid(firstReadReqW) )
			ht.read_req(unJust(firstReadReqW));
		else if ( isValid(retryReadReqW) )
			ht.read_req(unJust(retryReadReqW));
		if ( isValid(newIndexW) )
			currIndexR <= unJust(newIndexW);
		else if ( isValid(retryIndexW) )
			currIndexR <= unJust(retryIndexW);
	endrule
	
	method Action put_entry(HTKey key, HTData value, HTIndex index);
		entryQ.enq(tuple3(key, value, index));
	endmethod
	method Action probe(HTKey key, RowData value) = rowQ.enq(tuple2(key, value));
	method ActionValue#(Tuple2#(RowData, HTData)) get_match;
		outQ.deq;
		return outQ.first;
	endmethod
endmodule

