# Project setup
PROJ      = digitalLock
BUILD     = ./build
DEVICE    = 8k
FOOTPRINT = ct256

# Files
FILES = top.v
FILES += Button_Code.v
FILES += blink.v
FILES += enter_code.v
FILES += enter_new_code.v
FILES += counter.v
FILES += codeReg.v
FILES += newCodeReg.v
FILES += reprogram.v

.PHONY: all clean burn

all:
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	yosys -p "synth_ice40 -top top -blif $(BUILD)/$(PROJ).blif" $(FILES)
	# Place and route using arachne
	arachne-pnr -d $(DEVICE) -P $(FOOTPRINT) -o $(BUILD)/$(PROJ).asc -p pinmap.pcf $(BUILD)/$(PROJ).blif
	# Convert to bitstream using IcePack
	icepack $(BUILD)/$(PROJ).asc $(BUILD)/$(PROJ).bin

burn:
	iceprog $(BUILD)/$(PROJ).bin

clean:
	rm build/*