function [data_rate,data_length,signal_error,aim,aim_all]=rate_length(signal)
signal_error=0;
t=[25:48 1:24];
signal=signal(t);
%% singal
signal_d=signal(1:17);
for i=1:16
	signal_d(i+1)=xor(signal_d(i),signal_d(i+1));
end
%% aim
aim_all_d=signal(25:47);

for i=1:22
	aim_all_d(i+1)=xor(aim_all_d(i),aim_all_d(i+1));
end

%% singal
if(signal_d(17)==signal(18) && signal(5)==0)
  data_length=bin2dec(num2str(signal(17:-1:6)));
  if (signal(1:4)==[1,1,0,1])
      data_rate=6; 
  elseif (signal(1:4)==[1,1,1,1])
      data_rate=9;
  elseif (signal(1:4)==[0,1,0,1])
      data_rate=12;
  elseif (signal(1:4)==[0,1,1,1])
      data_rate=18;
  elseif (signal(1:4)==[1,0,0,1])
      data_rate=24;
  elseif (signal(1:4)==[1,0,1,1])
      data_rate=36;
  elseif (signal(1:4)==[0,0,0,1])
      data_rate=48;
  elseif (signal(1:4)==[0,0,1,1])
      data_rate=54;
  else
      disp('Error data_rate');
      data_rate=6;
      signal_error=1;
  end
else
    disp('Error signal');
    signal_error=1;
    data_rate=6;
    data_length=0;
end
%% aim
if (aim_all_d(23)==signal(48) && signal(36)==0)
    aim=bin2dec(num2str(signal(35:-1:25)));
    aim_all=bin2dec(num2str(signal(47:-1:37)));
else
    disp('Error aim');
    aim=-1;
    aim_all=-1;
    signal_error=1;
end