module Lab4_140L (
		  input wire   rst, // reset signal (active high)
		  input wire   clk,
		  input        bu_rx_data_rdy, // data from the uart is ready
		  input [7:0]  bu_rx_data, // data from the uart
		  output       L4_tx_data_rdy, // data ready to be sent to UART
		  output [7:0] L4_tx_data, // data to be sent to UART
		  output       L4_PrintBuf,
		  output [4:0] L4_led
		  );

   wire 	   sccDecrypt;    // processing a decrypt command
   wire 	   sccEncrypt;    // processing an encrypt command
   wire            sccEldByte;    // load a byte to encrypt
   wire            sccEmsBitsLd;  // load the msbits of the newly decrypted data
   wire            sccElsBitsLd;  // load the lsbits of the newly decrypted data
   wire 	   sccEmsBitsSl;  // select the ms bits of newly decrypted data
   wire 	   sccDnibble1En; // enable capture of the ms bits of encrypted data
   wire 	   sccDnibble2En; // enable capture of the ls bits of encrypted data
   wire 	   sccDByteValid; // decrypted byte is valid *not used*
   wire [7:0]      sccLdKey;      // load one of 8 key 4-bit registers
   wire 	   sccLdLFSR;     // load the LFSR from the key regsiter 
   wire 	   scdCharIsValid; // bu_rx_data is a printable character
   
   scdp scdp (
	      .L4_tx_data(L4_tx_data),
	      .scdCharIsValid(scdCharIsValid),
	      .bu_rx_data(bu_rx_data),
	      .bu_rx_data_rdy(bu_rx_data_rdy),
	      .sccEncrypt(sccEncrypt),
	      .sccEldByte(sccEldByte),
	      .sccEmsBitsLd(sccEmsBitsLd),
	      .sccElsBitsLd(sccElsBitsLd),
	      .sccEmsBitsSl(sccEmsBitsSl),
	      .sccDecrypt(sccDecrypt),
	      .sccDnibble1En(sccDnibble1En),
	      .sccDnibble2En(sccDnibble2En),

	      .sccLdKey(sccLdKey),
	      .sccLdLFSR(sccLdLFSR),

	      .rst(rst),
	      .clk(clk)
	      );
   


   wire 	   de_validAscii;
   wire 	   de_bigD;
   wire 	   de_bigE;
   wire 	   de_bigL;
   wire 	   de_bigP;
   wire 	   de_bigS;
   wire 	   de_hex;
   wire 	   de_cr;

   decodeKeysL4 dk (
		    .de_esc(),
		    .de_validAscii(de_validAscii),
		    .de_bigD(de_bigD),
		    .de_bigE(de_bigE),
		    .de_bigL(de_bigL),
		    .de_bigP(de_bigP),
		    .de_bigS(de_bigS),
		    .de_hex(de_hex),
		    .de_cr(de_cr),
		    .charData(bu_rx_data),
		    .charDataValid(bu_rx_data_rdy));

   scctrl scctrl (
			.sccEncrypt(sccEncrypt),
			.sccEldByte(sccEldByte),
			.sccEmsBitsLd(sccEmsBitsLd),
			.sccElsBitsLd(sccElsBitsLd),
			.sccEmsBitsSl(sccEmsBitsSl),
			.sccDecrypt(sccDecrypt),
			.sccDnibble1En(sccDnibble1En),
			.sccDnibble2En(sccDnibble2En),
			.sccLdKey(sccLdKey),
			.sccLdLFSR(sccLdLFSR),
			
			.bu_rx_data(bu_rx_data),
			.bu_rx_data_rdy(bu_rx_data_rdy),
			.scdCharIsValid(scdCharIsValid),

			.de_validAscii(de_validAscii),
			.de_bigD(de_bigD),
			.de_bigE(de_bigE),
			.de_bigL(de_bigL),
			.de_bigP(de_bigP),
			.de_bigS(de_bigS),
			.de_hex(de_hex),
			.de_cr(de_cr),

			.L4_PrintBuf(L4_PrintBuf),
			.L4_led(L4_led),
		
			.rst(rst),
			.clk(clk));



endmodule

//
// scdp - stream cipher datapath
// refer to lab instructions for a block diagram
//
//
module scdp (
	     output [7:0] L4_tx_data,   //     data to be sent to uartTxBuf
	     output wire  scdCharIsValid, // encrypt byte is a valid character

	     input [7:0]  bu_rx_data,   // data from the uart
	     input 	  bu_rx_data_rdy, // data from the uart is valid this cycle 
	     input 	  sccEncrypt,   //     control signal indicating we are in encrypt mode
	     input 	  sccEldByte,   // control signal to load bu_rx_data into encrypt register
	     input 	  sccEmsBitsLd, // load the most significant 4 bits of encrypted data
	                                // as an 8-bit ascii hex number
	     input 	  sccElsBitsLd, // load the least significant 4 bits of encrypted data
	                                  // as an 8-bit ascii hex number
	     input 	  sccEmsBitsSl, // select the hex number for the most significant 4 bits
	                                  // of encrypted data to L4_tx_data
	     input 	  sccDecrypt, // we are in decrypt mode
	     input 	  sccDnibble1En, // load 4 bits of encrypted data (most significant)
	     input 	  sccDnibble2En, // load 4 bits of encryhptd data (least significant)
	     
	     input [7:0]  sccLdKey,      // load 4-bit (nibble) of the key
	     input 	  sccLdLFSR,     // load the LFSR from the key

	     input 	  rst,
	     input 	  clk
	     );


   
   wire [3:0] 		  binVal;               // conversion of ascii hex to bin

   wire [7:0] 		  psrByte;  // pseudo random byte


   asciiHex2Bin a2b (.val(binVal), .inVal(bu_rx_data));
   
   
   //
   // decrypt datapath
   //
   wire [7:0] 		  byteToDecrypt;        // byte we are decrypting
   regrce #(4) u0 (byteToDecrypt[7:4], binVal, sccDnibble1En, rst, clk);
   regrce #(4) u1 (byteToDecrypt[3:0], binVal, sccDnibble2En, rst, clk);
    
   wire [7:0] 		  e2dData;
   wire [7:0] 		  pCharDecrypt;   // printable char
   assign e2dData = byteToDecrypt ^ psrByte;
   printable pinst0 (.pChar(pCharDecrypt), .pValid(), .inByte(e2dData));

   

   //
   // encrypt data path
   //
   wire [7:0]		  byteToEncrypt;        // byte we are encrypting
   regrce #(8) u2 (byteToEncrypt, bu_rx_data, sccEldByte, rst, clk);
   
   printable pinst1 (.pChar(), .pValid(scdCharIsValid), .inByte(bu_rx_data));

   
   wire [7:0] 		  d2eData;
   
   assign d2eData = byteToEncrypt ^ psrByte;
   

   //
   // we are encrypting, convert 
   // to two hex digits
   // will send the digits over two cycles.  MS nibble followed by LS nibble.
   //
   wire [7:0] 		  msBitsD, msBits;
   wire [7:0] 		  lsBitsD, lsBits;
   
   bin2AsciiHex b2a0 (msBits, d2eData[7:4]);
   bin2AsciiHex b2a1 (lsBits, d2eData[3:0]);
   
   regrce #(8) msBitsi (msBitsD, msBits, sccEmsBitsLd, rst, clk);
   regrce #(8) lsBitsi (lsBitsD, lsBits, sccElsBitsLd, rst, clk);

   wire [7:0] 		  key0;// bits 7-0
   wire [7:0] 		  key1;// bits 15-8
   wire [7:0] 		  key2;// bits 23-16
   wire [7:0] 		  key3;// bits 31-24

   wire [3:0] 		 binValD;   // bu_rx_data delayed
   wire                  binVal_ValidD;
   regrce #(4) rxdataD (.q(binValD),
			.d(binVal),
			.ce(1'b1), .rst(rst), .clk(clk));
   regrce #(1) rddataDV (.q(binVal_ValidD), .d(bu_rx_data_rdy),
			 .ce(1'b1), .rst(rst), .clk(clk));
   
   regrce #(4) k0l (.q(key0[3:0]), .d(binValD),
		    .ce(sccLdKey[0] & binVal_ValidD),
		   .rst(rst), .clk(clk));
   regrce #(4) k0h (.q(key0[7:4]), .d(binValD),
		    .ce(sccLdKey[1] & binVal_ValidD),
		   .rst(rst), .clk(clk));
   regrce #(4) k1l (.q(key1[3:0]), .d(binValD),
		    .ce(sccLdKey[2] & binVal_ValidD),
		   .rst(rst), .clk(clk));
   regrce #(4) k1h (.q(key1[7:4]), .d(binValD),
		    .ce(sccLdKey[3] & binVal_ValidD),
		   .rst(rst), .clk(clk));
   regrce #(4) k2l (.q(key2[3:0]), .d(binValD),
		    .ce(sccLdKey[4] & binVal_ValidD),
		   .rst(rst), .clk(clk));
   regrce #(4) k2h (.q(key2[7:4]), .d(binValD),
		    .ce(sccLdKey[5] & binVal_ValidD),
		   .rst(rst), .clk(clk));
   regrce #(4) k3l (.q(key3[3:0]), .d(binValD),
		    .ce(sccLdKey[6] & binVal_ValidD),
		   .rst(rst), .clk(clk));
   regrce #(4) k3h (.q(key3[7:4]), .d(binValD),
		    .ce(sccLdKey[7] & binVal_ValidD),
		   .rst(rst), .clk(clk));


   wire [31:0] 		 lfsrVal;
   lfsr lfsrInst (
		  .lfsrVal(lfsrVal),
		  .psrByte(psrByte),
		  .ldVal({key3, key2, key1, key0}),
		  .ldLFSR(sccLdLFSR),
		  .step(sccDnibble2En | sccEldByte),
		  .rst(rst),
		  .clk(clk)
		  );
   

      
   assign L4_tx_data = sccEncrypt ?
		       (sccEmsBitsSl ? msBitsD : lsBitsD ) :
		       pCharDecrypt;
   
