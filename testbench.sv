////////////////////////////////////////////////////////////////////////////////

//TRANSACTION CLASS

typedef enum {WRITE, READ, WRITE_FASTER, READ_FASTER, WRITE_READ_NOMINAL, WRITE_ONLY, READ_ONLY}T_type;

class transaction #(parameter N=8);
   randc bit [N-1:0]wdata;
   rand bit we, re;
   bit [N-1:0]rdata;
   bit full, empty;
   bit clk, rst;
   rand T_type op_mode;
  
   constraint op_type{if(op_mode == WRITE) {we == 1;}
                      if(op_mode == READ) {re == 1;}
                     
                      if(op_mode == WRITE_FASTER){we dist {1:=90, 0:=20};
                                                  re dist {1:=20, 0:=90};
                                                 }
                      if(op_mode == READ_FASTER){re dist {1:=90, 0:=20};
                                                 we dist {1:=20, 0:=90};
                                                }
                       
                       /*if(op_mode == WRITE_READ_NOMINAL) {we dist {1:=50, 0:=50};
                                                          re dist {1:=50, 0:=50};
                                                         }*/
                       
                      if(op_mode == WRITE_ONLY) {we == 1; re == 0;}
                      if(op_mode == READ_ONLY) {we == 0; re == 1;}
                     };
  
   function void print(string tag=" ");
      $display("T = %0t %s  we = %0h  wdata = %0h  re = %0h  rdata = %0h  full = %0h  empty = %0h", $time, tag, we, wdata, re, rdata, full, empty);
   endfunction
  
   function void pre_randomize(string tag=" ");    //to get coverages comment out the pre randomize and post randomize
      $display("T = %0t pre_randomize %s  we = %0h  wdata = %0h  re = %0h", $time, tag, we, wdata, re);
   endfunction
  
   function void post_randomize(string tag=" ");
      $display("T = %0t post_randomize %s  we = %0h  wdata = %0h  re = %0h", $time, tag, we, wdata, re);
   endfunction
  
endclass

/////////////////////////////////////////////////////////////////////////////

//GENERATOR OR SEQUENCE
 
class generator #(parameter M=3, parameter N=8);
   mailbox #(transaction)drv_mbx;
   event drv_done;
   int num = (2**M);
   transaction item = new();
  
   function build();
      $display("T = %0t [GENERATOR] build method triggered", $time);
      drv_mbx = new();
      $display("T = %0t [GENERATOR] build method exit", $time);
   endfunction
  
   virtual task run();
      $display("T = %0t [GENERATOR] run method triggered", $time);
      for(int i=0; i<num; i++) begin
         item.randomize();
         drv_mbx.put(item);
         @(drv_done);
         $display("T = %0t [GENERATOR] loop : %0d/%0d creat next item \n", $time, i+1, num);
      end
      $display("T = %0t [GENERATOR] DONE! generation of %0d items \n", $time, num);
   endtask
  
endclass

/////////WRITE AFTER READ////////////
class seq_wr_re extends generator;

   task run(); 
      $display("T = %0t [GENERATOR WDATA<100] run method triggered", $time);
      for(int i=0; i<2*num; i++) begin
         item.randomize() with {if(i<num) op_mode == WRITE;
                                else op_mode == READ;
                                wdata inside {[0:100]};
                               };
         drv_mbx.put(item);
         @(drv_done);
         $display("T = %0t [GENERATOR WDATA<100] loop : %0d/%0d creat next item \n", $time, i+1, num);
      end
      $display("T = %0t [GENERATOR WDATA<100] run method exit", $time);
   endtask
  
endclass

///////////WRITE FOLLOWED READ////////////
class seq_w_foll_r extends generator;
  
   task run(); 
      $display("T = %0t [GENERATOR W_R_B2B] run method triggered", $time);
      for(int i=0; i<num; i++) begin
         item.randomize() with {op_mode == WRITE_ONLY;
                                wdata inside {[0:100]};
                               };
         drv_mbx.put(item);
         @(drv_done);
        
         item.randomize() with {op_mode == READ_ONLY;
                                wdata inside {[0:100]};
                               };
         drv_mbx.put(item);
         @(drv_done);
         $display("T = %0t [GENERATOR W_R_B2B] loop : %0d/%0d creat next item \n", $time, i+1, num);
      end
      $display("T = %0t [GENERATOR W_R_B2B] run method exit", $time);     
   endtask
endclass

///////////READ ONLY/////////////////////////
class seq_only_read extends generator;
  
   task run(); 
      $display("T = %0t [GENERATOR READ_ONLY] run method triggered", $time);
      for(int i=0; i<num; i++) begin
         item.randomize() with {op_mode == READ_ONLY;
                                wdata inside {[0:100]};
                               };
         drv_mbx.put(item);
         @(drv_done);
         $display("T = %0t [GENERATOR READ_ONLY] loop : %0d/%0d creat next item \n", $time, i+1, num);
      end
      $display("T = %0t [GENERATOR READ_ONLY] run method exit", $time);     
   endtask
