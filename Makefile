ifeq ($(OS),Windows_NT)
	detected_OS := Windows
else
	detected_OS := $(shell sh -c 'uname 2>/dev/null || echo Unknown')
endif

ifeq ($(detected_OS),Windows)
	RM = del /Q /S
	FixPath = $(subst /,\,$1)
	MD = if not exist $1 mkdir $1
	FixQuotes = $(subst /,\,$(subst ",,$1))
	EXT = .exe
endif
ifeq ($(detected_OS),Linux)
	RM = rm -rf
	FixPath = $1
	MD = mkdir -p $1
	FixQuotes = $1
	EXT = .out
endif

FLAGS = 

CC = g++ -std=c++23 -I . -march=native -fno-math-errno $(FLAGS)

IMPL_DIR = impl
OBJ_DIR = obj
BIN_DIR = bin
DATA_DIR = data

FIB = fibsonicci.cpp
EVAL = eval.cpp

.PHONY: init
init:
	$(call MD,$(OBJ_DIR))
	$(call MD,$(BIN_DIR))
	$(call MD,$(DATA_DIR))

.PHONY: clean clean-bin clean-data clean-all
clean-all: clean clean-bin clean-data

clean: # clean objects
	$(RM) $(OBJ_DIR)

clean-bin:
	$(RM) $(BIN_DIR)

clean-data:
	$(RM) $(DATA_DIR)



###############################################################################
## Fibonacci implementations
IMPL = naive \
	   linear \
	   matmul_simple \
	   matmul_fastexp \
	   matmul_strassen \
	   matmul_karatsuba \
	   matmul_dft \
	   matmul_fft \
	   field_ext

IMPL_OPT = $(IMPL:%=%.Og) $(IMPL:%=%.O3)

IMPL_GOAL = $(IMPL:%=%.O3.1)
IMPL_LONG = $(IMPL_OPT:%=%.5)

IMPL_LIMIT = $(IMPL_LONG) $(IMPL_GOAL)

.PHONY: $(IMPL_LIMIT:%=run-%) all-data all-data-long

all-data: $(IMPL_GOAL:%=$(DATA_DIR)/%.dat)

all-data-long: $(IMPL_LONG:%=$(DATA_DIR)/%.dat)

$(IMPL_LIMIT:%=run-%): run-%: $(BIN_DIR)/%
	$(call FixQuotes,./$^)

$(IMPL_LIMIT:%=$(DATA_DIR)/%.dat): $(DATA_DIR)/%.dat: $(BIN_DIR)/%$(EXT)
	$(call FixQuotes,./$^) > $@


.PHONY: all all-obj

all: $(IMPL_LIMIT:%=$(BIN_DIR)/%$(EXT))

all-obj: $(IMPL_OPT:%=$(OBJ_DIR)/%.o)


.SECONDEXPANSION:
$(IMPL_OPT:%=$(BIN_DIR)/one_%$(EXT)): $(BIN_DIR)/one_%$(EXT): $(FIB) $(OBJ_DIR)/$$(word 1,$$(subst ., ,%)).$$(word 2,$$(subst ., ,%)).o
	$(CC) $^ -o $@ -$(word 2,$(subst ., ,$@))

.SECONDEXPANSION:
$(IMPL_LIMIT:%=$(BIN_DIR)/%$(EXT)): $(BIN_DIR)/%$(EXT): $(EVAL) $(OBJ_DIR)/$$(word 1,$$(subst ., ,%)).$$(word 2,$$(subst ., ,%)).o
	$(CC) $^ -o $@ -$(word 2,$(subst ., ,$@)) -DLIMIT=$(patsubst %,%,$(word 3,$(subst ., ,$@))) -lpthread


.SECONDEXPANSION:
$(IMPL_OPT:%=$(OBJ_DIR)/%.o): $(OBJ_DIR)/%.o: $(IMPL_DIR)/$$(word 1,$$(subst ., ,%)).cpp
	$(CC) -c $^ -o $@ -$(word 2,$(subst ., ,$@))
