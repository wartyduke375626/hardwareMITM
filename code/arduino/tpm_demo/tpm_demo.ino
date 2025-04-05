#include <SPI.h>

#define CS_PIN 15    // D8
#define MOSI_PIN 13  // D7
#define MISO_PIN 12  // D6
#define SCK_PIN 14   // D5
#define RST_PIN 16   // D0

#define SPI_FREQ 1000000 // 1MHz

#define TPM_ACCESS 0xD40000
#define TPM_STATUS 0xD40018
#define TPM_FIFO 0xD40024

#define WAIT_TIMEOUT 50

#define IS_STATUS_VALID(status) (0x80 & status)
#define IS_STATUS_EXPECT(status) (0x08 & status)
#define IS_STATUS_DATA_AVAIL(status) (0x10 & status)
#define IS_STATUS_CMD_READY(status) (0x40 & status)


SPISettings spiSettings(SPI_FREQ, MSBFIRST, SPI_MODE0);

uint8_t readRegister(uint32_t reg)
{
    SPI.beginTransaction(spiSettings);
    digitalWrite(CS_PIN, LOW);
    SPI.transfer(0x80);
    SPI.transfer((reg >> 16) & 0xFF);
    SPI.transfer((reg >> 8) & 0xFF);
    SPI.transfer(reg & 0xFF);
    uint8_t value = SPI.transfer(0x00);
    digitalWrite(CS_PIN, HIGH);
    SPI.endTransaction();
    return value;
}

void writeRegister(uint32_t reg, uint8_t value)
{
    SPI.beginTransaction(spiSettings);
    digitalWrite(CS_PIN, LOW);
    SPI.transfer(0x00);
    SPI.transfer((reg >> 16) & 0xFF);
    SPI.transfer((reg >> 8) & 0xFF);
    SPI.transfer(reg & 0xFF);
    SPI.transfer(value);
    digitalWrite(CS_PIN, HIGH);
    SPI.endTransaction();
}

void printHexData(uint8_t* buffer, size_t len)
{
    for (size_t i = 0; i < len; ++i)
    {
        Serial.printf("0x%02X ", buffer[i]);
    }
}

bool tpmSendCommand(uint8_t* cmd_buffer, size_t cmd_len, uint8_t* resp_buffer, size_t resp_len)
{
    uint8_t status;

    // wait for command ready
    size_t wait = 0;
    while(1)
    {
        status = readRegister(TPM_STATUS);
        if (IS_STATUS_CMD_READY(status)) break;
        ++wait;
        if (wait == WAIT_TIMEOUT) {
            Serial.println("Waiting for command ready timed out.");
            Serial.printf("\tTPM_STATUS value: 0x%02X\n", status);
            return false;
        }
        delay(1);
    }
    
    // write command FIFO
    for (size_t i = 0; i < cmd_len; ++i)
    {
        writeRegister(TPM_FIFO, cmd_buffer[i]);
    }

    
    status = readRegister(TPM_STATUS);
    // wait for status valid
    wait = 0;
    while(1)
    {
        status = readRegister(TPM_STATUS);
        if (IS_STATUS_VALID(status)) break;
        ++wait;
        if (wait == WAIT_TIMEOUT) {
            Serial.println("Waiting for status valid timed out.");
            Serial.printf("\tTPM_STATUS value: 0x%02X\n", status);
            return false;
        }
        delay(1);
    }
    // assert expect bit is clear
    if (IS_STATUS_EXPECT(status)) {
        Serial.println("Fatal error while sending command: expect bit is not clear.");
        Serial.printf("\tTPM_STATUS value: 0x%02X\n", status);
        return false;
    }

    // set go bit
    status = readRegister(TPM_STATUS);
    writeRegister(TPM_STATUS, status | 0x20);

    // wait for data avalable
    wait = 0;
    while(1)
    {
        status = readRegister(TPM_STATUS);
        if (IS_STATUS_VALID(status) && IS_STATUS_DATA_AVAIL(status)) break;
        ++wait;
        if (wait == WAIT_TIMEOUT) {
            Serial.println("Waiting for data available timed out.");
            Serial.printf("\tTPM_STATUS value: 0x%02X\n", status);
            return false;
        }
        delay(1);
    }

    // read response data
    for (size_t i = 0; i < resp_len; ++i)
    {
        resp_buffer[i] = readRegister(TPM_FIFO);
    }
    
    status = readRegister(TPM_STATUS);
    // wait for status valid
    wait = 0;
    while(1)
    {
        status = readRegister(TPM_STATUS);
        if (IS_STATUS_VALID(status)) break;
        ++wait;
        if (wait == WAIT_TIMEOUT) {
            Serial.println("Waiting for status valid timed out.");
            Serial.printf("\tTPM_STATUS value: 0x%02X\n", status);
            return false;
        }
        delay(1);
    }
    // assert data available bit is clear
    if (IS_STATUS_DATA_AVAIL(status)) {
        Serial.println("Fatal error while reading response: data available bit is not clear.");
        Serial.printf("\tTPM_STATUS value: 0x%02X\n", status);
        return false;
    }

    // set command ready to restore state machine
    status = readRegister(TPM_STATUS);
    writeRegister(TPM_STATUS, status | 0x40);

    return true;
}

