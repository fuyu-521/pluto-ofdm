clc;clear;close all;
addpath receiver_matlab
rx = sdrrx('Pluto','RadioID','usb:0','CenterFrequency',433e6,...
    'BasebandSampleRate',32e6,...
    'OutputDataType','double',...
    'SamplesPerFrame',2e6,'Gain',40);                                
%Pluto反复发送数据
while 1
Rdata = rx();
upsample=2; 
mark_d=0; %成功接收到包的标记
aim_h=1; %希望接受的包号
[data_byte,mark_d]=rx_func(Rdata,upsample,aim_h);
if mark_d %成功接收到包不在进行接收
   break;
end
end
release(rx);

