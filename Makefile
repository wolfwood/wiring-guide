OPENSCAD=openscad
SCADFLAGS=-q --hardwarnings

SOCKETS=2 3 4
TARGET_prefixes=$(addprefix things/jig-,$(SOCKETS))
TARGETS=$(addsuffix -left.stl,$(TARGET_prefixes)) $(addsuffix -right.stl,$(TARGET_prefixes))

all: things/ $(TARGETS)

things/jig-%-left.stl: jig.scad
	$(OPENSCAD) $(SCADFLAGS) --render -Dsockets=$* -o $@ $<

things/jig-%-right.stl: jig.scad
	$(OPENSCAD) $(SCADFLAGS) --render -Dsockets=$* '-D$$mirror=true' -o $@ $<

things/:
	mkdir things

clean:
	-rm $(TARGETS)
