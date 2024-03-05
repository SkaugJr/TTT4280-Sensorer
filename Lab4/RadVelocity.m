clear mypi;
clear;
mypi=raspi("192.168.86.82","Kollis","646djohr");

nSamples=31250;
channels=2;
nBits=12;
VDD=3.3;
f_radar=24.13*10^9;
c=3*10^8;
N_fft=2^(14);
j=sqrt(-1);
isRunning=true;

while isRunning
system(mypi,'lab1/./adc_sampler nSamples /home/Kollis/lab1/datafiler/SAMPLE.bin','sudo');
getFile(mypi,'/home/Kollis/lab1/datafiler/SAMPLE.bin','C:\Users\skaug\OneDrive\Skole\2024-06-VÅR\TTT4280 - Sensorer og instrumentering\Lab\Lab4 - Radar');
deleteFile(mypi,'/home/Kollis/lab1/datafiler/SAMPLE.bin');

fid=fopen("SAMPLE.bin","rb");
nomPeriod=fread(fid,1,"double");
nomPeriod = nomPeriod * 1e-6;
fs=nSamples/nomPeriod;
data=fread(fid,"uint16");
nSamples=numel(data)/channels; %Antall sampler per ADC
dataMatrix = reshape(data,channels,nSamples); %Matrise med verdiene til ADC-ene i hver rad
fclose(fid);

I=dataMatrix(1,:);
Q=dataMatrix(2,:);

x=I+j*Q;
X=fft(X,N_fft);

f = (0:nSamples-1) * fs / nSamples;
[max_amp, max_idx] = max(abs(X));
f_d = f(max_idx);

v_rad=c*f_d/(2*f_radar);

disp(['Radiell hastighet: ', num2str(v_rad), ' m/s']);

if kbhit
        fprintf('Program avsluttet.\n');
        isRunning = false;
end
end