// Code your design here

module SYNCH_FIFO #(parameter M=3, parameter N=8)
   (interfaces intf);
  
   reg [M:0]wptr, rptr; 
   reg [N-1:0]fifo[(2**M)-1:0];
  
   always @(posedge intf.clk) begin
      if(intf.rst) begin
         foreach(fifo[i]) fifo[i] <= 'h0;
         wptr <= 0;
         rptr <= 0; 
         intf.rdata <= 'h00;
      end
      else begin
         if(intf.full==0 && intf.we==1)begin
            fifo[wptr[M-1:0]] <= intf.wdata;
            wptr <= wptr+1;       
         end
         if(intf.empty==0 && intf.re==1)begin
            intf.rdata <= fifo[rptr[M-1:0]];
            rptr <= rptr+1;       
         end
      end
   end
  
   assign intf.full = intf.rst?0:(wptr[M] != rptr[M] && (wptr[M-1:0] == rptr[M-1:0]))?1:0;
   assign intf.empty = (intf.rst || (wptr==rptr))?1:0;
endmodule
   
 


         