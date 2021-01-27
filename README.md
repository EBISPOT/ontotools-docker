# CUSTOM OntoTools Deployment Pipeline

The OLS/OXO/Zooma pipeline (just "pipeline" from now on) supports the following workflows:

1. Deploying a new OLS/OXO/Zooma instance entirely using docker containers, using `docker-compose`.
2. Re-indexing OLS/OXO when the data changes.

# Server Configuration

Install prerequisties: Docker, Docker Compose

# Pipeline

The pipeline performs the following steps, which are encoded as as series of docker commands in [redeploy.sh](redeploy.sh). Note that [update-data.sh](update-data.sh) can be used to _just_ reindex the data, without actually stopping most of the services. It is, due to the low overall runtime of the script, not necessary to use update-data.sh (you can simply always use redeploy.sh).

1. Starting ols-solr and ols-mongo instance
2. Import OLS config from [config/ols-config](config/ols-config).
3. Index ontologies in OLS
4. Start the remaining services (ols-web oxo-solr oxo-neo4j oxo-web). It is important that ols-web is not running at indexing time. This is a shortcoming in the OLS architecture and will likely be solved in future versions.
5. Extract all datasets from OLS for OxO processing
6. Load datasets (not mappings) into OxO Neo4j
7. Extract the xref mappings from OLS and exports them into OxO format.
8. Loads the mappings into OxO Neo4j
9. Index mappings in solr

## WARNING

We are currently using the IHCC images instead of the official EBI ones.. We should use those, but last time I checked they were not up to date.

## Custom installations

We have started to maintain a [list of known custom OLS installations](docs/custom_ontotools_users.md). Please create an issue if you want your installation to be listed as well.
