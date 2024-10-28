OPENSCAD=openscad
SCADFLAGS = -q --hardwarnings

MANIFOLD_FEATURE := $(shell $(OPENSCAD) --version --enable manifold > /dev/null 2>&1; echo $$?)
MANIFOLD_BACKEND := $(shell $(OPENSCAD) --version --backend manifold > /dev/null 2>&1; echo $$?)

ifeq ($(MANIFOLD_BACKEND), 0)
	SCADFLAGS += --backend manifold
else
ifeq ($(MANIFOLD_FEATURE), 0)
	SCADFLAGS += --enable manifold
endif
endif


SOCKETS=2 3 4
RULERS=$(addsuffix .stl,$(addprefix things/ruler-,$(SOCKETS)))
JIG_prefixes=$(addprefix things/jig-,$(SOCKETS))
TARGETS=$(addsuffix -left.stl,$(JIG_prefixes)) $(addsuffix -right.stl,$(JIG_prefixes)) $(RULERS)


all: things/ $(TARGETS)

-include .*.depends


things/jig-%-left.stl: jig.scad
	$(OPENSCAD) $(SCADFLAGS) --render -Dsockets=$* -o $@ $<

things/jig-%-right.stl: jig.scad
	$(OPENSCAD) $(SCADFLAGS) --render -Dsockets=$* '-D$$mirror=true' -o $@ $<

things/ruler-%.stl: ruler.scad
	$(OPENSCAD) $(SCADFLAGS) -d .ruler.depends --render -Dsockets=$* -o $@ $<


things/:
	mkdir things

clean:
	-rm $(TARGETS) .ruler.depends
