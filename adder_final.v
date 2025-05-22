`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.01.2025 14:12:44
// Design Name: 
// Module Name: adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module adder(
    input clk,
    input reset,
    input [31:0] a,
    input [31:0] b,
    input available,
    input [4:0] exception_f,
    output [31:0] sum,
    output done
    );
    localparam IDLE = 3'd0,
               INIT = 3'd1,
               EXCEP = 3'd2,
               SHIFT = 3'd3,
               ADD1 = 3'd4,
               ADD2 = 3'd5,
               NORM = 3'd6,
               DONE = 3'd7;
    reg [2:0] state_reg , state_next;
    reg [7:0] exp_a_reg , exp_a_next , exp_b_reg , exp_b_next;
    reg [24:0] mant_a_reg , mant_a_next , mant_b_reg , mant_b_next , cal_mant_reg , cal_mant_next;
    reg [7:0] exp_diff_reg , exp_diff_next;
    reg [22:0] mant_sum_reg , mant_sum_next;
    reg [7:0] exp_sum_reg , exp_sum_next;
    wire exception;
    reg init_flag;
    or or1 (exception,exception_f[0],exception_f[1],exception_f[2],exception_f[3],exception_f[4]);
    always @ (posedge clk or posedge reset) begin
       if(reset) begin
          exp_a_reg <= {8{1'b0}};
          exp_b_reg <= {8{1'b0}};
          mant_a_reg <= {25{1'b0}};
          mant_b_reg <= {25{1'b0}};
       end
       else begin
          exp_a_reg <= exp_a_next;
          exp_b_reg <= exp_b_next;
          mant_a_reg <= mant_a_next;
          mant_b_reg <= mant_b_next; 
       end
    end
    always @ (*) begin
       if(init_flag) begin
          if(a[30:23] > b[30:23]) begin
             exp_a_next = a[30:23];
             exp_b_next = b[30:23];
             mant_a_next = {2'b01,a[22:0]};
             mant_b_next = {2'b01,b[22:0]};
          end
          else if (a[30:23] < b[30:23]) begin
             exp_b_next = a[30:23];
             exp_a_next = b[30:23];
             mant_b_next = {2'b01,a[22:0]};
             mant_a_next = {2'b01,b[22:0]};
          end
          else begin
             if(a[22:0] > b[22:0]) begin
                exp_a_next = a[30:23];
                exp_b_next = b[30:23];
                mant_a_next = {2'b01,a[22:0]};
                mant_b_next = {2'b01,b[22:0]};
             end
             else begin
                exp_b_next = a[30:23];
                exp_a_next = b[30:23];
                mant_b_next = {2'b01,a[22:0]};
                mant_a_next = {2'b01,b[22:0]};
             end
          end
       end
      else begin
          exp_a_next = exp_a_reg;
          exp_b_next = exp_b_reg;
          mant_a_next = mant_a_reg;
          mant_b_next = mant_b_reg;
      end 
    end
    always @ (posedge clk or posedge reset) begin
       if(reset) begin
          state_reg <= IDLE;
          exp_diff_reg <= 8'd0;
          exp_sum_reg <= 8'd0;
          mant_sum_reg <= 23'd0;
          cal_mant_reg <= 25'd0;
       end
       else begin
          state_reg <= state_next;
          exp_diff_reg <= exp_diff_next;
          exp_sum_reg <= exp_sum_next;
          mant_sum_reg <= mant_sum_next;
          cal_mant_reg <= cal_mant_next;
       end
    end
    always @ (*) begin
       case(state_reg)
           IDLE : begin
                     if(available) begin
                        state_next = INIT;
                     end
                     else begin
                        state_next = IDLE;
                     end
                     init_flag = 1'b0;
                     exp_diff_next = exp_diff_reg;
                     exp_sum_next = exp_sum_reg;
                     mant_sum_next = mant_sum_reg;
                     cal_mant_next = cal_mant_reg;
                  end
           INIT : begin
                     init_flag = 1'b1;
                     state_next = EXCEP;
                     exp_diff_next = exp_diff_reg;
                     exp_sum_next = exp_sum_reg;
                     mant_sum_next = mant_sum_reg;
                     cal_mant_next = cal_mant_reg;
                  end 
           EXCEP : begin
                     if(exception) begin
                        state_next = DONE;
                     end
                     else begin
                        state_next = SHIFT;
                     end
                     exp_diff_next = exp_a_reg - exp_b_reg;
                     exp_sum_next = exp_sum_reg;
                     mant_sum_next = mant_sum_reg;
                     cal_mant_next = mant_b_reg;
                     init_flag = 1'b0;
                  end
           SHIFT : begin
                     if(exp_diff_reg >= 23) begin
                        exp_sum_next = exp_a_reg;
                        mant_sum_next = mant_a_reg;
                        state_next = DONE;
                        cal_mant_next = 25'd0;
                        exp_diff_next = 8'd0;
                        init_flag = 1'b0;
                     end
                     else begin
                        if(exp_diff_reg == 0) begin
                           state_next = ADD1;
                           cal_mant_next = cal_mant_reg;
                           exp_diff_next = exp_diff_reg;
                           init_flag = 1'b0;
                           exp_sum_next = exp_sum_reg;
                           mant_sum_next = mant_sum_reg;
                        end
                        else begin
                           cal_mant_next = cal_mant_reg >> 1;
                           exp_diff_next = exp_diff_reg - 1;
                           state_next = SHIFT;
                           exp_sum_next = exp_sum_reg;
                           mant_sum_next = mant_sum_reg;
                           init_flag = 1'b0;
                        end
                     end
                  end 
           ADD1 : begin
                     cal_mant_next = cal_mant_reg + mant_a_reg;
                     init_flag = 1'b0;
                     state_next = ADD2;
                     exp_sum_next = exp_sum_reg;
                     mant_sum_next = mant_sum_reg;
                     exp_diff_next = exp_diff_reg;
                  end
           ADD2 : begin
                     mant_sum_next = cal_mant_reg[24] ? cal_mant_reg[23:1] : cal_mant_reg[22:0];
                     exp_sum_next = cal_mant_reg[24] ? exp_a_reg + 1 : exp_a_reg;
                     cal_mant_next = cal_mant_reg;
                     state_next = DONE;
                     init_flag = 1'b0;
                     exp_diff_next = exp_diff_reg;
                  end
           DONE : begin
                     mant_sum_next = mant_sum_reg;
                     exp_sum_next = exp_sum_reg;
                     cal_mant_next = cal_mant_reg;
                     state_next = IDLE;
                     init_flag = 1'b0;
                     exp_diff_next = exp_diff_reg;
                  end
           default : begin
                         mant_sum_next = mant_sum_reg;
                         exp_sum_next = exp_sum_reg;
                         cal_mant_next = cal_mant_reg;
                         state_next = IDLE;
                         init_flag = 1'b0;
                         exp_diff_next = exp_diff_reg;
                     end                                            
       endcase
    end
    assign sum = {a[31],exp_sum_reg,mant_sum_reg};
    assign done = (state_reg == DONE);                        
endmodule
