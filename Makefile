BIN_DIR=./bin
SRC_DIR=./src
TEST_DIR=./test_programs

WAVE_FILE = waves.vcd
TOP = cpu_tb

TB_SRC = $(SRC_DIR)/$(TOP).v
SIM_BIN = $(TB_SRC:$(SRC_DIR)/%.v=$(BIN_DIR)/%)

TEST_FILES = $(wildcard $(TEST_DIR)/*.asm)
TEST_HEX_LIST = $(TEST_FILES:$(TEST_DIR)/%.asm=$(BIN_DIR)/%.hex.text)
TEST_HEX_LIST += $(TEST_FILES:$(TEST_DIR)/%.asm=$(BIN_DIR)/%.hex.data)
TEST_MARS_LIST = $(TEST_FILES:$(TEST_DIR)/%.asm=$(BIN_DIR)/%.out.mars)
TEST_OURS_LIST = $(TEST_FILES:$(TEST_DIR)/%.asm=$(BIN_DIR)/%.out.ours)

.PHONY: elab run regression waves clean
.PRECIOUS: $(TEST_HEX_LIST)

elab: $(SIM_BIN)

run: $(SIM_BIN)
	vvp $(SIM_BIN)

regression: test_0 test_1 test_2 test_3 test_4 test_5 test_6 test_7 test_8 test_9 test_10 test_11 test_12 test_a2a test_a2b test_a2c

# Main test target. Creates output from both MARS and our simulation and diffs.
%: $(SIM_BIN) $(BIN_DIR)/%.hex.text $(BIN_DIR)/%.hex.data FORCE
	java -jar mars.jar nc mc CompactDataAtZero zero at v0 v1 a0 a1 a2 a3 t0 t1 t2 t3 t4 t5 t6 t7 \
		s0 s1 s2 s3 s4 s5 s6 s7 t8 t9 k0 k1 gp sp fp ra 0x00000000-0x00002FFC \
		$(TEST_DIR)/$*.asm > $(BIN_DIR)/$*.out.mars
	vvp $(SIM_BIN) +PROG=$(BIN_DIR)/$* +TEXT=$(word 2,$^) +DATA=$(word 3,$^)
	diff --ignore-space-change --ignore-blank-lines \
		$(BIN_DIR)/$*.out.mars $(BIN_DIR)/$*.out.ours
	
$(BIN_DIR)/%.hex.text: $(TEST_DIR)/%.asm
	java -jar mars.jar mc CompactDataAtZero a dump .text HexText $@ $<

$(BIN_DIR)/%.hex.data: $(TEST_DIR)/%.asm
	java -jar mars.jar mc CompactDataAtZero a dump .data HexText $@ $<

$(SIM_BIN): $(wildcard $(SRC_DIR)/*.v) | $(BIN_DIR)
	iverilog -I$(SRC_DIR) -s $(TOP) -o $(SIM_BIN) $(TB_SRC)

$(BIN_DIR):
	mkdir $(BIN_DIR)

waves:
	java -jar WaveView.jar $(BIN_DIR)/$(WAVE_FILE)

clean:
	rm -f $(SIM_BIN) $(BIN_DIR)/$(WAVE_FILE) $(BIN_DIR)/*.hex.* $(BIN_DIR)/*.ours $(BIN_DIR)/*.mars $(BIN_DIR)/.waves.vcd.waveconfig

FORCE: