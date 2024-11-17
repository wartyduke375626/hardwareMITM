## Description
This directory contains simple programms for MITM attacks demonstration against communication between a simple Microcontroller **ESP8266 NodeMCU** and the **AT93C56A** EEPROM.

## Dependencies

* **M93Cx6 Library**: an Arduino library for communication with the **AT93C56A** - https://github.com/TauSolutions/M93Cx6/tree/master  
Before use, a small bugfix is required -- change the argument type in functions *M93Cx6::read*, *M93Cx6::write*, and *M93Cx6::erase* from *uint8_t* to *uint16_t*.  
When the one-byte organisation is set, the EEPROM address width can be up to 9 bits which does not fit in *uint8_t*.

## Sample Programs
* **mem_dump**: dumps the entire memory content and displays it through serial line.
* **write_demo**: writes the *"Hello world!"* string to a specific address on the EEPROM.