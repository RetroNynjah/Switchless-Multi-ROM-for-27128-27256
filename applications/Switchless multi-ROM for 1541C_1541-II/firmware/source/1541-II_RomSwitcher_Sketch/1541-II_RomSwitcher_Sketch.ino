#include <EEPROM.h>

// searchString is the command that is used for switching ROM.
// It is passed by the 1541-II in reverse order so the variable should be reversed too.
// The command should be preceded by a ROM number between 1 and 4 when used.
// The below reversed searchString in hex ascii is MORNR@ which is specified like this on the C64: 1@RNROM, 2@RNROM and so on.
byte searchString[] = {0x4D,0x4F,0x52,0x4E,0x52,0x40};

int commandLength = sizeof(searchString);
int bytesCorrect = 0;
volatile bool state;


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
  
  pinMode(11, OUTPUT); // reset pin
  digitalWrite(11, LOW);
  delay(50);
  digitalWrite(11, HIGH);
  delay(50);
  digitalWrite(11, LOW);
  pinMode(11, INPUT);

}


void switchrom(int romnumber){

  for (int x = 0; x <= romnumber; x++){
    digitalWrite (A0, HIGH);
    delay(30);
    digitalWrite (A0, LOW);
    delay(250);
  }
  delay (200);

  // switch eprompin A14 (D9)
  if (romnumber & B01){
    digitalWrite(9 , HIGH);
  }  
  else {
    digitalWrite(9 , LOW);
  }

  // switch eprompin A15 (D10)
  if (romnumber & B10){
    digitalWrite(10 , HIGH);
  }  
  else {
    digitalWrite(10 , LOW);
  }

  int savedROM = EEPROM.read(0);
  if (savedROM != romnumber){
    EEPROM.write(0, romnumber);
  }

  resetdrive();

}



// function for debugging using onboard LED
void blinknumber(int num) {
  int hundreds = num / 100;
  int tens = num % 100 / 10;
  int singular = num % 10;
  
  for (int x = 1; x <= 10; x++){
    digitalWrite(A0, HIGH);
    delay(50);
    digitalWrite(A0, LOW);
    delay(50);
  }
  delay(2000);

  for (int x = 1; x <= hundreds; x++){
    digitalWrite(A0, HIGH);
    delay(50);
    digitalWrite(A0, LOW);
    delay(350);
  }
  delay(2000);

  for (int x = 1; x <= tens; x++){
    digitalWrite(A0, HIGH);
    delay(50);
    digitalWrite(A0, LOW);
    delay(350);
  }
  delay(2000);

  for (int x = 1; x <= singular; x++){
    digitalWrite(A0, HIGH);
    delay(50);
    digitalWrite(A0, LOW);
    delay(350);
  }
}



void setup() {

  // set data pins as inputs
  DDRD = B00000000;
  
  pinMode(13, INPUT); // clock pin
  pinMode(9, OUTPUT); // eprom A14
  pinMode(10, OUTPUT); // eprom A15
  pinMode(11, INPUT); // reset pin
  pinMode (A0, OUTPUT); // LED
  
  // retrieve last used ROM from ATmega EEPROM and switch ROM using A14/A15
  int lastROM = EEPROM.read(0);
  if (lastROM > 4){
    cleareeprom();
    lastROM = 0;
  }
  switchrom(lastROM);
  
  // enable pin change interrupt on pin D13(PB5) connected to R/W on 6502
  pciSetup(13); 
}


void loop() {
  if (state == HIGH){
    state=LOW;
    byte byteCurr = PIND;
      
    if (bytesCorrect == commandLength){
      // we have our search string. This byte must be the ROM number
      // valid numbers are 1-4 (ASCII 49-52)
      if ((byteCurr >= 49)&&(byteCurr<=52)){
        // rom number within valid range. Switch rom
        switchrom(byteCurr - 49);
      }
      else{
        bytesCorrect=0;
      }
      //blinknumber(byteCurr);
    }

    // we don't have full search string yet. check if current byte is what we are looking for
    if (byteCurr == searchString[bytesCorrect]){
      // increase bytesCorrect to check for next character
      bytesCorrect++;
    }
    else {
      bytesCorrect = 0;
    }
  }
}
