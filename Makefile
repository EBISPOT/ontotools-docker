URIBASE = http://purl.obolibrary.org/obo

# the below onts were collected from ols-config.yaml
# (phenio is commented out until we produce a version of the file without cycles)
ONTS = upheno2 geno upheno_patterns hp chr mondo mondo_patterns mondo-harrisons-view uberon-human-view phenio

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

# echo "  - id: mondo_issue$*" >> $(OLSCONFIG)
# echo "    preferredPrefix: MONDO_ISSUE$*" >> $(OLSCONFIG)
# echo "    title: Mondo Disease Ontology - Issue $* (Developmental Snapshot)" >> $(OLSCONFIG)
# echo "    uri: http://purl.obolibrary.org/obo/mondo/mondo-issue-$*.owl" >> $(OLSCONFIG)
# echo "    definition_property:" >> $(OLSCONFIG)
# echo "      - http://purl.obolibrary.org/obo/IAO_0000115" >> $(OLSCONFIG)
# echo "    reasoner: EL" >> $(OLSCONFIG)
# echo "    oboSlims: false" >> $(OLSCONFIG)
# echo "    ontology_purl : file:/opt/ols/$@" >> $(OLSCONFIG)

ontologies/%.owl: 
	$(ROBOT) convert -I $(URIBASE)/$*.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/hp.owl: 
	$(ROBOT) convert -I https://ci.monarchinitiative.org/job/hpo-pipeline-dev2/lastSuccessfulBuild/artifact/hp.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/mondo.owl: 
	$(ROBOT) convert -I https://ci.monarchinitiative.org/job/mondo-build/lastSuccessfulBuild/artifact/src/ontology/mondo.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/mondo-harrisons-view.owl: 
	$(ROBOT) convert -I https://ci.monarchinitiative.org/job/mondo-build/lastSuccessfulBuild/artifact/src/ontology/modules/mondo-harrisons-view.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/chr.owl: 
	$(ROBOT) convert -I https://raw.githubusercontent.com/monarch-initiative/monochrom/master/chr.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/upheno2.owl: 
	$(ROBOT) -vv merge -I https://bbop-ontologies.s3.amazonaws.com/upheno/current/upheno-release/all/upheno_all_with_relations.owl \
	remove --term-file src/remove_terms.txt \
	annotate --link-annotation http://purl.obolibrary.org/obo/IAO_0000700 http://purl.obolibrary.org/obo/UPHENO_0001001 -o $@.tmp.owl && mv $@.tmp.owl $@
	
ontologies/upheno_patterns.owl:
	$(ROBOT) convert -I https://raw.githubusercontent.com/obophenotype/upheno/master/src/patterns/pattern.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/mondo_patterns.owl:
	$(ROBOT) convert -I https://raw.githubusercontent.com/monarch-initiative/mondo/master/src/patterns/pattern.owl -o $@.tmp.owl && mv $@.tmp.owl $@

HUMAN_VIEW=http://purl.obolibrary.org/obo/uberon/subsets/human-view.owl

ontologies/uberon-human-view.owl:
	$(ROBOT) convert -I $(HUMAN_VIEW) -o $@.tmp.owl && mv $@.tmp.owl $@

PHENIO_URL=https://github.com/monarch-initiative/phenio/releases/latest/download/phenio.owl

ontologies/phenio.owl:
	$(ROBOT) convert -I $(PHENIO_URL) -o $@.tmp.owl && mv $@.tmp.owl $@

VBO_URL=https://raw.githubusercontent.com/monarch-initiative/vertebrate-breed-ontology/master/vbo.owl

ontologies/vbo.owl:
	$(ROBOT) convert -I $(VBO_URL) -o $@.tmp.owl && mv $@.tmp.owl $@

#ontologies/monarch.owl:
#	$(ROBOT) convert -I https://ci.monarchinitiative.org/job/monarch-owl-pipeline/lastSuccessfulBuild/artifact/src/ontology/mo.owl -o $@.tmp.owl && mv $@.tmp.owl $@

