function tx_11a = tx_func(in_byte,rate,upsample,aim,aim_all)
sim_consts = set_sim_consts;
sim_options.PacketLength=length(in_byte)+4;
sim_options.rate=rate;
sim_options.upsample=upsample;
if sim_options.rate==6;
    sim_options.ConvCodeRate='R1/2';
    sim_options.Modulation='BPSK';
elseif sim_options.rate==9;
    sim_options.ConvCodeRate='R3/4';
    sim_options.Modulation='BPSK';
elseif  sim_options.rate==12;
    sim_options.ConvCodeRate='R1/2';
    sim_options.Modulation='QPSK';
elseif sim_options.rate==18;
    sim_options.ConvCodeRate='R3/4';
    sim_options.Modulation='QPSK';
elseif sim_options.rate==24;
    sim_options.ConvCodeRate='R1/2';
    sim_options.Modulation='16QAM';
elseif  sim_options.rate==36;
    sim_options.ConvCodeRate='R3/4';
    sim_options.Modulation='16QAM';
elseif  sim_options.rate==48;
    sim_options.ConvCodeRate='R2/3';
    sim_options.Modulation='64QAM';
elseif  sim_options.rate==54;
    sim_options.ConvCodeRate='R3/4';
    sim_options.Modulation='64QAM';
end
%% 数据处理
in_byte_col(:,1)=in_byte;
in_bits_1=de2bi(in_byte_col,8);
in_bits_r=in_bits_1(:,8:-1:1);
in_bits_re=in_bits_r.';
in_bits_s=in_bits_re(:);
in_bits(1,:)=in_bits_s;
ret=crc32(in_bits);
inf_bits=[in_bits ret.'];
service=zeros(1,16);
data_bits=tx_generate_data(inf_bits,service,sim_options);
%% 加扰
scramble_int=[1,1,1,1,0,0,0];
scramble_bits=scramble_lc(scramble_int,data_bits,sim_options);
%% 编码
coded_bit_stream = tx_conv_encoder(scramble_bits); 
tx_bits = tx_puncture(coded_bit_stream, sim_options.ConvCodeRate);
rdy_to_mod_bits =tx_bits;
%% 交织
rdy_to_mod_bits = tx_interleaver(rdy_to_mod_bits,sim_options.Modulation);
%% 调制
mod_syms = tx_modulate(rdy_to_mod_bits, sim_options.Modulation);
%% 导频
mod_ofdm_syms = tx_add_pilot_syms(mod_syms);
%% IFFT
time_syms = tx_freqd_to_timed(mod_ofdm_syms,sim_options.upsample);
%% 循环前缀
time_signal = tx_add_cyclic_prefix(time_syms,sim_options.upsample);
%% 同步子
preamble = tx_gen_preamble(sim_options);
%% 信号信息
l_sig=tx_gen_sig(sim_options,aim,aim_all);
%% 组帧
tx_11a=[preamble l_sig time_signal].';
