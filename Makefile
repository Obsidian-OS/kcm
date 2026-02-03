PREFIX ?= /usr
BUILD_DIR ?= build
CMAKE_FLAGS ?= -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PREFIX)

.PHONY: all build install uninstall clean rebuild configure

all: build

configure:
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && cmake $(CMAKE_FLAGS) ..

build: configure
	@cmake --build $(BUILD_DIR) --parallel

install: build
	@DESTDIR=$(DESTDIR) cmake --install $(BUILD_DIR)

uninstall:
	@if [ -f $(BUILD_DIR)/install_manifest.txt ]; then \
		xargs rm -f < $(BUILD_DIR)/install_manifest.txt; \
	else \
		echo "No install manifest found. Run 'make install' first."; \
	fi

clean:
	@rm -rf $(BUILD_DIR)

rebuild: clean build

debug:
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=$(PREFIX) ..
	@cmake --build $(BUILD_DIR) --parallel

test: build
	@cd $(BUILD_DIR) && ctest --output-on-failure

package: build
	@cd $(BUILD_DIR) && cpack

help:
	@echo "ObsidianOS KCM Module Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build the project (default)"
	@echo "  configure - Run CMake configuration"
	@echo "  build     - Build the project"
	@echo "  install   - Install to system (requires root)"
	@echo "  uninstall - Remove installed files (requires root)"
	@echo "  clean     - Remove build directory"
	@echo "  rebuild   - Clean and rebuild"
	@echo "  debug     - Build with debug symbols"
	@echo "  test      - Run tests"
	@echo "  package   - Create distribution package"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  PREFIX=$(PREFIX)"
	@echo "  BUILD_DIR=$(BUILD_DIR)"
	@echo "  CMAKE_FLAGS=$(CMAKE_FLAGS)"
