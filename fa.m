clc;clear;close all;
addpath transmitter_matlab
fid=fopen("D:\����\ofdm_tr\Fa_signal.txt");
file_dat=fread(fid);
file_dat=file_dat';
in_byte=file_dat;
 rate=18;
 upsample=2; 
 aim=1;  %���ı��
 aim_all=100; %�ܰ��ı��
 y=tx_func(in_byte,rate,upsample,aim,aim_all);
 %y=[y;y;y;y;y];
%%
%Pluto ����
Tdata = y;
Tdata=[zeros(length(Tdata),1);Tdata];
tx = sdrtx('Pluto','RadioID','usb:0','CenterFrequency',433e6,...
    'BasebandSampleRate',32e6,...
    'SamplesPerFrame',2e6,'Gain',0);
                         
%Pluto������������
tx.transmitRepeat(Tdata);

%��������
while 1
    tx.transmitRepeat(Tdata);
   pause(5)
end
release(tx);

