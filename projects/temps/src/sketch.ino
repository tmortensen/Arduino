#include <OneWire.h>
#include <Wire.h>
#include "HTU21D.h"
#include <DallasTemperature.h>

// Data wire is plugged into port 2 on the Arduino
#define ONE_WIRE_BUS 2
#define TEMPERATURE_PRECISION 12

// Memory on RTC
#define I2C_EEPROM_ADDR 0x57

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);

// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature sensors(&oneWire);

DeviceAddress Probe1 = { 0x28, 0xFF, 0xFE, 0x40, 0x5, 0x0, 0x0, 0x99 };
DeviceAddress Probe2 = { 0x28, 0x8B, 0x0D, 0x41, 0x5, 0x0, 0x0, 0xBA };
DeviceAddress Probe3 = { 0x28, 0x64, 0x1A, 0xF7, 0x4, 0x0, 0x0, 0xA9 };

int inByte = 0;         // incoming serial byte


float LastHumid = 0;

// Create Humidity object
HTU21D myHumidity;

void setup(void)
{
	// Set Analog refrence to the 3.3v using aref pin.  
	//  Remember to unhook analog sensors before uploading sketch for first time
	analogReference(EXTERNAL);

	// start serial port
	Serial.begin(19200);

	// Start up the library for onewire
	sensors.begin();

	// Start up the lib for humidity
	myHumidity.begin();

	// set the resolution to 12 bit
	sensors.setResolution(Probe1, TEMPERATURE_PRECISION);
	sensors.setResolution(Probe2, TEMPERATURE_PRECISION);
	sensors.setResolution(Probe3, TEMPERATURE_PRECISION);

}

void loop(void)
{ 

	// if we get a valid byte, read temps 
	if (Serial.available() > 0) {
		// get incoming byte:
		inByte = Serial.read();
		inByte = inByte - '0';
		char say [50];
		if (inByte == 1) {
			// call sensors.requestTemperatures() to issue a global temperature 
			sensors.requestTemperatures();

			// get the device information
			float Temp1 = getTemperature(Probe1);
			float Temp2 = getTemperature(Probe2);
			float Temp3 = getTemperature(Probe3);
			// Save off old Humidity in case we get error 998 or 999
			// todo,  somehow alert if we only get errors back for a time period
			float Humid = getHumidity();
			float HumidTemp = getHumidityTemp();

			if ( ( Humid == '998' ) || ( Humid == '999' ) ) {
				if ( ( LastHumid == '998' ) || ( LastHumid == '999' ) ) {
					// Set humid to 0 to indicate an issue over more then one monitor cycle.
					Humid = 0;
				}
				else {
					// Set Humid to LastHumid
					Humid = LastHumid;
				}
			} else {
				LastHumid = Humid;
			}

			Serial.print(Temp1);
			Serial.print(",");
			Serial.print(Temp2);
			Serial.print(",");
			Serial.print(Temp3);               
			Serial.print(",");
			Serial.print(Humid);               
			Serial.print(",");
			Serial.println(HumidTemp);               
		}
		else { 
			String sayThis = String(inByte);
			char sayThisNow[2];
			sayThis.toCharArray(sayThisNow,2);
			SerialSay(sayThisNow);
			// Serial.print(inByte);
		}
	}
	else {
		establishContact();
	}

}

// function to send a line of data out to serial

void SerialSay(char* input) 
{
 Serial.println(input);
}

// function to print the humidity and temp
float getHumidity()
{
  float humd = myHumidity.readHumidity();
	return humd;
}

float getHumidityTemp()
{
  float Ctemp = myHumidity.readTemperature();
	return Celcius2Fahrenheit(Ctemp);
}

// function to print a device address
void printAddress(DeviceAddress deviceAddress)
{
	for (uint8_t i = 0; i < 8; i++)
	{
		// zero pad the address if necessary
		if (deviceAddress[i] < 16) Serial.print("0");
		Serial.print(deviceAddress[i], HEX);
	}
}

// function to print the temperature for a device
void printTemperature(DeviceAddress deviceAddress)
{
	float tempC = sensors.getTempC(deviceAddress);
	Serial.print(DallasTemperature::toFahrenheit(tempC));
}

// function to print a device's resolution
void printResolution(DeviceAddress deviceAddress)
{
	Serial.print("Resolution: ");
	Serial.print(sensors.getResolution(deviceAddress));
	Serial.println();    
}

// function to print the temperature for a device
float getTemperature(DeviceAddress deviceAddress)
{
	float tempC = sensors.getTempC(deviceAddress);
	return DallasTemperature::toFahrenheit(tempC);
}

// main function to print information about a device
void printData(DeviceAddress deviceAddress)
{
	Serial.print("Address: ");
	printAddress(deviceAddress);
	Serial.print(" ");
	printTemperature(deviceAddress);
	Serial.println();
}

int Celcius2Fahrenheit(int celcius)
{
	return (celcius *  9.0 / 5.0) + 32.0;
}

void establishContact() {
	while (Serial.available() <= 0) {
		//Serial.println("0,0,0");   // send an initial string
//		delay(300);
	}
}

