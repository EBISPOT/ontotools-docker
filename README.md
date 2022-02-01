# OntoTools Deployment Pipeline

The EBI Ontology Tools (consisting of OLS, OxO and Zooma) are available as docker containers. These containers are provided in the following 2 ways:

* Standalone applications: This is for users who want to only run an instance of OLS (or OxO or Zooma), rather than the complete Ontology Tools stack.
* Full Ontology Tools stack: This is for users who want to run the full Ontology Tools stack consisting of OLS, OxO and Zooma.

This repository contains the official Dockerised deployment pipeline for the **Full Ontology Tools stack**. For instructions for the standalone applications, see the [OLS](http://github.com/EBISPOT/OLS), [OxO](http://github.com/EBISPOT/OXO), or [ZOOMA](http://github.com/EBISPOT/ZOOMA) repositories respectively.

# Instructions

First, install Git, Docker and Docker compose. On an Ubuntu server:

    apt install git docker.io
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

To use Docker without `sudo`, make sure your user is in the `docker` group. For example, if your username is `spot`:

    sudo usermod -aG docker spot
  
Next, clone this repository:

    git clone https://github.com/EBISPOT/ontotools-docker.git
    cd ontotools-docker

The configuration options for each of the OntoTools can be found in the `config` directory. For example, to change the OLS configuration, edit the files in `config/ols-config`.
   
Finally, run the `redeploy.sh` script to deploy the OntoTools stack:

    ./redeploy.sh
    
To update the data in your OntoTools instances, run the `update-data.sh` script:

    ./update-data.sh
   
# Customisation

It is possible to customise several branding options for the OntoTools by editing `docker-compose.yml`:

## OLS

* `ols.customisation.debrand` — If set to true, removes the EBI header and footer, documentation, and about page
* `ols.customisation.title` — A custom title for your instance, e.g. "My OLS Instance"
* `ols.customisation.short-title` — A shorter version of the custom title, e.g. "MYOLS"
* `ols.customisation.description` — A description of the instance
* `ols.customisation.org` — The organisation hosting your instance
* `ols.customisation.web` — Url of the website for your organization.
* `ols.customisation.twitter` — Handle to the Twitter account of your organisation.
* `ols.customisation.issuesPage` — Url for the issue tracker for your organisation.
* `ols.customisation.supportMail` — Email address where people can contact you.
* `ols.customisation.hideGraphView` — Set to true to hide the graph view 
* `ols.customisation.errorMessage` — Message to show on error pages
* `ols.customisation.ontologyAlias` — A custom word or phrase to use instead of "Ontology", e.g. "Data Dictionary"
* `ols.customisation.ontologyAliasPlural` — As `ontologyAlias` but plural, e.g. "Data Dictionaries"
* `ols.customisation.oxoUrl` — The URL of an OxO instance to link to with a trailing slash e.g. `https://www.ebi.ac.uk/spot/oxo/

## OxO

* `oxo.customisation.debrand` — If set to true, removes the EBI header and footer, documentation, and about page
* `oxo.customisation.title` — A custom title for your instance, e.g. "My OxO Instance"
* `oxo.customisation.short-title` — A shorter version of the custom title, e.g. "MYOxO"
* `oxo.customisation.description` — A description of the instance
* `oxo.customisation.org` — The organisation hosting your instance

# Pipeline

The OLS/OXO/Zooma pipeline (just "pipeline" from now on) supports the following workflows:

1. Deploying a new OLS/OXO/Zooma instance entirely using docker containers, using `docker-compose`.
2. Re-indexing OLS/OXO when the data changes.

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

## Custom installations

We have started to maintain a [list of known custom OLS installations](docs/custom_ontotools_users.md). Please create an issue if you want your installation to be listed as well.