endclass

///////////WRITE ONLY////////////////
class seq_only_write extends generator;

   task run(); 
      $display("T = %0t [GENERATOR WRITE_ONLY] run method triggered", $time);
      for(int i=0; i<num; i++) begin
         item.randomize() with {op_mode == WRITE_ONLY;
                                wdata inside {[0:100]};
                               };
         drv_mbx.put(item);
         @(drv_done);
         $display("T = %0t [GENERATOR WRITE_ONLY] loop : %0d/%0d creat next item \n", $time, i+1, num);
      end
      $display("T = %0t [GENERATOR WRITE_ONLY] run method exit", $time);     
   endtask
endclass

//////////WRITE FAST//////////////////
class seq_write_max extends generator;

   task run(); 
     $display("T = %0t [GENERATOR WRITE_MAX] run method triggered", $time);
     for(int i=0; i<2*num; i++) begin
        item.randomize() with {op_mode == WRITE_FASTER;
                               wdata inside {[0:100]};
                              };
         drv_mbx.put(item);
         @(drv_done);
         $display("T = %0t [GENERATOR WRITE_MAX] loop : %0d/%0d creat next item \n", $time, i+1, num);
      end
      $display("T = %0t [GENERATOR WRITE_MAX] run method exit", $time);     
   endtask
endclass
 
////////////READ FAST/////////////////
class seq_read_max extends generator;

   task run(); 
      $display("T = %0t [GENERATOR READ_MAX] run method triggered", $time);
      for(int i=0; i<2*num; i++) begin
        item.randomize() with {op_mode == READ_FASTER;
                                //wdata inside {[0:100]
                              };
         drv_mbx.put(item);
         @(drv_done);
         $display("T = %0t [GENERATOR READ_MAX] loop : %0d/%0d creat next item \n", $time, i+1, num);
      end
      $display("T = %0t [GENERATOR READ_MAX] run method exit", $time);     
   endtask
endclass
 
////////////FIFO DEPTH/////////////////
class seq_depth_fifo extends generator;
   int que_depth[$];
   task run(); 
      $display("T = %0t [GENERATOR READ_MAX] run method triggered", $time);
      for(int i=0; i<20; i++) begin
         item.randomize() with {op_mode == WRITE;
                                wdata inside {[0:100]};
                               };
         if(i<(2**M)) que_depth.push_back(item.wdata);
         $display("T = %0t FIFO DEPTH = %0d", $time, $size(que_depth));
         drv_mbx.put(item);
         @(drv_done);
         $display("T = %0t [GENERATOR READ_MAX] loop : %0d/%0d creat next item \n", $time, i+1, num);
      end
      $display("T = %0t [GENERATOR READ_MAX] run method exit", $time);     
   endtask
endclass
                      
////////////READ MAX/////////////////
class seq_read_write_nominal extends generator;

   task run(); 
      $display("T = %0t [GENERATOR READ_MAX] run method triggered", $time);
      for(int i=0; i<2*num; i++) begin
         item.randomize() with {op_mode dist{WRITE :=50, READ:=50};
                                wdata inside {[0:100]};
                               };
         drv_mbx.put(item);
         @(drv_done);
         $display("T = %0t [GENERATOR READ_MAX] loop : %0d/%0d creat next item \n", $time, i+1, num);
      end
      $display("T = %0t [GENERATOR READ_MAX] run method exit", $time);     
   endtask
endclass

///////////////////////////////////////////////////////////////////////////

//INTERFACE

interface interfaces #(parameter N=8) (input bit clk);
   logic rst;
   logic we, re;
   logic [N-1:0] wdata;
   logic [N-1:0] rdata;
   logic full, empty;
  
   clocking dut_cb @(posedge clk);
      default input #1 output #2;
      output rst;
      output we, re;
      output wdata;
      input rdata;
      input full, empty;
   endclocking
  
   clocking tb_cb @(posedge clk);
      default input #0 output #0;
      input rst;
      input we, re;
      input wdata;
      input rdata;
      input full, empty;
   endclocking
  
   modport fifo_modport(clocking dut_cb, clocking tb_cb);
   modport fifo_designs_ports(input clk, rst,
                              input we, re,
                              input wdata,
                              output rdata,
                              output full, empty); 
endinterface

//////////////////////////////////////////////////////////////////////////////

//DRIVER OBJECT

