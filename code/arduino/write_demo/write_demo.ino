#include <M93Cx6.h>

// Pin layout
#define PWR_PIN     5
#define CS_PIN      15
#define SK_PIN      14
#define DO_PIN      12  // MISO
#define DI_PIN      13  // MOSI
#define ORG_PIN     16

// EEPROM config
#define ORG         ORG_8
#define CHIP        M93C66
#define PIN_DELAY_TIME 1

#define ADDR_COUNT  512
#define SREIAL_BAUD 115200
#define START_ADDR  0x128

// Objects
M93Cx6 eeprom = M93Cx6(PWR_PIN, CS_PIN, SK_PIN, DO_PIN, DI_PIN, ORG_PIN);


void setup() {
  Serial.begin(SREIAL_BAUD);
  eeprom.setChip(CHIP);
  eeprom.setOrg(ORG);
  Serial.println("\nSetup ready.\n");
  delay(2000);

  Serial.println("Writing to EEPROM...");

  char buffer[13] = "Hello World!";

  eeprom.writeEnable();
  for (int i = 0; i < 12; ++i) {
    // Write byte
    eeprom.write(START_ADDR + i, buffer[i]);
  }
  eeprom.writeDisable();

  Serial.println("Writing Done.");
}

void loop() {
  delay(100);
}
