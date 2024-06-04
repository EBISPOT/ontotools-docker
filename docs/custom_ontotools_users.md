# List of custom OntoTools installations

Most custom OLS, OxO or Zooma installations are unknown and will not be accessible to the public. This page is intended to trace custom OLS installations that are public, and describe their use cases.


# International HundredK+ Cohorts Consortium (IHCC) - Data harmonisation effort

The [IHCC](https://ihccglobal.org/) aims "to create a global network for translational research that utilises large cohorts to enhance the understanding of the biological and genetic basis of disease and improve clinical care and population health." As part of their effort to harmonise data dictionaries across cohorts using their Genomics Cohorts Knowledge Ontology (GECKO), they offer dictionaries and mapping services delivered through the OntoTools stack. More information [here](https://ihcc-cohorts.github.io/).

* The IHCC ontology lookup service: https://registry.ihccglobal.app/index
* The IHCC mapping service: https://mapping.ihccglobal.app/zooma/
* The IHCC mapping browser: https://mapping.ihccglobal.app/search 

Technical notes: IHCC uses a docker-compose setup of the OntoTools.

# Monarch Initiative - Harmonising phenotype data to improve variant prioritisation for clinical diagnosis

The [Monarch Initiative](https://monarchinitiative.org/) aims to integrate data connecting phenotypes to genotypes across species, bridging basic and applied research with semantics-based analysis. 

In order to showcase work in progress ontologies that are not official published yet (such as the second iteration of the Unified Phenotype Ontology ([uPheno 2](https://ols.monarchinitiative.org/ontologies/upheno2)), or the [Monochrom Ontology](https://ols.monarchinitiative.org/ontologies/chr)), Monarch maintains a custom installation of OLS. A further use case is to provide developers with access of weekly snapshots of development versions of key ontologies such as the Human Phenotype Ontology or CL.


# Human Cell Atlas

The [International Human Cell Atlas initiative](https://www.humancellatlas.org/) aims to create comprehensive reference maps of all human cells—the fundamental units of life—as a basis for both understanding human health and diagnosing, monitoring, and treating disease.

A selection of ontologies key to the HCA effort is accessible via their custom OLS installation [here](https://ontology.archive.data.humancellatlas.org/index).

# SemLookP

The Semantic Lookup Platform **SemLookP** hosted by the [ZB MED - Information Centre for Life Sciences](https://www.zbmed.de/en/) should be used in the biomedical domain. We want to use the system as a backbone service for different other services. SemLookP should help us in the following task:

- Create (semi-)automatic annotations for research data
- Set up an enriched semantic search service
- Give additional information about a specific terminology resource

Our SemLookP services are accessible under:
- terminology service: https://semanticlookup.zbmed.de/ols/index
- mapping service: https://semanticlookup.zbmed.de/mappings/

One of our first use cases where we use SemLookP to show additional information for a concept is our COVID-19 preprint viewer [preVIEW](https://preview.zbmed.de/).

# TIB 
The TIB main instance: https://terminology.tib.eu/ts/index.

Other services are:
- https://terminology.nfdi4chem.de/ts
- https://terminology.nfdi4ing.de/ts/

These three are using the same backend and using the parameter collection to identify the wished subset of ontologies in the TIB General.

# The Anthropological Notation Ontology
https://ols.imise.uni-leipzig.de/ontologies/anno




