MARKER = .done
TCL_SCRIPT = arquivo.tcl
INPUT_FILE = contador_netlist.tcl

all: run_script $(MARKER)

$(MARKER): $(TCL_SCRIPT)
	@echo "Rodando script TCL..."
	tclsh $(TCL_SCRIPT) $(INPUT_FILE)
	touch $(MARKER)

run_script:
	@echo "Rodando script shell..."
	bash script1.sh .

clean:
	rm -rf $(MARKER) md tcl txt sh