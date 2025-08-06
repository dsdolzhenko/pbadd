TARGET = pbadd
SOURCES = pbadd.m
CC = clang
CFLAGS = -Wall -Wextra -O2
FRAMEWORKS = -framework Foundation -framework AppKit
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin

.PHONY: all
all: $(TARGET)

$(TARGET): $(SOURCES)
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o $(TARGET) $(SOURCES)

.PHONY: install
install: $(TARGET)
	@echo "Installing $(TARGET) to $(BINDIR)..."
	install -d $(BINDIR)
	install -m 755 $(TARGET) $(BINDIR)/$(TARGET)
	@echo "Installation complete. You can now use '$(TARGET)' from anywhere."

.PHONY: uninstall
uninstall:
	@echo "Removing $(TARGET) from $(BINDIR)..."
	rm -f $(BINDIR)/$(TARGET)
	@echo "Uninstallation complete."

.PHONY: clean
clean:
	rm -f $(TARGET)

.PHONY: debug
debug: CFLAGS += -g -DDEBUG
debug: $(TARGET)

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all       - Build the program (default)"
	@echo "  install   - Install to $(BINDIR)"
	@echo "  uninstall - Uninstall from $(BINDIR)"
	@echo "  clean     - Remove build artifacts"
	@echo "  debug     - Build with debug symbols"
	@echo "  help      - Print this help message"
	@echo ""
	@echo "Variables:"
	@echo "  PREFIX    - Installation prefix (default: $(PREFIX))"
	@echo "  CC        - Compiler (default: $(CC))"
