SOURCES=$(wildcard src/*.vhd)
OBJECTS=$(subst src/,obj/,$(subst .vhd,.o,$(SOURCES)))
TESTS=$(subst src/,,$(subst .vhd,,$(wildcard src/*_tb.vhd)))

tests: $(TESTS)

%_tb: $(OBJECTS)
	cd obj && ghdl -e $@
	@mv obj/$@ .
	@echo "TEST START - $@"; echo "ghdl -r $@"
	@timeout 1 ghdl -r $@; echo "TEST END - $@"

obj/%.o: src/%.vhd
	@mkdir -p obj
	cd obj && ghdl -a ../$<

clean:
	rm -rf obj *_tb
