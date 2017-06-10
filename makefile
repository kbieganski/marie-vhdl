SOURCES=$(wildcard src/*.vhd)
OBJECTS=$(subst src/,obj/,$(subst .vhd,.o,$(SOURCES)))
TESTS=$(subst src/,,$(subst .vhd,,$(wildcard src/*_tb.vhd)))

tests: $(TESTS)

%_tb: obj/global_constants.o obj/utility.o $(OBJECTS)
	cd obj && ghdl -e --std=08 $@
	@mv obj/$@ .
	@echo "TEST START - $@"; echo "ghdl -r $@"
	@timeout 1 ghdl -r $@; echo "TEST END - $@"

obj/%.o: src/%.vhd
	@mkdir -p obj
	cd obj && ghdl -a --std=08 ../$<

clean:
	rm -rf obj *_tb
