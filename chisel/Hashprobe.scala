package Hashprobe

import Chisel._
import scala.collection.mutable.HashMap
//import util.Random

class Hashprobe(val k:Int, d:Int, htsz:Int) extends Module {
  def lfsr(key:UInt): UInt = Cat(key(14, 0), ((key(15) ^ key(13)) ^ key(12)) ^ key(10))
  def htbits = log2Up(htsz)
  val io = new Bundle {
    // Insert new bucket
    val ht_in_key = UInt(INPUT, width = k)
    val ht_in_data = UInt(INPUT, width = d)
    val ht_in_index = UInt(dir = INPUT, width = htbits)
    val ht_in_en = Bool(INPUT)
    // Probe row
    val row_in_key = UInt(INPUT, width = k)
    val row_in_data = UInt(INPUT, width = d)
    val row_in_en = Bool(INPUT)
    val row_in_rdy = Bool(OUTPUT)
    // Result
    val out_data = UInt(OUTPUT, width = d*2)
    val out_v = Bool(OUTPUT)
  }
  val ht = Mem(UInt(width = 64), htsz)
  val hvec_v = Vec.fill(16){ Reg(init=Bool(false)) }
  val hvec_k = Vec.fill(16){ Reg(UInt(0, width = k)) }
  val hvec_d = Vec.fill(16){ Reg(UInt(0, width = d)) }
  when (io.ht_in_en) {
    ht(io.ht_in_index) := Cat(UInt(1, width=1), UInt(0, width=64-k-d-1), io.ht_in_key, io.ht_in_data)
  }
  hvec_k(0) := lfsr(lfsr(io.row_in_key))
  hvec_v(0) := io.row_in_en
  hvec_d(0) := io.row_in_data
  for (i <- 0 until 15) {
    hvec_k(i+1) := lfsr(hvec_k(i))
    hvec_v(i+1) := hvec_v(i)
    hvec_d(i+1) := hvec_d(i)
  }
  val hash_index = Reg(UInt(width = htbits))
  val hash_v = Reg(Bool(false))
  val hash_k = Reg(UInt(0, width = k))
  val hash_d = Reg(UInt(0, width = d))
  val out_dR = Reg(UInt(0, width = d*2))
  val out_vR = Reg(Bool(false))

  io.out_data := UInt(0, width = d*2)
  io.out_v := Bool(false)
  io.row_in_rdy := Bool(false)
  when ( hash_v ) {
    val bucket = ht(hash_index)
    val b_v = bucket(63)
    val b_k = bucket(k+d-1, d)
    val b_d = bucket(d-1, 0)
    when ( b_v ) {
      when ( b_k === hash_k ) {
        // Found key
        out_dR := Cat(b_d, hash_d)
        out_vR := Bool(true)
        io.row_in_rdy := Bool(true)
      } .otherwise {
        // Search next bucket
        hash_index := hash_index + UInt(1)
      }
    } .otherwise {
      // Key not found
      io.row_in_rdy := Bool(true)
    }
  }
  when (hvec_v(15)) {
    hash_index := hvec_k(15)(htbits - 1, 0)
    hash_k := hvec_k(15)
    hash_d := hvec_d(15)
  }
  hash_v := hvec_v(15)
  io.out_data := out_dR
  io.out_v := out_vR
}

class HashprobeTests(c: Hashprobe, k:Int, d:Int, htsz:Int) extends Tester(c) {
  //val rnd  = new Random()
  val vars = new HashMap[Node, Node]()
  vars(c.io.ht_in_key) = UInt(0, width = k)
  vars(c.io.ht_in_data) = UInt(0, width = d)
  vars(c.io.ht_in_index) = UInt(0, width = log2Up(htsz))
  vars(c.io.ht_in_en) = Bool(false)
  step(1)
}

object Hashprobe {
	def main(args: Array[String]): Unit = {
    val args = Array("--backend", "v")
    //val args = Array("--backend", "c", "--genHarness", "--compile", "--test")
    chiselMainTest(args, () => Module(new Hashprobe(k = 32, d = 32, htsz = 65536))) {
      c => new HashprobeTests(c, 16, 32, 65536) }
  }
}