bool tpmStartup()
{
    uint8_t cmd[] = {
        0x80, 0x01,             // Tag: TPM2_ST_NO_SESSIONS
        0x00, 0x00, 0x00, 0x0C, // Command len: 12 bytes
        0x00, 0x00, 0x01, 0x44, // Command code: TPM2_CC_Startup
        0x00, 0x00              // Startup mode: TPM_SU_CLEAR
    };

    uint8_t resp[10]; // (2byte tag + 4byte size + 4byte RC)
    if(!tpmSendCommand(cmd, sizeof(cmd), resp, sizeof(resp))) return false;

    // check if response is TPM_RC_SUCCESS (0x000)
    uint16_t rc = resp[9] | ((resp[8] & 0x0F) << 8);
    if (rc != 0) {
        Serial.println("Fatal error while executing TPM Startup command: response code is not SUCCESS.");
        Serial.printf("\tTPM_RC value: 0x%03X\n", rc);
        Serial.print("\tFull response data: ");
        printHexData(resp, sizeof(resp));
        Serial.println();
        return false;
    }

    return true;
}

bool tpmGetRandom(uint16_t num_bytes)
{
    uint8_t cmd[] = {
        0x80, 0x01,             // Tag: TPM2_ST_NO_SESSIONS
        0x00, 0x00, 0x00, 0x0C, // Command len: 12 bytes
        0x00, 0x00, 0x01, 0x7B, // Command code: TPM2_CC_GetRandom
        (uint8_t)(num_bytes >> 8), (uint8_t)(num_bytes & 0xFF)  // Bytes requested
    };

    size_t resp_len = 12 + num_bytes;   // (2byte tag + 4byte size + 4byte RC + 2byte resp data size + num_bytes)
    uint8_t* resp = (uint8_t*)malloc(resp_len);
    if(!tpmSendCommand(cmd, sizeof(cmd), resp, resp_len)) return false;

    // check if response is TPM_RC_SUCCESS (0x000)
    uint16_t rc = resp[9] | ((resp[8] & 0x0F) << 8);
    if (rc != 0) {
        Serial.println("Fatal error while executing TPM GetRandom command: response code is not SUCCESS.");
        Serial.printf("\tTPM_RC value: 0x%03X\n", rc);
        Serial.print("\tFull response data: ");
        printHexData(resp, resp_len);
        Serial.println();
        return false;
    }

    // print random bytes
    Serial.print("Got random bytes: ");
    printHexData(resp + 12, num_bytes);
    Serial.println();

    free(resp);
    return true;
}

void setup()
{
    Serial.begin(115200);
    delay(5000);
    Serial.println("Starting TPM SLB 9670 Test...");

    pinMode(RST_PIN, OUTPUT);
    pinMode(CS_PIN, OUTPUT);
    SPI.begin();

    Serial.println("Ressetting TPM...");
    digitalWrite(RST_PIN, LOW);
    digitalWrite(CS_PIN, HIGH);
    delay(500);
    digitalWrite(RST_PIN, HIGH);
    delay(1000);

    Serial.println("Requesting locality 0...");
    uint8_t value = readRegister(TPM_ACCESS);
    Serial.printf("TPM_ACCESS before: 0x%02X\n", value);
    writeRegister(TPM_ACCESS, 0x02);
    delay(100);
    value = readRegister(TPM_ACCESS);
    Serial.printf("TPM_ACCESS after: 0x%02X\n", value);
    if (value != 0xA1) {
        Serial.println("Locality failed!");
        return;
    }

    value = readRegister(TPM_STATUS);
    Serial.printf("TPM_STATUS after: 0x%02X\n", value);

    Serial.println("Sending TPM2_Startup...");
    if (!tpmStartup()) {
        Serial.println("Startup failed!");
        return;
    }

    /*
    Serial.println("Relinquishing locality...");
    writeRegister(TPM_ACCESS, 0x20);
    access = readRegister(TPM_ACCESS);
    Serial.printf("TPM_ACCESS after release: 0x%02X\n", access);
    */
}

void loop()
{
    Serial.println("Sending TPM2_GetRandom...");
    if (!tpmGetRandom(16)) {
        Serial.println("GetRandom failed!");
        return;
    }
    delay(3000);
}

/*
uint32_t readBurstCount() {
    digitalWrite(CS_PIN, LOW);
    SPI.transfer(0x83);
    SPI.transfer(0xD4);
    SPI.transfer(0x00);
    SPI.transfer(0x18);
    uint32_t burst = 0;
    burst |= (SPI.transfer(0x00) << 24);
    burst |= (SPI.transfer(0x00) << 16);
    burst |= (SPI.transfer(0x00) << 8);
    burst |= SPI.transfer(0x00);
    digitalWrite(CS_PIN, HIGH);
    return burst;
}*/