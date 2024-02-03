URIBASE = http://purl.obolibrary.org/obo

ROBOT=robot
# the below onts were collected from ols-config.yaml
# (note that .owl is appended to each of these later on, so there's no need to add it here)
ONTS = upheno2 upheno-patterns vbo-edit hp-edit chr mondo-edit mondo-rare mondo-patterns hp-branch-lymphoma omim

#monarch
ONTFILES = $(foreach n, $(ONTS), ontologies/$(n).owl)
VERSION = "0.0.3" 
IM=monarchinitiative/monarch-ols
OLSCONFIG=/opt/ols/ols-config.yaml

# Download and pre-process the ontologies
clean:
	rm -rf ontologies/*

ontologies: $(ONTFILES)

ontologies/mondo-branch-%.owl:
	mkdir -p github && mkdir -p github/mondo-branch-$* && rm -rf github/mondo-branch-$*/*
	cd github/mondo-branch-$* && git clone --depth 1 https://github.com/monarch-initiative/mondo.git -b $* 
	cd github/mondo-branch-$*/mondo/src/ontology/ && make IMP=false PAT=false MIR=false mondo.owl
	cp github/mondo-branch-$*/mondo/src/ontology/mondo.owl $@

ontologies/mondo-edit.owl:
	mkdir -p github && mkdir -p github/main && rm -rf github/main/*
	cd github/main && git clone --depth 1 https://github.com/monarch-initiative/mondo.git
	cd github/main/mondo/src/ontology/ && make IMP=false PAT=false MIR=false mondo.owl
	cp github/main/mondo/src/ontology/mondo.owl $@

ontologies/hp-branch-%.owl:
	mkdir -p github && mkdir -p github/hp-branch-$* && rm -rf github/hp-branch-$*/*
	cd github/hp-branch-$* && git clone --depth 1 https://github.com/obophenotype/human-phenotype-ontology.git -b $* 
	cd github/hp-branch-$*/human-phenotype-ontology/src/ontology/ && make IMP=false PAT=false MIR=false hp.owl
	cp github/hp-branch-$*/human-phenotype-ontology/src/ontology/hp.owl $@

ontologies/hp-edit.owl:
	mkdir -p github && mkdir -p github/main && rm -rf github/main/*
	cd github/main && git clone --depth 1 https://github.com/obophenotype/human-phenotype-ontology.git
	cd github/main/human-phenotype-ontology/src/ontology/ && make IMP=false PAT=false MIR=false hp.owl
	cp github/main/human-phenotype-ontology/src/ontology/hp.owl $@

ontologies/vbo-edit.owl:
	mkdir -p github && mkdir -p github/main && rm -rf github/main/*
	cd github/main && git clone --depth 1 https://github.com/monarch-initiative/vertebrate-breed-ontology.git
	cd github/main/vertebrate-breed-ontology/src/ontology/ && make IMP=false PAT=false MIR=false vbo.owl -B
	cp github/main/vertebrate-breed-ontology/src/ontology/vbo.owl $@

ontologies/chr.owl: 
	$(ROBOT) convert -I https://raw.githubusercontent.com/monarch-initiative/monochrom/master/chr.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/omim.owl: 
	$(ROBOT) convert -I https://github.com/monarch-initiative/omim/releases/latest/download/omim.owl -o $@.tmp.owl && mv $@.tmp.owl $@

UPHENO_URL=https://github.com/obophenotype/upheno-dev/releases/download/v2023-10-27/upheno_all.owl

ontologies/upheno2.owl: 
	$(ROBOT) -vv merge -I $(UPHENO_URL) \
	remove --term-file src/remove_terms.txt \
	annotate --link-annotation http://purl.obolibrary.org/obo/IAO_0000700 http://purl.obolibrary.org/obo/UPHENO_0001001 -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/upheno-patterns.owl:
	$(ROBOT) convert -I https://raw.githubusercontent.com/obophenotype/upheno/master/src/patterns/pattern.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/mondo-patterns.owl:
	$(ROBOT) convert -I https://raw.githubusercontent.com/monarch-initiative/mondo/master/src/patterns/pattern.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/mondo-rare.owl:
	$(ROBOT) convert -I http://purl.obolibrary.org/obo/mondo/subsets/mondo-rare.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/uberon-human-view.owl:
	$(ROBOT) convert -I http://purl.obolibrary.org/obo/uberon/subsets/human-view.owl -o $@.tmp.owl && mv $@.tmp.owl $@
