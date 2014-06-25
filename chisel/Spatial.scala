package Median

import Chisel._
import scala.collection.mutable.HashMap
import util.Random


object SortData {
  def apply(k:Int, d:Int): SortData = {new SortData(k=k, d=d)}
  def apply(io:IODirection, k:Int, d:Int): SortData = {new SortData(io, k, d)}
}

class SortData(val io:IODirection=null, k:Int, d:Int) extends Bundle {
  val key = UInt(io, width = k)
  val data = UInt(io, width = d)
  override def clone(): this.type = {
    SortData(io, k, d).asInstanceOf[this.type]
  }
}

class SortReg(val k:Int, d:Int) extends Module {
  val io = new Bundle {
    val in = SortData(INPUT, k, d)
    val fin = Bool(INPUT)
    val out = SortData(OUTPUT, k, d)
    val fout = Bool(OUTPUT)
    val e = Bool(INPUT)
    val v = Bool(OUTPUT)
  }
  val value = Reg(SortData(k, d))
  val flush = Reg(Bool(false))
  val valid = Reg(Bool(false))
  
  val valueR = Reg(SortData(k, d))
  val flushR = Reg(Bool(false))
  val validR = Reg(Bool(false))
  
  when ( io.e ) {
    when ( flush ) {
      valueR := value
      flushR := flush
      validR := Bool(true)
      value := io.in
      flush := io.fin
      valid := Bool(true)
    } .elsewhen ( !valid ) {
      // new value
      value := io.in
      flush := io.fin
      valid := Bool(true)
      validR := Bool(false)
    } .elsewhen ( io.in.key < value.key ) {
      valueR := io.in
      flushR := Bool(false)
      validR := Bool(true)
      flush := io.fin
    } .otherwise {
      valueR := value
      flushR := Bool(false)
      validR := Bool(true)
      value := io.in
      flush := io.fin
    }
  } .elsewhen ( valid && flush ) {
    valueR := value
    flushR := flush
    validR := Bool(true)
    valid := Bool(false)
  } .otherwise {
    validR := Bool(false)
  }
  io.out := valueR
  io.fout := flushR
  io.v := validR
}

class Spatial(val n:Int, k:Int, d:Int) extends Module {
  val io = new Bundle {
    val in = SortData(INPUT, k, d)
    val fin = Bool(INPUT)
    val out = SortData(OUTPUT, k, d)
    val fout = Bool(OUTPUT)
    val e = Bool(INPUT)
    val v = Bool(OUTPUT)
  }
  val sortregs = Vec.fill(n) { Module(new SortReg(k, d)).io }
  sortregs(0).in := io.in
  sortregs(0).fin := io.fin
  sortregs(0).e := io.e
  for (i <- 1 until n) {
    sortregs(i).in := sortregs(i-1).out
    sortregs(i).fin := sortregs(i-1).fout
    sortregs(i).e := sortregs(i-1).v
  }
  io.out := sortregs(n-1).out
  io.fout := sortregs(n-1).fout
  io.v := sortregs(n-1).v
}

class SpatialTests(c: Spatial, n:Int, k:Int, d:Int) extends Tester(c, Array(c.io)) {
  defTests {
    val rnd  = new Random()
    val vars = new HashMap[Node, Node]()
    val in = SortData(k, d)
    val median = SortData(k, d)
    vars(c.io.in) = in
    vars(c.io.e) = Bool(true)
    vars(c.io.v) = Bool(true)
    step(vars)
  }
}

object Spatial {
	def main(args: Array[String]): Unit = {
    val args = Array("--backend", "v")
    //val args = Array("--backend", "c", "--genHarness", "--compile", "--test")
    chiselMainTest(args, () => Module(new Spatial(n = 16, k = 32, d = 32))) {
      c => new SpatialTests(c, 16, 32, 32) }
  }
}