endmodule // scdp


//
// scctrl - stream cipher control
//
module scctrl (
		 output sccEncrypt,
		 output sccEldByte,
		 output sccEmsBitsLd,
		 output sccElsBitsLd,
		 output sccEmsBitsSl,
		 output sccDecrypt,
		 output sccDnibble1En,
		 output sccDnibble2En,
		 output [7:0] sccLdKey,
		 output sccLdLFSR,
		
		 //output [7:0] L4_tx_data,
		 //output L4_tx_data_rdy,
		 input [7:0] bu_rx_data,
		 input bu_rx_data_rdy,
		 input scdCharIsValid,

		 input de_validAscii,
		 input de_bigD,
		 input de_bigE,
		 input de_bigL,
		 input de_bigP,
		 input de_bigS,
		 input de_hex,
		 input de_cr,

		 output L4_PrintBuf,
		 output [4:0] L4_led,
	
		 input rst,
		 input clk    
		 );


reg [3:0] state;
//idle start
//encrypt read encrypt input
//decrypt encrypt and output
parameter idle = 0, encrypt = 1, decrypt = 2, load = 3, load1 = 4, load2 = 5, 
		  load3 = 6, load4 = 7, load5 = 8, load6 = 9, load7 = 10, load8 = 11;

assign sccEncrypt = (state == encrypt);
assign sccEldByte = (sccEncrypt & scdCharIsValid & bu_rx_data_rdy);
assign sccEmsBitsLd = sccEldByte;
assign sccElsBitsLd = sccEldByte;

reg EmsBitsSl;
assign sccEmsBitsSl = EmsBitsSl; 

always @(posedge clk) begin
	if(rst)
		EmsBitsSl = 1'b1;
	else
		EmsBitsSl = ~EmsBitsSl;
end


assign L4_led[0] = (state == (encrypt || decrypt || load));
assign L4_led[1] = (state == (encrypt || decrypt));
assign L4_led[2] = (state == load);
assign L4_led[3] = 1'b0;
assign L4_led[4] = (state == idle);

assign L4_PrintBuf = de_cr; 


always @(bu_rx_data_rdy or rst) begin
	if(rst) begin
		state <= idle;
	end
	else begin
		case(state)
			idle:begin
				if(de_bigE)
					state <= encrypt;
				else if(de_bigD)
					state <= decrypt;
				else if(de_bigL)
					state <= load;
				else
					state <= idle;
			end
			encrypt:begin
				if(de_cr)
					state <= idle;
				else
					state <= encrypt;
			end
			decrypt:begin
				if(de_cr)
					state <= idle;
				else
					state <= decrypt;
			end
			load:begin
				if(de_hex)
					state <= load2;
				else
					state <= load;
			end
			load2:begin
				if(de_hex)
					state <= load3;
				else
					state <= load2;
			end
			load3:begin
				if(de_hex)
					state <= load4;
				else
					state <= load3;
			end
			load4:begin
				if(de_hex)
					state <= load5;
				else
					state <= load4;
			end
			load5:begin
				if(de_hex)
					state <= load6;
				else
					state <= load5;
			end
			load6:begin
				if(de_hex)
					state <= load7;
				else
					state <= load6;
			end
			load7:begin
				if(de_hex)
					state <= load8;
				else
					state <= load7;
			end
			load8:begin
				if(de_cr)
					state <= idle;
				else
					state <= load8;
			end
		endcase
	end
end
wire delay1, delay2, delay3, delay4;
regrce r1 (.q(delay1), .d(sccEldByte), .ce(1'b1), .rst(rst), .clk(clk));
regrce r2 (.q(delay2), .d(delay1), .ce(1'b1), .rst(rst), .clk(clk));
regrce r3 (.q(delay3), .d(delay2), .ce(1'b1), .rst(rst), .clk(clk));
//regrce r4 (.q(delay4), .d(delay3), .ce(1'b1), .rst(rst), .clk(clk));

endmodule // scctrl