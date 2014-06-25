import Include::*;

import Vector::*;
import FIFOF::*;
import FShow::*;

(* synthesize *)
module mkMedianModule(Median#(VectorWidth, SortData));
	Median#(VectorWidth, SortData) median <- mkMedian;
	return median;
endmodule

module mkMedian(Median#(VectorWidth, SortData)) provisos(Arith#(SortData));
	SortBox#(VectorWidth, SortData) sorter <- mkSorter;
	
	method Action data_in(Vector#(VectorWidth, SortData) datav);
		sorter.data_in(datav);
	endmethod
	
	method ActionValue#(SortData) data_out;
		let vo <- sorter.data_out;
		let a = vo[valueof(VectorWidth) / 2 - 1];
		let b = vo[valueof(VectorWidth) / 2];
		let m = (a + b) >> 1;
		return m;
	endmethod
endmodule

function Action redbox_stage (Vector#(n, Reg#(t)) y,
                              Vector#(n, Reg#(t)) x,
                              Integer blue_ht,
                              Integer red_ht,
                              Bool is_red)
   provisos (Ord#(t));
   action
      for (Integer red_base = 0; red_base < valueOf (n); red_base = red_base + red_ht) begin
         Integer half = red_ht/2;
         for (Integer j = 0; j < half; j = j + 1) begin
            Integer k1 = red_base + j;
            Integer k2 = is_red ? (red_base + j + half) : (red_base + red_ht - j - 1);
            Bool swap = compareData(x[k1], x[k2]);
            y[k1] <= (swap ? x[k2] : x[k1]);
            y[k2] <= (swap ? x[k1] : x[k2]);
         end
      end
   endaction
endfunction

module mkSorter (SortBox#(n,t))
      provisos (Bits#(t, tsz), Ord#(t),
                Log#(n, logn),
                NumAlias#(num_stages, TDiv#(TMul#(logn, TAdd#(1,logn)), 2)),
                Add#(a__, 1, TDiv#(TMul#(logn, TAdd#(1, logn)), 2)));

   Wire#(Bool) dataInW <- mkDWire(False);
   Reg#(Bit#(num_stages)) validReg <- mkReg(zeroExtend(1'b0));
   Vector#(num_stages, Vector#(n, Reg#(t))) regs <- replicateM (replicateM (mkRegU));
   Vector#(n, Reg#(t)) srcW <- replicateM(mkWire);

   rule valid;
      validReg <= (validReg << 1) | zeroExtend(dataInW ? 1'b1 : 1'b0);
   endrule

   rule compute;
      Integer stage = 0;
      for (Integer blue_ht = 2; blue_ht <= valueOf (n); blue_ht = blue_ht * 2)
         for (Integer red_ht = blue_ht; red_ht > 1; red_ht = red_ht / 2) begin
            let src = (stage == 0) ? srcW : regs[stage-1];
            redbox_stage(regs[stage], src, blue_ht, red_ht, red_ht != blue_ht);
            stage = stage + 1;
         end
   endrule

   method Action data_in (Vector#(n, t) vin);
      writeVReg (srcW, vin);
      dataInW <= True;
   endmethod

   method ActionValue#(Vector#(n, t)) data_out if (validReg[valueOf(num_stages)-1] == 1'b1);
      return readVReg (regs[valueOf(num_stages)-1]);
   endmethod
endmodule

