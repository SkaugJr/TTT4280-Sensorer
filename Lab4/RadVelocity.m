clear mypi;
clear;
mypi=raspi("192.168.86.100","Kollis","646djohr");


channels=2;
nBits=12;
VDD=3.3;
f_radar=24.13*10^9;
c=3*10^8;
N_fft=2^(14);
j=sqrt(-1);

while true

system(mypi,'lab4/./radar_sampler 31250 /home/Kollis/lab4/SAMPLE.bin','sudo');
getFile(mypi,'/home/Kollis/lab4/SAMPLE.bin','C:\GitHub\TTT4280-Sensorer\Lab4');
deleteFile(mypi, '/home/Kollis/lab4/SAMPLE.bin');

fid=fopen("SAMPLE.bin","rb");
nomPeriod=fread(fid,1,"double");
nomPeriod = nomPeriod * 1e-6;
data=fread(fid,"uint16");
nSamples=numel(data)/channels; 
fs=1/nomPeriod;
dataMatrix = reshape(data,channels,nSamples);
fclose(fid);

h=transpose(hann(nSamples-1));
I=(dataMatrix(1,2:end))*VDD/(2.^nBits);
Q=(dataMatrix(2,2:end))*VDD/(2.^nBits);
I=I-mean(I);
Q=Q-mean(Q);

x=h.*(I+j*Q);
X=abs(fftshift(fft(x,N_fft)));
f=1/(N_fft*nomPeriod)*(-N_fft/2:N_fft/2-1);

[max_amp, max_idx] = max(X);
f_d = f(max_idx);

if(abs(f_d)<10)
    v_rad=0;
else
    v_rad=c*f_d/(2*f_radar); 
end

disp(['Radiell hastighet: ', num2str(v_rad), ' m/s']);

end 