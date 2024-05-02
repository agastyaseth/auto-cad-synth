module mult32(input clk,
	      input rst,
	      input en,
	      input [31:0] a,
	      input [31:0] b,
	      output [31:0] z,
				output output_ready);

reg [49:0] temp_out ;
reg s_a, s_b, s_z;
reg [9:0] e_a, e_b, e_z;
reg [23:0] m_a, m_b, m_z;
reg guard, round, lonz;
//reg [3:0] state;
reg [31:0] Z, temp2;
reg out_ready;
reg [5:0] diff2;
reg [15:0] val16;
reg [7:0] val8;
reg [3:0] val4;

/*
parameter   enable 				= 4'd0,
						unpack        = 4'd1,
            special_cases = 4'd2,
	    			normalize_a   = 4'd3,
            normalize_b   = 4'd4,
						multiply	   = 4'd5,
            normalize_stage_1   = 4'd6,
            normalize_stage_2   = 4'd7,
            rnd	          = 4'd8,
            pack          = 4'd9,
            put_z         = 4'd10;
*/
always@(posedge clk)
begin

	if(rst == 1)
	begin
		Z = 32'd0;
		out_ready = 0;
	end
	else if(en == 0)
	begin
		out_ready = 0;
	end
	else if(en == 1)
	begin 

		s_a = a[31];
		s_b = b[31];
		e_a = a[30:23] - 127;
		e_b = b[30:23] - 127;
		m_a[22:0] = a[22:0];
		m_b[22:0] = b[22:0];
		m_a[23] = 1;
		m_b[23] = 1;

		//Either a or b is NaN
		if((e_a == 128 && m_a[22:0] != 0) || (e_b == 128 && m_b[22:0] != 0))
		begin
			Z[31] = 1;
			Z[30:23] = 8'hff;
			Z[22] = 1;
			Z[21:0] = 0;
			out_ready = 1;
		end
		//a is Inf
		else if(e_a == 128)
		begin
			//b is 0; Inf * 0 = NaN
			if(($signed(e_b) == -127) && (m_b[22:0] == 0))
			begin
				Z[31] = 1;
				Z[30:23] = 8'hff;
				Z[22] = 1;
				Z[21:0] = 0;
				out_ready = 1;
			end
			//z is Inf
			else
			begin
				Z[31] = s_a ^ s_b;
				Z[30:23] = 8'hff;
				Z[22:0] = 0;
				out_ready = 1;
			end
		end
		//b is Inf
		else if(e_b == 128)
		begin
			//a is 0; Inf * 0 = NaN
			if(($signed(e_a) == -127) && (m_a[22:0] == 0))
			begin
				Z[31] = 1;
				Z[30:23] = 8'hff;
				Z[22] = 1;
				Z[21:0] = 0;
				out_ready = 1;
			end
			//z is Inf
			else
			begin
				Z[31] = s_a ^ s_b;
				Z[30:23] = 8'hff;
				Z[22:0] = 0;
				out_ready = 1;
			end
		end
		//a is 0
		else if($signed(e_a) == -127 && m_a[22:0] == 23'd0)  	
		begin	   
			Z[31] = s_a ^ s_b;
			Z[30:23] = 0;
			Z[22:0] = 0;
			out_ready = 1;
		end
		//b is 0
		else if($signed(e_b) == -127 && m_b[22:0] == 23'd0)	
		begin	   
			Z[31] = s_a ^ s_b;
			Z[30:23] = 0;
			Z[22:0] = 0;
			out_ready = 1;
		end
		
		else
		begin
			s_z = s_a ^ s_b;
			e_z = e_a + e_b + 1;
			temp_out = m_a * m_b * 4;
			m_z = temp_out [49:26];
			guard = temp_out [25];
			round = temp_out [24];
			lonz = (temp_out[23:0] != 0);

			if(m_z[23] == 0)
			begin
				temp2 [23:0] = m_z[23:0];
				temp2 [31:24] = 0;
				if (temp2 == 0)
				begin 
					diff2 = 32;
				end
				else
				begin
			//		diff2[6] = 1'b0;
    			diff2[5] = 1'b0;
    			//val32 = diff2[5] ? temp2[31:0] : temp2[63:32];
  		  	diff2[4] = (temp2[31:16] == 16'b0);
    			val16 = diff2[4] ? temp2[15:0] : temp2[31:16];
    			diff2[3] = (val16[15:8] == 8'b0);
    			val8 = diff2[3] ? val16[7:0] : val16 [15:8];
    			diff2[2] = (val8[7:4] == 4'b0);
    			val4 = diff2[2] ? val8[3:0] : val8[7:4];
    			diff2[1] = (val4[3:2] == 2'b0);
					//val2 = diff2[1] ? val4[1:0] : val4[3:2];
    			diff2[0] = diff2[1] ? ~val4[1] : ~val4[3];
				end
				m_z = m_z << (diff2 - 8);
				e_z = e_z - (diff2 - 8);
			end
	
			if (guard && (round | lonz | m_z[0]))
			begin
				m_z = m_z + 1;
				if(m_z == 24'hffffff)
				begin
					e_z = e_z + 1;
				end
			end

			Z[22:0] = m_z [22:0];
			Z[31:23] = e_z [7:0] + 127;	
			Z[31] = s_z;
			if($signed(e_z) < -126)
			begin
				Z[31:0] = 0; 
			end
			if($signed(e_z) == -126 && m_z[23] == 0)
			begin
				Z[30:23] = 0;
			end	
			if($signed(e_z) > 127)
			begin
				Z[22:0] = 0;
				Z[30:23] = 8'hff;
				Z[31] = s_z;
			end
			out_ready = 1;		
		end
	end
end
assign z = Z;
assign output_ready = out_ready;
endmodule	


  
    
