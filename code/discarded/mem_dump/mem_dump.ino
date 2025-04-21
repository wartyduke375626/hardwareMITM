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

// Objects
M93Cx6 eeprom = M93Cx6(PWR_PIN, CS_PIN, SK_PIN, DO_PIN, DI_PIN, ORG_PIN);


void setup()
{
    Serial.begin(SREIAL_BAUD);
    eeprom.setChip(CHIP);
    eeprom.setOrg(ORG);
    Serial.println("\nSetup ready.\n");
    delay(2000);

    Serial.println("Reading EEPROM...");

    for (int i = 0; i < ADDR_COUNT; i += 8)
    {
        // Print Address prefix
        Serial.print("0x");
        if (i < 0x10) Serial.print("0");
        if (i < 0x100) Serial.print("0");
        if (i < 0x1000) Serial.print("0");
        Serial.print(i, HEX);
        Serial.print(": ");

        // Read bytes and print them in HEX
        uint8_t bytes[8];
        for (int j = 0; j < 8; ++j)
        {
            bytes[j] = eeprom.read(i + j);
            uint8_t byte = bytes[j];

            if (byte < 0x10) Serial.print("0");
            Serial.print(byte, HEX);
            Serial.print(" ");
        }

        // Print ASCII printable bytes
        Serial.print(" ");
        for (int j = 0; j < 8; ++j)
        {
            uint8_t byte = bytes[j];
            if (byte >= 32 && byte <= 126) {
                char c = (char) byte;
                Serial.print(c);
            }
            else {
                Serial.print(".");
            }
        }

        Serial.println();
    }

    Serial.println("Done.");
}

void loop()
{
    delay(100);
}
