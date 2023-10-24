URIBASE = http://purl.obolibrary.org/obo

ROBOT=robot
# the below onts were collected from ols-config.yaml
# (phenio is commented out until we produce a version of the file without cycles)
ONTS = upheno2 upheno-patterns hp-edit chr mondo-edit mondo-rare #mondo-patterns

#monarch
ONTFILES = $(foreach n, $(ONTS), ontologies/$(n).owl)
VERSION = "0.0.3" 
IM=monarchinitiative/monarch-ols
OLSCONFIG=/opt/ols/ols-config.yaml

# Download and pre-process the ontologies
clean:
	rm -rf ontologies/*

ontologies: $(ONTFILES)

ontologies/mondo-issue-%.owl:
	mkdir -p github && mkdir -p github/mondo-issue-$* && rm -rf github/mondo-issue-$*/*
	cd github/mondo-issue-$* && git clone --depth 1 https://github.com/monarch-initiative/mondo.git -b issue-$* 
	$(ROBOT) merge -i github/mondo-issue-$*/mondo/src/ontology/mondo-edit.obo --catalog github/mondo-issue-$*/mondo/src/ontology/catalog-v001.xml remove --select ontology reason --reasoner ELK -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/mondo-edit.owl:
	mkdir -p github && mkdir -p github/main && rm -rf github/main/*
	cd github/main && git clone --depth 1 https://github.com/monarch-initiative/mondo.git
	cd github/main/mondo/src/ontology/ && make IMP=false PAT=false MIR=false mondo.owl
	cp github/main/mondo/src/ontology/mondo.owl $@

ontologies/%.owl: 
	$(ROBOT) convert -I $(URIBASE)/$*.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/hp-edit.owl:
	mkdir -p github && mkdir -p github/main && rm -rf github/main/*
	cd github/main && git clone --depth 1 https://github.com/obophenotype/human-phenotype-ontology.git
	cd github/main/human-phenotype-ontology/src/ontology/ && make IMP=false PAT=false MIR=false hp.owl
	cp github/main/human-phenotype-ontology/src/ontology/hp.owl $@

ontologies/chr.owl: 
	$(ROBOT) convert -I https://raw.githubusercontent.com/monarch-initiative/monochrom/master/chr.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/upheno2.owl: 
	$(ROBOT) -vv merge -I https://bbop-ontologies.s3.amazonaws.com/upheno/current/upheno-release/all/upheno_all_with_relations.owl \
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