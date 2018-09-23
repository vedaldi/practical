.PHONY: prepack, pack, pack-data, pack-code, post, clean, distclean

SHELL := /bin/bash
CURRENT_MAKEFILE_LIST := $(MAKEFILE_LIST)

pack-all: pack-data pack-code pack

tarflags=--exclude='.git*' --exclude='.build' --exclude='local' --exclude='*~'

DST := vgg@login.robots.ox.ac.uk:WWW/share

TMPDIR ?= /tmp

distname:=$(name)-$(ver)
#code:=$(addprefix "$(CURDIR)/",$(code))
#data:=$(addprefix "$(CURDIR)/",$(data))
deps:=$(shell find $(code) $(data) -type f)

# sed "s/ /\\\\ /g")

pack: $(TMPDIR)/$(distname).tar.gz
pack-data: $(TMPDIR)/$(distname)-data-only.tar.gz
pack-code: $(TMPDIR)/$(distname)-code-only.tar.gz

$(TMPDIR)/$(distname).tar.gz: $(deps)
	rm -rf $(TMPDIR)/$(distname)
	mkdir -p $(TMPDIR)/$(distname)/data
	ln -sf $(data) $(TMPDIR)/$(distname)/data/
	ln -sf $(code) $(TMPDIR)/$(distname)/
	tar -C $(TMPDIR) -cvh $(tarflags) $(distname)/ | gzip -n >$(TMPDIR)/$(distname).tar.gz

$(TMPDIR)/$(distname)-data-only.tar.gz: $(deps)
	rm -rf $(TMPDIR)/$(distname)
	mkdir -p $(TMPDIR)/$(distname)/data
	tar -C $(TMPDIR) -cvh $(tarflags) $(distname)/ | gzip -n >$(TMPDIR)/$(distname)-data-only.tar.gz 

$(TMPDIR)/$(distname)-code-only.tar.gz: $(deps)
	rm -rf $(TMPDIR)/$(distname)
	mkdir -p $(TMPDIR)/$(distname)/data
	ln -sf $(code) $(TMPDIR)/$(distname)/
	tar -C $(TMPDIR) -cvh $(tarflags) $(distname)/ | gzip -n >$(TMPDIR)/$(distname)-code-only.tar.gz

post: pack-all
	rsync -vt --progress "$(TMPDIR)/$(distname).tar.gz" "$(DST)/"
	rsync -vt --progress "$(TMPDIR)/$(distname)-data-only.tar.gz" "$(DST)/"
	rsync -vt --progress "$(TMPDIR)/$(distname)-code-only.tar.gz" "$(DST)/"

clean:
	find . -name '*~' -delete

distclean: clean
	rm -f $(TMPDIR)/$(distname)*.tar.gz
	rm -rf $(TMPDIR)/$(distname)/

info: info-dist

info-dist:
	@echo deps = $(deps)
	@echo name = $(name)
	@echo ver = $(ver)
	@echo distname = "$(distname)"
	@echo TMPDIR = "$(TMPDIR)"
