module adder32(input clk,
						 input rst,
						 input en,
						 input [31:0] a,
						 input [31:0] b,
						 output [31:0] z,
						 output output_ready);

reg s_a, s_b, s_z;
reg [9:0] e_a, e_b, e_z, e_min, diff;
reg [26:0] m_a, m_b;
reg [23:0] m_z;
reg [27:0] temp;
reg guard, round, lonz;
//reg diff;
reg [31:0] Z, temp2;
reg out_ready;
reg [5:0] diff2;
//reg [31:0] val32;
reg [15:0] val16;
reg [7:0] val8;
reg [3:0] val4;
//reg [3:0] state;
/*
parameter   enable				= 4'd0,
						unpack        = 4'd1,
            special_cases = 4'd2,
	    			align         = 4'd3,
            add_stage_1   = 4'd4,
            add_stage_2   = 4'd5,
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
		diff = 0;
		diff2 = 0;
		Z = 32'd0;
		out_ready = 0;
		temp = 0;
		//state <= enable;
	end
	else if (en == 0)
	begin
		out_ready = 0;
	end
	else if (en == 1)
	begin
		/*diff = 0;
		temp = 0;
		guard = 0;
		round = 0;
		lonz = 0;
		m_z = 0;
		e_z = 0;
		s_z = 0;
		*/
		s_a = a[31];
		s_b = b[31];
		e_a = a[30:23] - 127;
		e_b = b[30:23] - 127;
		m_a[26] = 1;
		m_b[26] = 1;
		m_a [25:3]= a[22:0];
		m_b [25:3]= b[22:0];
		m_a [2:0] = 3'd0;
		m_b [2:0] = 3'd0;

		//Either a or b is NaN
		if((e_a == 128 && m_a[25:0] != 0) || (e_b == 128 && m_b[25:0] != 0))
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
			//z is Inf
			Z[31] = s_a;
			Z[30:23] = 8'hff;
			Z[22:0] = 0;
			out_ready = 1;
		end
		//b is Inf
		else if(e_b == 128)
		begin
			//z is Inf
			Z[31] = s_b;
			Z[30:23] = 8'hff;
			Z[22:0] = 0;
			out_ready = 1;
		end
		//a and b are 0
		else if(($signed(e_a) == -127 && m_a[25:0] == 0) && ($signed(e_b) == -127 && m_b[25:0] == 0))
		begin	   
			Z[31] = s_a & s_b;
			Z[30:23] = 0;
			Z[22:0] = 0;
			out_ready = 1;
			//state <= put_z;
		end
		//a is 0
		else if($signed(e_a) == -127 && m_a[25:0] == 0) 	
		begin	   
			Z[31] = s_b;
			Z[30:23] = e_b[7:0] + 127;
			Z[22:0] = m_b[25:3];
			out_ready = 1;
			//z[63:0] <= b[63:0];
			//state <= put_z;
		end
		//b is 0
		else if($signed(e_b) == -127 && m_b[25:0] == 0)  	
		begin	   
			Z[31] = s_a;
			Z[30:23] = e_a[7:0] + 127;
			Z[22:0] = m_a[25:3];
			out_ready = 1;
			//state <= put_z;
		end

		//a and b are equal in magnitude but have opposite signs
		else if(($signed(e_a) == $signed(e_b)) && (m_a == m_b) && (s_a != s_b))			
		begin
			Z[31] = 0;
			Z[30:23] = 0;
			Z[22:0] = 0;
			out_ready = 1;
		end

		
		else
		begin
								
			//Align mantissas
			if($signed(e_a) > $signed(e_b))
			begin
				diff = e_a - e_b;
				e_b = e_b + diff;
				m_b = m_b >> diff;
				m_b[0] = m_b[0] | m_b[1];
			end
			
			else if ($signed(e_a) < $signed(e_b))
			begin
				diff = e_b - e_a;
				e_a = e_a + diff;
				m_a = m_a >> diff;
				m_a[0] = m_a[0] | m_a[1];
			end

			e_z = e_a;
			if(s_a == s_b)
			begin
				temp = m_a + m_b;
				s_z = s_a;
			end
			else
			begin
				if(m_a >= m_b)
				begin
					temp = m_a - m_b;
					s_z = s_a;
				end
				else
				begin
					temp = m_b - m_a;
					s_z = s_b;
				end
			end


			if(temp[27] == 1)
			begin
				m_z = temp[27:4];
				e_z = e_z + 1;
				guard = temp[3];
				round = temp[2];
				lonz = temp[1] | temp[0];
			end
			else
			begin
				m_z = temp[26:3];
				guard = temp[2];
				round = temp[1];
				lonz = temp[0];
				//m_z = m_z << 1;
				//e_z = e_z - 1;
				m_z[0] = guard;
			end

			if(m_z [23] == 0)
			begin
				temp2 [23:0] = m_z;
				temp2 [31:24] = 0;
				if (temp2 == 0)
				begin 
					diff2 = 32;
				end
				else
				begin
					//diff2[6] = 1'b0;
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
			//Verify this
			//Round overflow
			if(guard && (round | lonz | m_z[0]))
			begin
				m_z = m_z + 1;
				if(m_z == 24'hffffff)
				begin
					e_z = e_z + 1;
				end
			end

			//Pack Output
			Z[22:0] = m_z [22:0];
			Z[30:23] = e_z[7:0] + 127;	
			Z[31] = s_z;
			if($signed(e_z) < -126)
			begin
				Z[31:0] = 0; 
			end
			if($signed(e_z) == -127 && m_z[23] == 0)
				Z[30:23] = 0;
			if ($signed(e_z) == -127 && m_z[23:0] == 24'h0)
			          Z[31] = 0; // -a + a = +0.
			if($signed(e_z) > 127)
			begin
				Z[22:0] = 0;
				Z[30:23] = 8'hff;
				Z[31] = s_z;
			end
			out_ready = 1;	
		end
		//out_z <= Z;
		//out_ready <= o_r;
	end
end
assign z = Z;
assign output_ready = out_ready;
endmodule