class driver;
   virtual interfaces vif;
   event drv_done;
   mailbox #(transaction)drv_mbx;
  
   function void build();
      $display("T = %0t [DRIVER] build method triggered", $time);
      drv_mbx = new();
      $display("T = %0t [DRIVER] build method exit", $time);
   endfunction
  
   task run();
      $display("T = %0t  [DRIVER] run method triggered", $time);
      @(vif.fifo_modport.dut_cb);
      
      forever begin
         transaction item;
         drv_mbx.get(item);
        
         pre_modify_item(item);
         item.print("Driver");
        
         vif.fifo_modport.dut_cb.we <= item.we;
         vif.fifo_modport.dut_cb.re <= item.re;
         vif.fifo_modport.dut_cb.wdata <= item.wdata;
        
         post_display_item(item);
         
         @(vif.fifo_modport.dut_cb);
         ->drv_done;
      end
      $display("T = %0t [DRIVER] run method exit", $time);
   endtask
     
   virtual task pre_modify_item(transaction item);
   endtask
     
   virtual task post_display_item(transaction item);
   endtask

endclass
 
////////////////CALLBACK METHOD TO MODIFY THE DATA////////////////
class modify extends driver;   
  
   task pre_modify_item(transaction item);    
      item.wdata <= item.wdata + 1;
      $display("T = %0t Modified wdata is %d", $time, item.wdata);
   endtask
  
   task post_display_item(transaction item);
      #10;
      $display("T = %0t Modified wdata is %d", $time, item.wdata);
   endtask
  
endclass

  

///////////////////////////////////////////////////////////////////////////////

//MONITOR 

class monitor;
   virtual interfaces vif;
   mailbox #(transaction) scb_mbx;
   mailbox #(transaction) cov_mbx;
   event rst_triggered;
  
   function void build();
      $display("T = %0t [MONITOR] build method triggered", $time);
      scb_mbx = new();
      cov_mbx = new();
      $display("T = %0t [MONITOR] build method exit", $time);
   endfunction
  
  
   task run(string tag = " ");
      $display("T = %0t [MONITOR] sample_port method triggered", $time);
      forever begin
         @(vif.fifo_modport.tb_cb); 
         if(vif.fifo_modport.tb_cb.rst)begin
            ->rst_triggered;     
            $display("T = %0t MONITOR RESET TRIGGERED", $time);
         end
         if(vif.fifo_modport.tb_cb.rst ==0)begin
            transaction item = new();
            
            item.we = vif.fifo_modport.tb_cb.we;
            item.re = vif.fifo_modport.tb_cb.re;
            item.wdata = vif.fifo_modport.tb_cb.wdata;
           
            item.rdata = vif.fifo_modport.tb_cb.rdata;
            item.full = vif.fifo_modport.tb_cb.full;
            item.empty = vif.fifo_modport.tb_cb.empty;
         
            scb_mbx.put(item);
            cov_mbx.put(item);
            item.print({"Monitor_", tag});
         end
      end
      $display("T = %0t [MONITOR]  sample_port method exit \n", $time);
   endtask
  
endclass

////////////////////////////////////////////////////////////////////////////

//SCOREBOARD

/*class scoreboard;
   mailbox #(transaction)scb_mbx;
 
   function build();
      $display("T = %0t  [SCOREBOARD] build method triggered", $time);
      scb_mbx = new();
     $display("T = %0t  [SCOREBOARD] build method exit", $time);
   endfunction
  
   task run();
      $display("T = %0t  [SCOREBOARD] run method triggered", $time);
      forever begin
         transaction item;
         scb_mbx.get(item);
      end
     $display("T = %0t  [SCOREBOARD] run method exit", $time);
   endtask
     
endclass*/
     

