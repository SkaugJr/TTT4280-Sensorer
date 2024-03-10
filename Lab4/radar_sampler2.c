/*
radar_sampler.c

Compile with:
gcc -o radar_sampler2 radar_sampler2.c -lpigpio -lrt -lm -lfftw3

Run with:
sudo ./radar_sampler2 TIME 

This code bit bangs SPI on several devices using DMA.

Using DMA to bit bang allows for two advantages
1) the time of the SPI transaction can be guaranteed to within a
   microsecond or so.

2) multiple devices of the same type can be read or written
   simultaneously.

This code reads several MCP3201 ADCs in parallel, and writes the data to a binary file.
Each MCP3201 shares the SPI clock and slave select lines but has
a unique MISO line. The MOSI line is not in use, since the MCP3201 is single
channel ADC without need for any input to initiate sampling.
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pigpio.h>
#include <math.h>
#include <time.h>
#include <fftw3.h>

#define ADCS 2      // Number of connected MCP3201.
#define MISO1 23    // ADC 1 MISO (GPIO pin number)
#define MISO2 24    // ADC 2 MISO (GPIO pin number)
#define MOSI 10     // GPIO for SPI MOSI (GPIO 10 aka SPI_MOSI). MOSI not in use here due to single ch. ADCs, but must be defined anyway.
#define SPI_SS 20   // GPIO for slave select (GPIO 15).
#define CLK 19      // GPIO for SPI clock (GPIO 16).
#define NUM_SAMPLES 1024 // Adjust as needed
#define DOPPLER_FREQ 24.3e9 // Frequency of K-LC6 radar in Hz
#define SPEED_OF_LIGHT 3e8 // Speed of light in m/s

// Function to process I/Q data with FFT and estimate radial velocity
void process_data_with_fft(uint16_t* i_data, uint16_t* q_data, size_t size) {
    fftw_complex *in, *out;
    fftw_plan p;

    in = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * size);
    out = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * size);

    // Copy I/Q data to in
    for (int i = 0; i < size; i++) {
        in[i][0] = i_data[i]; // real part (I)
        in[i][1] = q_data[i]; // imaginary part (Q)
    }

    p = fftw_plan_dft_1d(size, in, out, FFTW_FORWARD, FFTW_ESTIMATE);

    fftw_execute(p); // execute the FFT

    // Find peak frequency in FFT result
    double max_magnitude = 0;
    int peak_index = 0;
    for (int i = 0; i < size; i++) {
        double magnitude = sqrt(out[i][0] * out[i][0] + out[i][1] * out[i][1]);
        if (magnitude > max_magnitude) {
            max_magnitude = magnitude;
            peak_index = i;
        }
    }

    // Convert peak frequency to Doppler shift and radial velocity
    double doppler_shift = (double)peak_index / size; // in Hz
    double radial_velocity = doppler_shift * SPEED_OF_LIGHT / (2 * DOPPLER_FREQ); // in m/s

    printf("Radial velocity: %.2f m/s\n", radial_velocity);

    fftw_destroy_plan(p);
    fftw_free(in);
    fftw_free(out);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <duration>\n", argv[0]);
        return 1;
    }

    int duration = atoi(argv[1]); // Duration in seconds

    if (gpioInitialise() < 0) {
        fprintf(stderr, "pigpio initialisation failed\n");
        return 1;
    }

    // Set up SPI
    int spiHandle = spiOpen(0, 1000000, 0); // Open SPI channel 0, with a speed of 1MHz

    // Allocate memory for I/Q data
    uint16_t *i_data = (uint16_t*)malloc(sizeof(uint16_t) * NUM_SAMPLES);
    uint16_t *q_data = (uint16_t*)malloc(sizeof(uint16_t) * NUM_SAMPLES);

    time_t start_time = time(NULL);
    while (time(NULL) - start_time < duration) {
        // Sample I/Q data from ADCs
        for (int i = 0; i < NUM_SAMPLES; i++) {
            char buf[2];
            spiXfer(spiHandle, buf, buf, 2); // Perform SPI transfer
            i_data[i] = ((buf[0] & 0x1F) << 7) | (buf[1] >> 1); // Extract I data from MISO1
            q_data[i] = ((buf[0] & 0x1F) << 7) | (buf[1] >> 1); // Extract Q data from MISO2
        }

        // Process I/Q data with FFT and estimate radial velocity
        process_data_with_fft(i_data, q_data, NUM_SAMPLES);
    }

    free(i_data);
    free(q_data);

    spiClose(spiHandle);
    gpioTerminate();

    return 0;
}