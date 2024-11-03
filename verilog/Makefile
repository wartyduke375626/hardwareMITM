.PHONY: clean sim-all default


# Directoriy declarations
SRC_DIR=src
TEST_DIR=test

BUILD_DIR=build
TEST_BUILD_DIR=$(BUILD_DIR)/test
SIM_DIR=sim


include test.mk


default: sim-all


# Create directories
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
	
$(TEST_BUILD_DIR):
	mkdir -p $(TEST_BUILD_DIR)
	
$(SIM_DIR):
	mkdir -p $(SIM_DIR)


# Clean rule
clean:
	rm -rf $(BUILD_DIR) $(SIM_DIR)