module lfsr (
	     output [31:0] lfsrVal, // lfsr current value
	     output [7:0]  psrByte, // psuedo random byte
	     input [31:0]  ldVal,   //  load value to LFSR
         input 	   ldLFSR,      // load the LFSR, up to 32 bits
         input 	   step,        // advance the LFSR 
	     input 	   rst,
	     input 	   clk);

reg [31:0] prng_lfsr;

wire new_bit = prng_lfsr[2] ^ prng_lfsr[5] ^ prng_lfsr[6] ^ prng_lfsr[12] ^ prng_lfsr[30];

assign lfsrVal[31:0] = prng_lfsr[31:0];

assign psrByte[7:0] = 8'b00000000;
//prng_lfsr[7:0] ^ prng_lfsr[15:8] ^
//					  prng_lfsr[23:16] ^ {1'b1, prng_lfsr[30:24]};

wire [31:0] prng_lfsr_next = (ldLFSR) ? ldVal[31:0] :
					  (step) ? {prng_lfsr[30:0], new_bit} : prng_lfsr[31:0];

always @(posedge clk or posedge rst)
begin
	if(rst) 
		prng_lfsr <= 32'h00000000;
	else
		prng_lfsr <= prng_lfsr_next;
end


endmodule // lfsr
