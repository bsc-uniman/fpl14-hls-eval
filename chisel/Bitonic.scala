package Bitonic

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

class CAE(val k:Int, d:Int) extends Module {
  val io = new Bundle {
    val ain = SortData(INPUT, k, d)
    val bin = SortData(INPUT, k, d)
    val aout = SortData(OUTPUT, k, d)
    val bout = SortData(OUTPUT, k, d)
  }
  val gt = io.ain.key < io.bin.key
  io.aout := Mux(!gt, io.ain, io.bin)
  io.bout := Mux(gt, io.ain, io.bin)
}

class BitonicIfc(val n:Int, k:Int, d:Int) extends Bundle {
  val in  = Vec.fill(n) { SortData(INPUT, k, d) }
  val out = Vec.fill(n) { SortData(OUTPUT, k, d) }
  val e   = Bool(INPUT)
  val v   = Bool(OUTPUT)
}

class Stage(val n:Int, k:Int, d:Int) extends Module {
  val io = new BitonicIfc(n, k, d)
  val datareg = Vec.fill(n) { Reg( SortData(k, d) ) }
  val vreg = Reg( Bool(false) )
  when ( io.e ) {
    datareg := io.in
  }
  vreg := io.e
  io.out := datareg
  io.v := vreg
}

class SortB(val n:Int, k:Int, d:Int) extends Module {
  val io = new BitonicIfc(n, k, d)
  val stage0 = Module(new Stage(n, k, d))
  for ( i <- 0 until n/4 ) {
    val cae = Module(new CAE(k, d))
    cae.io.ain := io.in(i)
    cae.io.bin := io.in(i+n/4)
    stage0.io.in(i) := cae.io.aout
    stage0.io.in(i+n/4) := cae.io.bout
  }
  for ( i <- n/2 until 3*n/4 ) {
    val cae = Module(new CAE(k, d))
    cae.io.ain := io.in(i)
    cae.io.bin := io.in(i+n/4)
    stage0.io.in(i) := cae.io.aout
    stage0.io.in(i+n/4) := cae.io.bout
  }
  stage0.io.e := io.e
  if (n > 4) {
    val subsorters = Vec.fill(2) { Module(new SortB(n/2, k, d)).io }
    for ( i <- 0 until n/2 ) {
      subsorters(0).in(i) := stage0.io.out(i)
      subsorters(1).in(i) := stage0.io.out(i+n/2)
      io.out(i) := subsorters(0).out(i)
      io.out(i+n/2) := subsorters(1).out(i)
    }
    subsorters(0).e := stage0.io.v
    subsorters(1).e := stage0.io.v
    io.v := subsorters(0).v & subsorters(1).v
  } else {
    io.out := stage0.io.out
    io.v := stage0.io.v
  }
}

class Bitonic(val n:Int, k:Int, d:Int) extends Module {
  val io = new BitonicIfc(n, k, d)
  val inputs0 = Vec.fill(n) { SortData(k, d) }
  val valid0 = Bool()
  // Previous sub bitonics
  if ( n > 2 ) {
    val subu = Vec.fill(2) { Module(new Bitonic(n/2, k, d)).io }
    for (t <- 0 until n/2 ) {
      subu(0).in(t) := io.in(t)
      inputs0(t) := subu(0).out(t)
      subu(1).in(t) := io.in(t+n/2)
      inputs0(t+n/2) := subu(1).out(t)
    }
    subu(0).e := io.e
    subu(1).e := io.e
    valid0 := subu(0).v & subu(1).v
  } else {
    inputs0 := io.in
    valid0 := io.e
  }
  // Sort A
  val stage1 = Module(new Stage(n, k, d))
  for (t <- 0 until n/2) {
    val cae = Module(new CAE(k, d))
    cae.io.ain := inputs0(t)
    cae.io.bin := inputs0(n-t-1)
    stage1.io.in(t) := cae.io.aout
    stage1.io.in(n-t-1) := cae.io.bout
  }
  stage1.io.e := valid0
  // Sort B
  if ( n > 2 ) {
    val sortb = Module(new SortB(n, k, d))
    sortb.io.in := stage1.io.out
    sortb.io.e := stage1.io.v
    io.out := sortb.io.out
    io.v := sortb.io.v
  } else {
    io.out := stage1.io.out
    io.v := stage1.io.v
  }
}

class BitonicTests(c: Bitonic, n:Int, k:Int, d:Int) extends Tester(c, Array(c.io)) {
  defTests {
    val rnd  = new Random()
    val vars = new HashMap[Node, Node]()
    val in = Vec.fill(n) { SortData(k, d) }
    val out = Vec.fill(n) { SortData(k, d) }
    vars(c.io.in) = in
    vars(c.io.out) = out
    vars(c.io.e) = Bool(true)
    vars(c.io.v) = Bool(true)
    step(vars)
  }
}

object Bitonic {
	def main(args: Array[String]): Unit = {
    val args = Array("--backend", "v")
    //val args = Array("--backend", "c", "--genHarness", "--compile", "--test")
    chiselMainTest(args, () => Module(new Bitonic(n = 16, k = 32, d = 32))) {
      c => new BitonicTests(c, 16, 32, 32) }
  }
}

