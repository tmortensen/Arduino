#include <OneWire.h>
#include <Wire.h>
#include "HTU21D.h"
#include <DallasTemperature.h>

#define ONE_WIRE_BUS 2
#define TEMPERATURE_PRECISION 12

OneWire  oneWire(ONE_WIRE_BUS);

DallasTemperature sensors(&oneWire);

DeviceAddress Probe1 = { 0x28, 0x6F, 0x7B, 0x40, 0x05, 0x00, 0x00, 0x31 };
DeviceAddress Probe2 = { 0x28, 0x72, 0x58, 0x09, 0x06, 0x00, 0x00, 0x01 };
DeviceAddress Probe3 = { 0x28, 0x4D, 0x90, 0x40, 0x05, 0x00, 0x00, 0x43 };
DeviceAddress Probe4 = { 0x28, 0x9C, 0x76, 0x0A, 0x06, 0x00, 0x00, 0xE9 };

void setup(void) {
  Serial.begin(19200);
	sensors.begin();
	sensors.setResolution(Probe1, TEMPERATURE_PRECISION);
	sensors.setResolution(Probe2, TEMPERATURE_PRECISION);
	sensors.setResolution(Probe3, TEMPERATURE_PRECISION);
	sensors.setResolution(Probe4, TEMPERATURE_PRECISION);
}

void loop(void) {


	sensors.requestTemperatures();
	// get the device information
	float Temp1 = getTemperature(Probe1);
	float Temp2 = getTemperature(Probe2);
	float Temp3 = getTemperature(Probe3);
	float Temp4 = getTemperature(Probe4);

	Serial.print(Temp1);
	Serial.print(",");
	Serial.print(Temp2);
	Serial.print(",");
	Serial.print(Temp3);               
	Serial.print(",");
	Serial.println(Temp4);               
		
}

// function to print the temperature for a device
float getTemperature(DeviceAddress deviceAddress)
{
	float tempC = sensors.getTempC(deviceAddress);
	return DallasTemperature::toFahrenheit(tempC);
}

