/*
#########################################################################################
#                                                                                       #
#  ROM switcher sketch for 1541-II, 1571, 1581 (28-pin ROM)                             #
#  To be used with the Retroninja 27128/27256 switchless multi-ROM in either            #
#  27128 or 27256 mode. Configure romsize below to match your use case                  #
#                                                                                       #
#  Version 1.2                                                                          #
#  https://github.com/retronynjah                                                       #
#                                                                                       #
#########################################################################################
*/

#include <EEPROM.h>

// searchString is the command that is used for switching ROM.
// It is passed by the 1541-II in reverse order so the variable should be reversed too.
// The command should be preceded by a ROM number between 1 and 4 when used.
// The below reversed searchString in hex ascii is MORNR@ which is specified like this on the C64: 1@RNROM, 2@RNROM and so on.
byte searchString[] = {0x4D,0x4F,0x52,0x4E,0x52,0x40};

// define size of ROM block to switch. Valid values are 128 or 256.
// rom images in flash m,ust match this size.
// 1541-II = 128
// 1571 = 256
// 1581 = 256
const int romsize = 128;

// pin defitions
int resetPin = 11;
int clockPin = 13;
int ledPin = A0;

int commandLength = sizeof(searchString);
int bytesCorrect = 0;
volatile bool state;
static byte byteCurr;

void pciSetup(byte pin)
{
    *digitalPinToPCMSK(pin) |= bit (digitalPinToPCMSKbit(pin));  // enable pin
    PCIFR  |= bit (digitalPinToPCICRbit(pin)); // clear any outstanding interrupt
    PCICR  |= bit (digitalPinToPCICRbit(pin)); // enable interrupt for the group
}



ISR (PCINT0_vect) // handle pin change interrupt for D8 to D13 here
{    
       // read state of pin 13
       state = PINB & B00100000;
}
 

void cleareeprom(){
  for (int i = 0 ; i < EEPROM.length() ; i++) {
    EEPROM.write(i, 0);
  }
}


void resetdrive(){

  digitalWrite(resetPin, LOW);
  pinMode(resetPin, OUTPUT);
  delay(50);
  digitalWrite(resetPin, HIGH);
  pinMode(resetPin, INPUT);

}


void switchrom(int romnumber){

  for (int x = 0; x <= romnumber; x++){
    digitalWrite (ledPin, HIGH);
    delay(30);
    digitalWrite (ledPin, LOW);
    delay(250);
  }
  delay (200);

  if (romsize == 128){
    // switch eprompin A14 (D8)
    if (romnumber & B01){
      digitalWrite(8 , HIGH);
    }  
    else {
      digitalWrite(8 , LOW);
    }
  
    // switch eprompin A15 (D9)
    if (romnumber & B10){
      digitalWrite(9 , HIGH);
    }  
    else {
      digitalWrite(9 , LOW);
    }
  }
  else if (romsize == 256){
    // switch eprompin A15 (D9)
    if (romnumber & B01){
      digitalWrite(9 , HIGH);
    }  
    else {
      digitalWrite(9 , LOW);
    }
  
    // switch eprompin A16 (D10)
    if (romnumber & B10){
      digitalWrite(10 , HIGH);
    }  
    else {
      digitalWrite(10 , LOW);
    }
  }

  int savedROM = EEPROM.read(0);
  if (savedROM != romnumber){
    EEPROM.write(0, romnumber);
  }
  resetdrive();
}


void setup() {

  // set data pins as inputs
  DDRD = B00000000;
  
  pinMode(13, INPUT); // clock pin
  pinMode(8, OUTPUT); // eprom A14. connection of A14 is controlled by solder jumper
  pinMode(9, OUTPUT); // eprom A15
  pinMode(10, OUTPUT); // eprom A16
  pinMode(A1, OUTPUT); // eprom A17
  pinMode(A2, OUTPUT); // eprom A18

  pinMode(clockPin, INPUT); // R/!W
  pinMode(resetPin, INPUT); // Keep reset pin as input while not performing reset.

  pinMode (ledPin, OUTPUT);

  // retrieve last used ROM from ATmega EEPROM and switch ROM using A14/A15
  int lastROM = EEPROM.read(0);
  if (lastROM > 4){
    cleareeprom();
    lastROM = 0;
  }
  switchrom(lastROM);
  
  // enable pin change interrupt on pin D13(PB5) connected to R/W on 6502
  pciSetup(clockPin); 
}


void loop() {
  if (state == HIGH){
    byteCurr = PIND;
    state=LOW;
      
    // we don't have full search string yet. check if current byte is what we are looking for
    if (byteCurr == searchString[bytesCorrect]){
      // It is the byte we're waiting for. increase byte counter
      bytesCorrect++;
	    if (bytesCorrect == commandLength){
        // we have our full search string. wait for next byte
		    while(state == LOW){}
    		byteCurr = PIND;
    		// This byte should be the ROM number
    		// valid numbers are 1-4 (ASCII 49-52)
    		if ((byteCurr >= 49)&&(byteCurr<=52)){
              // rom number within valid range. Switch rom
              switchrom(byteCurr - 49);
    		}
    		else if(byteCurr == searchString[0]){
              // it was the first byte in string, starting with new string
              bytesCorrect = 1;
    		}
        else{
          bytesCorrect = 0;
        }
  	  }
    }
    // byte isn't what we are looking for, is it the first byte in the string then?
    else if(byteCurr == searchString[0]){
        // it was the first byte in string, starting with new string
        bytesCorrect = 1;
    }
    else {
      // byte not correct at all. Start over from the beginning
      bytesCorrect = 0;
    }
  }
}
