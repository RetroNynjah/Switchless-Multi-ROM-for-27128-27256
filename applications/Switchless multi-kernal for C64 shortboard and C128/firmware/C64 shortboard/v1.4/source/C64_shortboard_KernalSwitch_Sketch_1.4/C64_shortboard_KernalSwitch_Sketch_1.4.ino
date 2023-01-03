/*
#########################################################################################
#                                                                                       #
#  Kernal switcher sketch for C64 shortboard (28-pin ROM)                               #
#  To be used with the Retroninja 27128/27256 switchless multi-ROM in 27128 mode.       #
#                                                                                       #
#  Version 1.4                                                                          #
#  https://github.com/retronynjah                                                       #
#                                                                                       #
#########################################################################################
*/

#include <EEPROM.h>

// searchString is the command that the kernalselector firmware sends to the ROM switcher.
// Searchstring below is RNROM64#
// The command will be followed by a single byte ROM number between 1 (0x01) and 15 (0x0f)
byte searchString[] = {0x52,0x4E,0x52,0x4F,0x4D,0x36,0x34,0x23}; // "RNROM64#"

// pin defitions
int resetPin = 11;
int restorePin = 12;
int clockPin = 13;
int ledPin = A0;

int savedROM;
int commandLength = sizeof(searchString);
int bytesCorrect = 0;
int blinkROM = 0;
bool ledstate = LOW;
long ledchange = 0;
volatile bool clockstate;
bool restorestate;
bool restoreholding = false;
bool inmenu = false;
long restorepressed;

void pciSetup(byte pin) {
  // enable Pin Change Interrupt for requested pin
  *digitalPinToPCMSK(pin) |= bit(digitalPinToPCMSKbit(pin));  // enable pin
  PCIFR |= bit(digitalPinToPCICRbit(pin));                    // clear any outstanding interrupt
  PCICR |= bit(digitalPinToPCICRbit(pin));                    // enable interrupt for the group
}



ISR(PCINT0_vect)  // handle pin change interrupt for D8 to D13 here
{
  // read state of clock pin (D13)
  clockstate = PINB & B100000;
}


void cleareeprom() {
  for (int i = 0; i < EEPROM.length(); i++) {
    EEPROM.write(i, 0);
  }
}


void switchrom(int romnumber, bool doreset) {

  if (doreset) {
    // Hold reset low
    digitalWrite(resetPin, LOW);
    delay(100);
    pinMode(resetPin, OUTPUT);  // reset pin
    digitalWrite(resetPin, LOW);
  }

  // switch eprompin A14 (D8)
  if (romnumber & B00001) {
    digitalWrite(8, HIGH);
  } else {
    digitalWrite(8, LOW);
  }

  // switch eprompin A15 (D9)
  if (romnumber & B00010) {
    digitalWrite(9, HIGH);
  } else {
    digitalWrite(9, LOW);
  }

  // switch eprompin A16 (D10)
  if (romnumber & B00100) {
    digitalWrite(10, HIGH);
  } else {
    digitalWrite(10, LOW);
  }

  // switch eprompin A17 (A1)
  if (romnumber & B01000) {
    digitalWrite(A1, HIGH);
  } else {
    digitalWrite(A1, LOW);
  }

  // switch eprompin A18 (A2)
  if (romnumber & B10000) {
    digitalWrite(A2, HIGH);
  } else {
    digitalWrite(A2, LOW);
  }

  // if switching to a new kernal that isn't the menu kernal - save kernal to EEPROM address 0
  if ((romnumber != savedROM) && (romnumber != 0)) {
    EEPROM.write(0, romnumber);
    savedROM = romnumber;
  }

  if (romnumber != 0) {
    inmenu = false;
  }

  if (doreset) {
    // Release reset
    delay(200);
    pinMode(resetPin, INPUT);
  }

  // Give system some time to reset before entering main loop again.
  delay(500);
  blinkROM = romnumber;
}


