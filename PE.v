module PE (input [31:0] x, input [31:0] w, input [31:0] acc, output reg [31:0] res, input clk, output reg [31:0] wout);
  
  reg [31:0] S1;
  
  wire [31:0] addout,multout;
  always @(posedge clk) begin
    res <= addout;
   // res <= S1;
    wout <= w;
  end
  
mult32 m1(.clk(clk),.en(1'b1),.rst(1'b0),.a(x),.b(w),.z(multout),.output_ready());
adder32 a1(.clk(clk),.en(1'b1),.rst(1'b0),.a(multout),.b(acc),.z(addout),.output_ready());
endmodule