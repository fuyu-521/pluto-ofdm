function [data_byte,mark_d] = rx_func(rx_signal_40,upsample,aim_h)
close all;
mark_d=0;
sim_consts = set_sim_consts;
N=0;
viterbi='soft';
%% 下采样
flt1=rcosine(1,upsample,'fir/sqrt',1,64);
rx_signal_40=rcosflt(rx_signal_40,1,1, 'filter', flt1);
rx_signal(:,1)=rx_signal_40(1:upsample:end);

for p=1:2
    tic;
    %% 找包
    [dc_offset,thres_idx] = rx_search_packet_short_fpga3(rx_signal);
    disp(['thres_idx_short=',num2str(thres_idx)]);
    if thres_idx>=length(rx_signal)-32
        break;
    end
    rx_signal_coarse_sync = rx_signal(thres_idx:end)-dc_offset;
    rx_signal_coarse=rx_signal_coarse_sync;
    end_search=length(rx_signal_coarse);
    thres_idx_fine = rx_search_packet_long(end_search,rx_signal_coarse);
    if thres_idx_fine~=end_search
        rx_signal_fine_sync = rx_signal_coarse(thres_idx_fine+32:end);
    else
        rx_signal=rx_signal_coarse(end_search:end);
        disp('short sync error');
        data_byte=0;
        break;
    end

    %% 频率矫正
    [rx_signal_fine] = rx_frequency_sync_long(rx_signal_fine_sync);

    %% FFT
    [freq_tr_syms,  freq_data] = rx_timed_to_freqd(rx_signal_fine);

    %% 信道估计
    channel_est = rx_estimate_channel(freq_tr_syms);
     N=N+1;figure(N)
    plot([zeros(6,1);20*log10(abs(channel_est(1:26)));0;20*log10(abs(channel_est(27:52)));zeros(5,1)]);hold on;
    title('信道估计图');
    channel_est_data=repmat(channel_est,1,size(freq_data,2));
    chan_data=freq_data.*conj(channel_est_data);
    chan_data_amp=abs(channel_est_data(sim_consts.DataSubcPatt,:)).^2;
    chan_data_syms=chan_data(sim_consts.DataSubcPatt,:);
    chan_pilot_syms=chan_data(sim_consts.PilotSubcPatt,:);

    %% 相位矫正
    [correction_phases] = rx_pilot_phase_est1(chan_data_syms,chan_pilot_syms);

    freq_data_syms = chan_data_syms.*exp(-1i.*correction_phases(sim_consts.DataSubcPatt,:));
    %% 获取信号信息

    freq_signal_syms=freq_data_syms(:,1);
    [signal_soft_bits]=rx_demodulate_dynamic_soft(freq_signal_syms,chan_data_amp(:,1),'QPSK');
    signal_deint_bits = rx_deinterleave(signal_soft_bits,'QPSK');
    [signal_depunc_bits,signal_erase] = rx_depuncture(signal_deint_bits,'R1/2');
    t = poly2trellis(7, [133, 171]);
    signal_bits = vitdec( signal_depunc_bits, t, 48, 'term', 'soft',3, ...
        [],signal_erase);
    signal_bits=signal_bits(1:48);
    [data_rate,data_length,signal_error,aim,aim_all]=rate_length(signal_bits);
    if signal_error==1
        index_next=thres_idx+thres_idx_fine+1000;
        rx_signal=rx_signal(index_next:end);
        data_byte=0;
        break;
    end
    sim_options=rx_get_data_parameter(data_rate,data_length);
    ofdm_symbol_num=ceil((16+sim_options.PacketLength.*8+6)/(sim_options.rate*4));

    if ofdm_symbol_num+1>size(correction_phases,2)
        break;
    end

    %% 星座图
    N=N+1;figure(N)
    plot(real(freq_signal_syms)./chan_data_amp(:,1),imag(freq_signal_syms)./chan_data_amp(:,1),'*r');
    title('信号特征补偿后星座图');
    N=N+1;figure(N)
    freq_data_syms_ser=reshape(freq_data_syms(:,2:ofdm_symbol_num+1),48*ofdm_symbol_num,1);
    chan_data_amp_ser=reshape(chan_data_amp(:,2:ofdm_symbol_num+1),48*ofdm_symbol_num,1);
    plot(real(freq_data_syms_ser)./chan_data_amp_ser,imag(freq_data_syms_ser)./chan_data_amp_ser,'.');
    axis([-1.5,1.5,-1.5,1.5]);
    title('信号补偿后星座图');

    %% 接映射
    [data_soft_bits]=rx_demodulate_dynamic_soft ...
        (freq_data_syms_ser,chan_data_amp_ser,sim_options.Modulation);
    %% 解交织 
    data_deint_bits = rx_deinterleave(data_soft_bits,sim_options.Modulation);
    %% 补孔
    [data_depunc_bits,data_erase] = rx_depuncture(data_deint_bits,sim_options.ConvCodeRate);
    %% 解信道编码
    if ~isempty(findstr(viterbi, 'soft'))
        data_descramble_bits = vitdec( data_depunc_bits, t, 48, 'term', 'soft',3, ...
            [],data_erase);
    else
        data_depunc_bits=data_depunc_bits>=4;
        data_descramble_bits = vitdec( data_depunc_bits, t, 48, 'term', 'hard', ...
            [],data_erase);
    end
    %% 解扰吗
    [scramble,data_bits]=rx_descramble(data_descramble_bits);
    %% 得到发送信息
    inf_bits=data_bits(16+1:16+sim_options.PacketLength*8);
    bits=inf_bits(1:length(inf_bits)-32);
    bits_r=reshape(bits,8,length(bits)/8).';
    data_byte=bi2de(bits_r,'left-msb');
    file_name='signal';
    fid=fopen(['received_',char(file_name)],'w');
    file_data=data_byte;
    fwrite(fid,file_data);
    fclose(fid)
    %% 校验
    ret=crc32_new(inf_bits(1:length(inf_bits)-32)).';
    crc_bits=inf_bits(length(inf_bits)-31:length(inf_bits));
    crc_outputs=sum(xor(ret,crc_bits),2);
    if crc_outputs==0
        crc_ok='YES';
        if aim_h==aim
            disp(['已接受']);
            mark_d=1;
        end  
    else
        crc_ok='NO';

    end
    disp(['crc32=',crc_ok]);

    %% calculate next frame
    index_next=thres_idx+thres_idx_fine+160+80*(ofdm_symbol_num+1);
    if length(rx_signal)-index_next>1000
        rx_signal=rx_signal(index_next:end);
    else
        break;
    end 
    pause(0.2);
    break;
end