class scoreboard #(parameter M=3, parameter N=8, FIFO_DEPTH = 8);
   mailbox #(transaction)scb_mbx;
   event rst_captured;
  
   bit [N-1:0] exp_rdata;
   bit [N-1:0]tb_fifo[$]; 
   bit exp_full, exp_empty;
    
   function void build();
      $display("T = %0t [SCOREBOARD] BUILD method triggered", $time);
      scb_mbx = new();
      $display("T = %0t [SCOREBOARD] BUILD method exit", $time);
   endfunction
  
   task run();
      $display("T = %0t [SCOREBOARD] RUN method triggered",$time);
      forever fork
         begin
            wait(rst_captured.triggered);
            tb_fifo.delete();
            exp_full = 0;
            exp_empty = 1;
            exp_rdata = 0;
            $display("T = %0d RESET CAPTURED tb_fifo = %0p exp_full = %0h exp_empty = %0h, exp_rdata = %0h", $time, tb_fifo, exp_full, exp_empty, exp_rdata);
            #1ns;
         end
         begin
            transaction item;
            scb_mbx.get(item);
            ref_model_update(item);
            if(item.we == 1)write_checker(item);
            if(item.re == 1)read_checker(item);
            full_empty(item);
            full_empty_checker(item);
         end
      join_any
      $display("T = %0t [SCOREBOARD] RUN method exit", $time);     
   endtask
  
  
   function void ref_model_update(transaction item);
      if(item.we == 1 && exp_full == 0)begin
         tb_fifo.push_back(item.wdata);
         $display("T = %0t exp que after pushing %p", $time, tb_fifo);
      end
      if(item.re == 1 && exp_empty == 0)begin
         exp_rdata = tb_fifo.pop_front();
         $display("T = %0t exp que after pop %0p", $time, tb_fifo);
      end
   endfunction
  
   task full_empty(transaction item);
      if(tb_fifo.size() == FIFO_DEPTH) begin
         exp_full = 1;
         $display( "\nT = %0t FULL SHOULD BE full = %0h exp_full = %0h", $time, item.full, exp_full);
      end
      else begin
         exp_full = 0;
         $display("\nT = %0t FULL SHOULD BE  full = %0h exp_full = %0h", $time, item.full, exp_full);
      end
     
      if(tb_fifo.size() == 0) begin
         exp_empty = 1;
         $display( "\nT = %0t EMPTY SHOULD BE empty = %0h exp_empty = %0h", $time, item.empty, exp_empty);
      end
      else begin
         exp_empty = 0;
         $display("\nT = %0t EMPTY SHOULD BE empty = %0h exp_empty = %0h", $time, item.empty, exp_empty);
      end
   endtask
  
   task full_empty_checker(transaction item);
      if(exp_full == item.full)
         $display( "\nT = %0t FULL CHECKER PASS!", $time);
      else
         $error("\nT = %0t FULL CHECKER FAIL!  full = %0h exp_full = %0h", $time, item.full, exp_full);
    
      if(exp_empty == item.empty)
         $display( "\nT = %0t EMPTY CHECKER PASS!", $time);
      else
         $error("\nT = %0t EMPTY CHECKER FAIL!  full = %0h exp_empty = %0h", $time, item.empty, exp_empty);
   endtask
 
  
   task write_checker(transaction item);
      if(tb.u0.wptr[M-1:0] == 0)begin
         if(tb.u0.fifo[FIFO_DEPTH-1] === tb_fifo[tb_fifo.size() - 1]) begin
            $display("\nT = %0t WRITE CHECKER PASS! tb_wdata = %0h dut_wdata = %0h tb.u0.wptr = %0h", $time, tb_fifo[tb_fifo.size()-1], tb.u0.fifo[FIFO_DEPTH-1], tb.u0.wptr);
         end
         else begin
            $error("\nT = %0t WRITE CHECKER FAIL! tb_wdata = %0h dut_wdata = %0h tb.u0.wptr = %0h", $time, tb_fifo[tb_fifo.size()-1], tb.u0.fifo[tb.u0.wptr[M-1:0]-1], tb.u0.wptr);
         end
      end
     
      else begin
         if(tb.u0.fifo[tb.u0.wptr[M-1:0]-1] === tb_fifo[tb_fifo.size() - 1]) begin
            $display("\nT = %0t WRITE CHECKER PASS! tb_wdata = %0h dut_wdata = %0h tb.u0.wptr = %0h", $time, tb_fifo[tb_fifo.size()-1], tb.u0.fifo[tb.u0.wptr[M-1:0]-1], tb.u0.wptr);
         end
         else begin
            $error("\nT = %0t WRITE CHECKER FAIL! tb_wdata = %0h dut_wdata = %0h tb.u0.wptr = %0h", $time, tb_fifo[tb_fifo.size()-1], tb.u0.fifo[tb.u0.wptr[M-1:0]-1], tb.u0.wptr);
         end
      end
   endtask

   task read_checker(transaction item);
      if(item.rdata === exp_rdata)begin
         $display("\nT = %0t READ CHECKER PASS! tb_rdata = %0h dut_rdata = %0h", $time, exp_rdata, item.rdata);
      end
      else begin
         $error("\nT = %0t READ CHECKER FAIL!  tb_rdata = %0h dut_rdata = %0h", $time, exp_rdata, item.rdata);
      end
   endtask
   
endclass

/////////////////////////////////////////////////////////////////////////////////////////////
     
//FUNCTINAL COVERAGE
     