void setup() {

  // set data pins 0..7 as inputs
  DDRD = B00000000;

  // Keep reset active (low) during setup
  digitalWrite(resetPin, LOW);
  pinMode(resetPin, OUTPUT);

  pinMode(clockPin, INPUT);

  pinMode(8, OUTPUT);   // eprom A14
  pinMode(9, OUTPUT);   // eprom A15
  pinMode(10, OUTPUT);  // eprom A16
  pinMode(A1, OUTPUT);  // eprom A17
  pinMode(A2, OUTPUT);  // eprom A18
  pinMode(ledPin, OUTPUT);

  pinMode(restorePin, INPUT);  // Restore
  digitalWrite(ledPin, LOW);

  // retrieve last used ROM from ATmega EEPROM and switch ROM using ROM address pins A14-A18
  savedROM = EEPROM.read(0);
  if (savedROM > 15) {
    savedROM = 0;
  }
  if (savedROM == 0) {
    inmenu = true;
  }

  switchrom(savedROM, false);

  // release reset
  pinMode(resetPin, INPUT);
  delay(500);  // Give system some time to reset before entering loop

  // Enable pin change interrupt on pin D13(PB5) connected to R/!W signal
  pciSetup(clockPin);
}


void loop() {

  if (inmenu) {
    ledstate = LOW;
    blinkROM = 0;
    // while in menu mode, listen for command
    if (clockstate == HIGH) {
      byte byteCurr = PIND;
      clockstate = LOW;
      if (bytesCorrect == commandLength) {
        // We have already found our command string. This byte must be the ROM number
        // Valid numbers are 1-15
        if ((byteCurr >= 1) && (byteCurr <= 15)) {
          // ROM number within valid range. Switch ROM and perform a reset
          switchrom(byteCurr, true);
        } else {
          bytesCorrect = 0;
        }
      }
      // We don't have full command string yet. Check if current byte is what we are looking for
      else if (byteCurr == searchString[bytesCorrect]) {
        // Increase bytesCorrect to check for next character
        bytesCorrect++;
      } else {
        bytesCorrect = 0;
      }
    }

    // Check if reset pin is active (low)
    if (!(PINB & B1000)) {
      // Reset is active. Other switch might be active and doing a reset or user is resetting.
      // Switch ROM to give up menu in case we're in menu and don't perform another reset as a reset is already in progress.
      switchrom(savedROM, false);
    }
  } else {
    // while not in menu mode, listen for restore key
    restorestate = PINB & B010000;
    if (restorestate == LOW) {
      // restore pressed
      ledstate = HIGH;
      if (restoreholding == false) {
        // start counting restore hold time
        restorepressed = millis();
        restoreholding = true;
      }
      if ((millis() - restorepressed) > 2000) {
        // Switch to menu ROM and perform a reset
        inmenu = true;
        switchrom(0, true);
        ledstate = LOW;
        restoreholding = false;
      }
    } else {
      // restore not held
      if (restoreholding){
        // restore has just been released
        ledstate = LOW;
        restoreholding = false;
      }
      
      //if kernal has just been switched we can do some led blinking now to indicate selected kernal
      if (blinkROM > 0) {
        if (ledchange == 0) {
          // first blink turn on LED and start counting
          ledstate = HIGH;
          ledchange = millis() + 50;
        } else {
          if (millis() > ledchange) {
            // time to toggle LED
            if (ledstate == HIGH) {
              ledstate = LOW;
              blinkROM--;
              if (blinkROM > 0) {
                // turn off LED and start counting
                ledchange = millis() + 250;
              } else {
                ledchange = 0;
              }
            } else {
              // turn on LED and start counting
              if (blinkROM > 0) {
                ledstate = HIGH;
                ledchange = millis() + 50;
              }
            }
          }
        }
      } 
    }
    digitalWrite(ledPin, ledstate);
  }
}
