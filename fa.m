clc;clear;close all;
addpath transmitter_matlab
fid=fopen("D:\桌面\ofdm_tr\Fa_signal.txt");
file_dat=fread(fid);
file_dat=file_dat';
in_byte=file_dat;
 rate=18;
 upsample=2; 
 aim=1;  %包的标记
 aim_all=100; %总包的标记
 y=tx_func(in_byte,rate,upsample,aim,aim_all);
 %y=[y;y;y;y;y];
%%
%Pluto 发送
Tdata = y;
Tdata=[zeros(length(Tdata),1);Tdata];
tx = sdrtx('Pluto','RadioID','usb:0','CenterFrequency',433e6,...
    'BasebandSampleRate',32e6,...
    'SamplesPerFrame',2e6,'Gain',0);
                         
%Pluto反复发送数据
tx.transmitRepeat(Tdata);

%接收数据
while 1
    tx.transmitRepeat(Tdata);
   pause(5)
end
release(tx);

