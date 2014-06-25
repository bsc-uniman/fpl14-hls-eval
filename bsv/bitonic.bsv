import Vector::*;
import Include::*;

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

(*synthesize*)
module mkBitonicSorter(SortBox#(VectorWidth, SortData));
	SortBox#(VectorWidth, SortData) sorter <- mkSorter;
	return sorter;
endmodule

module mkSorter (SortBox#(n,t))
      provisos (Bits#(t, tsz), Ord#(t),
                Log#(n, logn),
                NumAlias#(num_stages, TDiv#(TMul#(logn, TAdd#(1,logn)), 2)),
                Add#(a__, 1, TDiv#(TMul#(logn, TAdd#(1, logn)), 2)));

   Wire#(Bool) dataInW <- mkDWire(False);
   Reg#(Bit#(num_stages)) validReg <- mkReg(zeroExtend(1'b0));
   Vector#(num_stages, Vector#(n, Reg#(t))) regs <- replicateM (replicateM (mkRegU));
   Vector#(n, Reg#(t)) destW <- replicateM(mkWire);
   Wire#(Bit#(1)) validW <- mkWire;

   rule valid;
      validReg <= (validReg << 1) | zeroExtend(dataInW ? 1'b1 : 1'b0);
      validW <= validReg[valueOf(num_stages)-1];
   endrule

   rule compute;
      Integer stage = 0;
      for (Integer blue_ht = 2; blue_ht <= valueOf (n); blue_ht = blue_ht * 2)
         for (Integer red_ht = blue_ht; red_ht > 1; red_ht = red_ht / 2) begin
            let dest = (stage+1 < valueOf(num_stages)) ? regs[stage+1] : destW;
            redbox_stage (dest, regs[stage], blue_ht, red_ht, red_ht != blue_ht);
            stage = stage + 1;
         end
   endrule

   method Action data_in (Vector#(n, t) vin);
      writeVReg (regs[0], vin);
      dataInW <= True;
   endmethod

   method ActionValue#(Vector#(n, t)) data_out if (validW == 1'b1);
      return readVReg (destW);
   endmethod
endmodule