class fun_cov #(parameter M=3, parameter N=8, FIFO_DEPTH = 8);
   mailbox #(transaction)cov_mbx;
   transaction item;
   bit clk;
  
   transaction q1[$];
   transaction q2[$];
   transaction q3[$];
   
   bit unsigned [M:0] wptr_w, rptr_w, wptr_r, rptr_r, wptr_n, rptr_n;
 
   bit write_faster;
   bit read_faster;
   bit write_read_nominal;
  
  
   function void build();
      $display("T = %0t [FUNCTIONAL_COVERAGE] BUILD method triggered", $time);
      cov_mbx = new();
      $display("T = %0t [FUNCTIONAL_COVERAGE] BUILD method exit", $time);
   endfunction
  
   covergroup cg;
      option.goal = 100;
     
      WE : coverpoint item.we iff(!item.rst){bins we1 = {1};}
      RE : coverpoint item.re iff(!item.rst){bins re1 = {1};}
      WDATA : coverpoint item.wdata iff(!item.rst) {wildcard bins wdata_one1 = {8'b1???????};
                                                    wildcard bins wdata_one2 = {8'b?1??????};
                                                    wildcard bins wdata_one3 = {8'b??1?????};
                                                    wildcard bins wdata_one4 = {8'b???1????};
                                                    wildcard bins wdata_one5 = {8'b????1???};
                                                    wildcard bins wdata_one6 = {8'b?????1??};
                                                    wildcard bins wdata_one7 = {8'b??????1?};
                                                    wildcard bins wdata_one8 = {8'b???????1};

                                                    wildcard bins wdata_zero1 = {8'b0???????};
                                                    wildcard bins wdata_zero2 = {8'b?0??????};
                                                    wildcard bins wdata_zero3 = {8'b??0?????};
                                                    wildcard bins wdata_zero4 = {8'b???0????};
                                                    wildcard bins wdata_zero5 = {8'b????0???};
                                                    wildcard bins wdata_zero6 = {8'b?????0??};
                                                    wildcard bins wdata_zero7 = {8'b??????0?};
                                                    wildcard bins wdata_zero8 = {8'b???????0};
                                                   }
     
      RDATA : coverpoint item.rdata iff(!item.rst) {wildcard bins rdata_one1 = {8'b1???????};
                                                    wildcard bins rdata_one2 = {8'b?1??????};
                                                    wildcard bins rdata_one3 = {8'b??1?????};
                                                    wildcard bins rdata_one4 = {8'b???1????};
                                                    wildcard bins rdata_one5 = {8'b????1???};
                                                    wildcard bins rdata_one6 = {8'b?????1??};
                                                    wildcard bins rdata_one7 = {8'b??????1?};
                                                    wildcard bins rdata_one8 = {8'b???????1};

                                                    wildcard bins rdata_zero1 = {8'b0???????};
                                                    wildcard bins rdata_zero2 = {8'b?0??????};
                                                    wildcard bins rdata_zero3 = {8'b??0?????};
                                                    wildcard bins rdata_zero4 = {8'b???0????};
                                                    wildcard bins rdata_zero5 = {8'b????0???};
                                                    wildcard bins rdata_zero6 = {8'b?????0??};
                                                    wildcard bins rdata_zero7 = {8'b??????0?};
                                                    wildcard bins rdata_zero8 = {8'b???????0};
                                                   }
      
      FULL : coverpoint item.full iff(!item.rst){bins full_low = {0};
                                                 bins full_high = {1};
                                 				}
     
      EMPTY : coverpoint item.empty iff(!item.rst){bins empty_low = {0};
                                     			   bins empty_high = {1};
                                    			  }
     
      WRITE_FAST : coverpoint write_faster iff(!item.rst){bins write_faster_high = {1};
                                           				  ignore_bins write_faster_low = {0};
                                          				 }
     
      READ_FAST : coverpoint read_faster iff(!item.rst){bins read_faster_high = {1};
                                        			    ignore_bins read_faster_low = {0};
                                          			   }
     
      WRITE_READ_NOMINAL : coverpoint write_read_nominal iff(!item.rst) {bins write_read_high = {1};
                                         								 ignore_bins write_read_low = {0};
                                          							    }
     
      WRITE_ON_FULL : cross WE, FULL {bins full_high_only = binsof(FULL.full_high);}
      READ_ON_EMPTY : cross RE, EMPTY {bins empty_high_only = binsof(EMPTY.empty_high);}      
   endgroup
 
   function new();
      cg = new();
   endfunction
  
   function void f_write_faster();
     
      foreach(q1[i])begin
         if(q1[i].full==0 && q1[i].we == 1)begin
            wptr_w = wptr_w+1;
            $display("T = %0t wptr_w = %0d", $time, wptr_w);
         end
        
         if(q1[i].empty==0 && q1[i].re == 1)begin
            rptr_w = rptr_w+1;
            $display("T = %0t rptr_w = %0d", $time, rptr_w);
         end
      end
            
      if((wptr_w - rptr_w)>2) begin
         write_faster = 1;
         $display("T = %0t HIT write_faster = %0d wptr_w = %0d rptr_w = %0d", $time, write_faster, wptr_w, rptr_w);
      end
      else begin
         write_faster = 0;
         $display("T = %0t write_faster = %0d wptr_w = %0d rptr_w = %0d", $time, write_faster, wptr_w, rptr_w);
      end
      cg.sample();
      $display("T = %0t WRITE_FAST.coverage = %0.2f %% \n", $time, cg.WRITE_FAST.get_coverage());
     
      q1.delete();  
      wptr_w = 0;
      rptr_w = 0;
      write_faster = 0;
   endfunction
   
   function void f_read_faster();
   
      foreach(q2[i])begin
         if( q2[i].we == 1)begin
            wptr_r = wptr_r+1;
            $display("T = %0t FAST READ FUCNTION wptr_r = %0d", $time, wptr_r);
         end
         if(q2[i].re == 1)begin
            rptr_r = rptr_r+1;
            $display("T = %0t FAST READ FUCNTION rptr_r = %0d", $time, rptr_r);
         end
      end

      if(rptr_r > wptr_r) begin
         read_faster = 1;
         $display("T = %0t HIT read_faster = %0d wptr_r = %0d rptr_r = %0d", $time, read_faster, wptr_r, rptr_r);
      end
      else begin
         read_faster = 0;
         $display("T = %0t read_faster = %0d wptr_r = %0d rptr_r = %0d", $time, read_faster, wptr_r, rptr_r);
      end 
      cg.sample();
      $display("T = %0t READ_FAST.coverage = %0.2f %% \n", $time, cg.READ_FAST.get_coverage());
     
      q2.delete();
      wptr_r = 0;
      rptr_r = 0;
      read_faster = 0;
   endfunction
  
   function void f_write_read_nominal();
     
      foreach(q3[i])begin
         if(q3[i].full==0 && q3[i].we == 1)begin
            wptr_n = wptr_n+1;
            $display("T = %0t wptr_n = %0d", $time, wptr_n);
         end
         if(q3[i].empty==0 && q3[i].re == 1)begin
            rptr_n = rptr_n+1;
            $display("T = %0t rptr_n = %0d", $time, rptr_n);
         end
      end
		
      if(rptr_n == wptr_n) begin
         write_read_nominal = 1;
         $display("T = %0t HIT write_read_nominal = %0d wptr_n = %0d rptr_n = %0d", $time, write_read_nominal, wptr_n, rptr_n);
      end
      else begin
         write_read_nominal = 0;
         $display("T = %0t write_read_nominal = %0d wptr_n = %0d rptr_n = %0d", $time, write_read_nominal, wptr_n, rptr_n);
      end 
      cg.sample();
      $display("T = %0t WRITE_READ_NOMINAL.coverage = %0.2f %% \n", $time, cg.WRITE_READ_NOMINAL.get_coverage());
     
      q3.delete();
      wptr_n = 0;
      rptr_n = 0;
      write_read_nominal = 0;
   endfunction
  
   task run();
      $display("T = %0t [FUNCTIONAL_COVERAGE] RUN method triggered",$time);
      forever begin         
         cov_mbx.get(item);
         q1.push_front(item);
         q2.push_front(item);
         q3.push_front(item);
        
         cg.sample();
         item.print("functional_coverage");
         $display("T = %0t WE.coverage = %0.2f %%", $time, cg.WE.get_coverage());
         $display("T = %0t RE.coverage = %0.2f %%", $time, cg.RE.get_coverage());
         $display("T = %0t WDATA.coverage = %0.2f %%", $time, cg.WDATA.get_coverage());
         $display("T = %0t RDATA.coverage = %0.2f %%", $time, cg.RDATA.get_coverage());
         $display("T = %0t FULL.coverage = %0.2f %%, item.full = %0d", $time, cg.FULL.get_coverage(), item.full);
         $display("T = %0t EMPTY.coverage = %0.2f %%, item.empty = %0d", $time, cg.EMPTY.get_coverage(), item.empty);
         $display("T = %0t WRITE_ON_FULL.coverage = %0.2f %% ", $time, cg.WRITE_ON_FULL.get_coverage());
         $display("T = %0t READ_ON_EMPTY.coverage = %0.2f %% \n", $time, cg.READ_ON_EMPTY.get_coverage());
        
         if(q1.size()>10)begin
            f_write_faster();
         end
        
        if(q2.size()>10)begin
           f_read_faster();
        end
        
        if(q2.size()>8)begin
           f_write_read_nominal();
        end
        $display("T = %0t coverage = %0.2f %% \n", $time, cg.get_coverage());
      end
     
      begin
      $display("T = %0t [FUNCTIONAL_COVERAGE] RUN method exit", $time);
      end
   endtask
  
endclass

///////////////////////////////////////////////////////////////////////////////////

//ENVIRONMENT

class environment;
   driver d0;
   monitor m0;
   generator g0;
   scoreboard s0;
   fun_cov f0;
  
   mailbox #(transaction)drv_mbx;
   mailbox #(transaction)scb_mbx;
   mailbox #(transaction)cov_mbx;
  
   event drv_done;
   event rst_triggered;
   event rst_captured;
   virtual interfaces vif;
  
   function build();
      $display("T = %0t [ENVIRONMENT] build method triggered", $time);
      d0 = new();
      d0.build;     
      m0 = new();
      m0.build;
      g0 = new();
      g0.build;
      s0 = new();
      s0.build;
      f0 = new();
      f0.build;
     
      drv_mbx = new();
      scb_mbx = new(); 
      cov_mbx = new();
      $display("T = %0t [ENVIRONMENT] build method exit", $time);
   endfunction
  
   virtual function void connect();
      $display("T = %0t [ENVIRONMENT] connect method triggered", $time);
   
      d0.drv_mbx = drv_mbx; 
      g0.drv_mbx = drv_mbx;  
      m0.scb_mbx = scb_mbx;  
      s0.scb_mbx = scb_mbx;
      m0.cov_mbx = cov_mbx;  
      f0.cov_mbx = cov_mbx;
     
      d0.drv_done = drv_done;
      g0.drv_done = drv_done;
     
      d0.vif = vif;
      m0.vif = vif;
     
      m0.rst_triggered = rst_captured;
      s0.rst_captured = rst_captured;
      $display("T = %0t [ENVIRONMENT] connect method exit", $time);
   endfunction
   
   virtual task run();
      $display("T = %0t [ENVIRONMENT] run method triggered", $time);
      fork
        d0.run();
        m0.run();
        g0.run();
        s0.run();
        f0.run();
      join_any
      $display("T = %0t [ENVIRONMENT] run method exit", $time);
   endtask
  
endclass

//////////////////////////////////////////////////////////////////////////////////

//TEST

class test;
   environment e0;
   
   virtual function build();
      e0 = new();
      e0.build();
   endfunction
  
   virtual function connect();
      e0.connect();
   endfunction
  
   virtual task run();
      e0.run();
   endtask
  
endclass
     
/////////CALL BACK METHOD//////////
class call_back extends test;
   modify d1;
  
   virtual function build();      
      super.build();
       $display("T = %0t [TEST_CALL_BACK] build method triggered", $time);
      d1 = new();
      $display("T = %0t [TEST_CALL_BACK] build method exit", $time);
   endfunction
  
   virtual function connect();
      $display("T = %0t [TEST_CALL_BACK] connect method triggered", $time);
      e0.d0 = d1;
      e0.connect();
      $display("T = %0t [TEST_CALL_BACK] connect method exit", $time);
   endfunction
  
endclass


///////////WRITE READ////////////
class test1 extends test;
   seq_wr_re g_c1;
  
   function build();      
      super.build();
       $display("T = %0t [TEST_WRITE_READ] build method triggered", $time);
      g_c1 = new();
      $display("T = %0t [TEST_WRITE_READ] build method exit", $time);
   endfunction
  
   virtual function connect();
      $display("T = %0t [TEST_WRITE_READ] connect method triggered", $time);
      e0.g0 = g_c1;
      e0.connect();
      $display("T = %0t [TEST_WRITE_READ] connect method exit", $time);
   endfunction
  
endclass

/////////WRITE READ BACK TO BACK//////////////
class test2 extends test;
   seq_w_foll_r g_c2;
  
   function build();      
      super.build();
      $display("T = %0t [TEST_WRITE_READ_B2B] build method triggered", $time);
      g_c2 = new();
      $display("T = %0t [TEST_WRITE_READ_B2B] build method exit", $time);
   endfunction
  
   virtual function connect();
      $display("T = %0t [TEST_WRITE_READ_B2B] connect method triggered", $time);
      e0.g0 = g_c2;
      e0.connect();
      $display("T = %0t [TEST_WRITE_READ_B2B] connect method exit", $time);
   endfunction
  
endclass

//////////READ ONLY////////////
class test3 extends test;
   seq_only_read g_c3;
  
   function build();      
      super.build();
      $display("T = %0t [TEST_READ_ONLY] build method triggered", $time);
      g_c3 = new();
      $display("T = %0t [TEST_READ_ONLY] build method exit", $time);
   endfunction
  
   virtual function connect();
      $display("T = %0t [TEST_READ_ONLY] connect method triggered", $time);
      e0.g0 = g_c3;
      e0.connect();
      $display("T = %0t [TEST_READ_ONLY] connect method exit", $time);
   endfunction
  
endclass

////////WRITE ONLY////////////////
class test4 extends test;
   seq_only_write g_c4;
  
   function build();      
      super.build();
      $display("T = %0t [TEST_WRITE_ONLY] build method triggered", $time);
      g_c4 = new();
      $display("T = %0t [TEST_WRITE_ONLY] build method exit", $time);
   endfunction
  
   virtual function connect();
      $display("T = %0t [TEST_WRITE_ONLY] connect method triggered", $time);
      e0.g0 = g_c4;
      e0.connect();
      $display("T = %0t [TEST_WRITE_ONLY] connect method exit", $time);
   endfunction
  
endclass
 
//////////WRITE MAX//////////////////
class test5 extends test;
   seq_write_max g_c5;
  
   function build();      
      super.build();
      $display("T = %0t [TEST_WRITE_MAX] build method triggered", $time);
      g_c5 = new();
      $display("T = %0t [TEST_WRITE_MAX] build method exit", $time);
   endfunction
  
   virtual function connect();
      $display("T = %0t [TEST_WRITE_MAX] connect method triggered", $time);
      e0.g0 = g_c5;
      e0.connect();
      $display("T = %0t [TEST_WRITE_MAX] connect method exit", $time);
   endfunction
  
endclass  

/////////READ MAX/////////////////////
class test6 extends test;
   seq_read_max g_c6;
  
   function build();      
      super.build();
      $display("T = %0t [TEST_READ_MAX] build method triggered", $time);
      g_c6 = new();
      $display("T = %0t [TEST_READ_MAX] build method exit", $time);
   endfunction
  
   virtual function connect();
      $display("T = %0t [TEST_READ_MAX] connect method triggered", $time);
      e0.g0 = g_c6;
      e0.connect();
      $display("T = %0t [TEST_READ_MAX] connect method exit", $time);
   endfunction
  
endclass  
     
/////////DEPTH FIFO/////////////////////
class test7 extends test;
   seq_depth_fifo g_c7;
  
   function build();      
      super.build();
      $display("T = %0t [TEST_READ_MAX] build method triggered", $time);
      g_c7 = new();
      $display("T = %0t [TEST_READ_MAX] build method exit", $time);
   endfunction
  
   virtual function connect();
      $display("T = %0t [TEST_READ_MAX] connect method triggered", $time);
      e0.g0 = g_c7;
      e0.connect();
      $display("T = %0t [TEST_READ_MAX] connect method exit", $time);
   endfunction
  
endclass

/////////WRITE READ NOMINAL/////////////////////
class test8 extends test;
   seq_read_write_nominal g_c8;
  
   function build();      
      super.build();
      $display("T = %0t [TEST_READ_MAX] build method triggered", $time);
      g_c8 = new();
      $display("T = %0t [TEST_READ_MAX] build method exit", $time);
   endfunction
  
   virtual function connect();
      $display("T = %0t [TEST_READ_MAX] connect method triggered", $time);
      e0.g0 = g_c8;
      e0.connect();
      $display("T = %0t [TEST_READ_MAX] connect method exit", $time);
   endfunction
  
endclass 
     
     

////////////////////////////////////////////////////////////////////

//TB TOP

module tb;
   bit clk;
   test t0;
   test1 t_c1;
   test2 t_c2;
   test3 t_c3;
   test4 t_c4;
   test5 t_c5;
   test6 t_c6;
   test7 t_c7;
   test8 t_c8;
   call_back c1;
  
   always #10 clk = ~clk;
   
   interfaces intf(clk);
   SYNCH_FIFO u0(intf.fifo_designs_ports);
  
  function initialisation();   //to get coverages comment out the function
      intf.fifo_modport.dut_cb.we <= 0;
      intf.fifo_modport.dut_cb.re <= 0;
      intf.fifo_modport.dut_cb.wdata <= 0;
   endfunction 
  
   task reset_mode();     //to get coverages comment out the below 5 lines
      initialisation();
      intf.fifo_modport.dut_cb.rst <= 1;
      repeat(5) @(intf.fifo_modport.dut_cb);
      intf.fifo_modport.dut_cb.rst <=0;
      repeat(5) @(intf.fifo_modport.dut_cb);
      intf.rst = 1;
      repeat(5) @(posedge clk);
      intf.rst =0;
      repeat(5) @(posedge clk);
   endtask
  
   task execute(); 
      t0.build;
      t0.e0.vif = intf;
      t0.connect();
      t0.run();
   endtask
  
   initial begin
      clk <= 1;
      reset_mode();
     
      t0 = new();
      t_c1 = new();  //WRITE READ
      t_c2 = new();  //WRITE FOLLOWED BY READ
      t_c3 = new();  //READ ONLY
      t_c4 = new();  //WRITE ONLY
      t_c5 = new();  //WRITE FAST
      t_c6 = new();  //READ FAST
      t_c7 = new();  //DEPTH FIFO
      t_c8 = new();  //WRITE READ NOMINAL
      c1 = new();    //CALL BACK
     
      /*t0 = t_c1;
      execute(); 
      reset_mode();*/ 
     
      t0 = t_c2;
      execute(); 
      reset_mode();
     
      /*t0 = t_c3;
      execute(); 
      reset_mode();*/
     
      /*t0 = t_c4;
      execute(); 
      reset_mode();*/ 
     
      /*t0 = t_c5;
      execute(); 
      reset_mode();*/
     
      /*t0 = t_c6;
      execute(); 
     reset_mode();*/
     
      /*t0 = t_c7;
      execute(); 
      reset_mode();*/
     
      /*t0 = t_c8;
      execute(); 
      reset_mode();*/ 
     
      /*t0 = new c1;
      execute(); 
      reset_mode();*/     
     
      #10 $finish;           
   end
  
   initial begin
      $dumpvars;
      $dumpfile ("dump.vcd");
   end 
  
     
   property DUT_RST_CHECK;
      @(posedge clk) (u0.intf.rst == 1)|=> (u0.intf.rdata == 'h0);
   endproperty
     
   ASSERT_DUT_RST_CHECK: assert property(DUT_RST_CHECK) $display("T = %0t TB ASSERTION DUT_RST_CHECK PASSED", $time); else $display("T = %0d TB ASSERTION DUT_RST_CHECK FAILED", $time);
    
endmodule
