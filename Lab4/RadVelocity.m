clear mypi;
clear;
mypi=raspi("192.168.86.97","Kollis","646djohr");


channels=2;
nBits=12;
VDD=3.3;
f_radar=24.13*10^9;
c=3*10^8;
N_fft=2^(15);
j=sqrt(-1);

isRunning = true;

while isRunning
system(mypi,'lab4/./radar_sampler 31250 /home/Kollis/lab4/SAMPLE.bin','sudo');
getFile(mypi,'/home/Kollis/lab4/SAMPLE.bin','C:\GitHub\TTT4280-Sensorer\Lab4');
deleteFile(mypi, '/home/Kollis/lab4/SAMPLE.bin');

fid=fopen("SAMPLE.bin","rb");
nomPeriod=fread(fid,1,"double");
nomPeriod = nomPeriod * 1e-6;
data=fread(fid,"uint16");
nSamples=numel(data)/channels; %Antall sampler per ADC
fs=nSamples/nomPeriod;
dataMatrix = reshape(data,channels,nSamples); %Matrise med verdiene til ADC-ene i hver rad
fclose(fid);

I=dataMatrix(1,:)*VDD/(2.^nBits);
Q=dataMatrix(2,:)*VDD/(2.^nBits);

x=I+j*Q;
X=fft(x,N_fft);

f = (0:nSamples-1) * fs / nSamples;
[max_amp, max_idx] = max(abs(X));
f_d = f(max_idx);

v_rad=c*f_d/(2*f_radar);

disp(['Radiell hastighet: ', num2str(v_rad), ' m/s']);
end 