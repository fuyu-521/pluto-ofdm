clc;clear;close all;
addpath receiver_matlab
rx = sdrrx('Pluto','RadioID','usb:0','CenterFrequency',433e6,...
    'BasebandSampleRate',32e6,...
    'OutputDataType','double',...
    'SamplesPerFrame',2e6,'Gain',40);                                
%Pluto������������
while 1
Rdata = rx();
upsample=2; 
mark_d=0; %�ɹ����յ����ı��
aim_h=1; %ϣ�����ܵİ���
[data_byte,mark_d]=rx_func(Rdata,upsample,aim_h);
if mark_d %�ɹ����յ������ڽ��н���
   break;
end
end
release(rx);

