function [out_signal, freq_est] = rx_frequency_sync_long(rxsignal)
D = 64; 
phase = rxsignal(1:64).*conj(rxsignal(65:128));   

phase = sum(phase); 
freq_est = -angle(phase) / (2*D*pi/20000000);
radians_per_sample = 2*pi*freq_est/20000000;

time_base=[0:length(rxsignal)-1].';
correction_signal=exp(-1i*radians_per_sample*time_base).*64;

out_signal = rxsignal.*correction_signal(1:length(rxsignal));