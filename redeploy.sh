#!/bin/bash

set -e
SECONDS=0

############ Runtime variables ############
DOCKERCMD=${DOCKERCMD:-docker}
# You can set DOCKERCOMPOSE to something like export DOCKERCOMPOSE="docker-compose -f /path/to/compose/compose/docker-compose.yml"
DOCKERCOMPOSE=${DOCKERCOMPOSE:-docker-compose}

# The directory where all the non-docker volumes will be persisted, and where the config files are located
VOLUMEROOT=${VOLUMEROOT:-$(pwd)}

# The location of the configuration directory (by default same directory as where the volumes are persisted)
CONFIGDIR=${CONFIGDIR:-$VOLUMEROOT/config/}

# The name of the network, as defined by docker-compose
NETWORK=${NETWORK:-customolsnet}

##############################################
############ Docker Configuration ############
##############################################

DOCKERRUN=$DOCKERCMD" run"

############ Volumes #########################
NEO4J_IMPORT_DIR=$VOLUMEROOT/oxo-neo4j-import
OLS_NEO4J_DATA=$VOLUMEROOT/ols-neo4j-data
OLS_NEO4J_DOWNLOADS=$VOLUMEROOT/ols-downloads
ZOOMA_DATA=$VOLUMEROOT/zooma-data

OLSCONFIGDIR=$CONFIGDIR/ols-config/
OXOCONFIGDIR=$CONFIGDIR/oxo-config/

############ Images ###########################
EBISPOT_OXOLOADER=ebispot/oxo-loader:dev
EBISPOT_OXOINDEXER=ebispot/oxo-indexer:dev
EBISPOT_OLSCONFIGIMPORTER=ebispot/ols-config-importer:stable
EBISPOT_OLSINDEXER=ebispot/ols-indexer:stable

# Necessary until fixed.
CUSTOM_OXOLOADER=matentzn/oxo-loader:0.0.1

######## Solr Services ########################
OXO_SOLR=http://oxo-solr:8983/solr
OLS_SOLR=http://ols-solr:8983/solr


##############################################
############ Pipeline ########################
##############################################

# We decided to expose the neo4j import directory for OxO as a local directory, because it is very useful for debugging 
# (checking the generated mapping tables etc). All other volumes are created and managed by docker-compose
echo "WARNING: Removing all existing indexed data"
echo "Warning: not removing $OLS_NEO4J_DOWNLOADS"
rm -rfv "$NEO4J_IMPORT_DIR" "$OLS_NEO4J_DATA" "$ZOOMA_DATA"
mkdir -vp "$NEO4J_IMPORT_DIR" "$OLS_NEO4J_DATA" "$OLS_NEO4J_DOWNLOADS" "$ZOOMA_DATA"
mkdir -vp "$ZOOMA_DATA"/index/lucene/annotation \
          "$ZOOMA_DATA"/index/lucene/annotation_count \
          "$ZOOMA_DATA"/index/lucene/annotation_summary \
          "$ZOOMA_DATA"/index/lucene/property \
          "$ZOOMA_DATA"/index/lucene/property_type

# 1. Make sure the OLS/OXO instances are currently not running, or if so, shut them down.
# Note that during development, we are using the `-v` option to ensure that unused volumes are cleared as well.
# https://docs.docker.com/compose/reference/down/
echo "INFO: Shutting any running services down... ($SECONDS sec)"
$DOCKERCOMPOSE down -v

# 2. Start Mongo and solr for OLS which are required for the data loading and indexing.
echo "INFO: Starting up Mongo and Solr services... ($SECONDS sec)"
$DOCKERCOMPOSE up -d ols-solr ols-mongo
# We are sleeping a bit to give the solr and mongo instances time to properly start up before running the data pipeline.
sleep 30

# 3. We are importing the ols-configuration file, which contains the list of ontologies to be loaded, as well their locations.
echo "INFO: OLS - Importing config... ($SECONDS sec)"
$DOCKERRUN --network "$NETWORK" -v "$OLSCONFIGDIR":/config \
           -e spring.data.mongodb.host=ols-mongo "$EBISPOT_OLSCONFIGIMPORTER"

# 4. This step indexes the OLS using the list of ontologies configured in the previous step.
# you could mount  here to inspect the downloaded ontologies
# Tried this because of some irrelevant noise in the DEBUG level log, but failed. -v $OLSCONFIGDIR/simplelogger.properties:/simplelogger.properties -e JAVA_OPTS=-Dlog4j.configuration=file:/simplelogger.properties
echo "INFO: OLS - Indexing OLS... ($SECONDS sec)"
$DOCKERRUN --network "$NETWORK" -v "$OLS_NEO4J_DATA":/mnt/neo4j -v "$OLS_NEO4J_DOWNLOADS":/mnt/downloads \
           -e spring.data.mongodb.host=ols-mongo \
           -e spring.data.solr.host="$OLS_SOLR" "$EBISPOT_OLSINDEXER"

# 5. Now, we start the remaining services. It is important that ols-web is not running at indexing time. 
# This is a shortcoming in the OLS archticture and will likely be solved in future versions
echo "INFO: Firing up remaining services (ols-web, oxo-solr, oxo-neo4j, oxo-web)... ($SECONDS sec)"
$DOCKERCOMPOSE up -d ols-web oxo-solr oxo-neo4j oxo-web
sleep 100 # Giving the services some time to start. 
# Note, in some environments, 50 seconds may not be sufficient; errors revolving around
# failed connections indicate that you should have waited longer. In that case, increase the sleep time, or better yet, implement a health check before proceeding.

# 6. Now we are extracting the datasets directly from OLS; this basically works on the assumption 
# that the loaded data dictionaries contain the appropriate xrefs (see Step 8). The output of this process is datasources.csv
# which should be in the directory that is mounted to `/mnt/neo4j` (at the time of documentation: $NEO4J_IMPORT_DIR).
echo "INFO: OXO - Extract datasets... ($SECONDS sec)"
$DOCKERRUN -v "$OXOCONFIGDIR"/oxo-config.ini:/mnt/config.ini \
    -v "$OXOCONFIGDIR"/idorg.xml:/mnt/idorg.xml \
    -v "$NEO4J_IMPORT_DIR":/mnt/neo4j \
    --network "$NETWORK" \
    -it "$EBISPOT_OXOLOADER" python /opt/oxo-loader/OlsDatasetExtractor.py -c /mnt/config.ini -i /mnt/idorg.xml -d /mnt/neo4j/datasources.csv

# 7. This process loads the datasets declared in the datasources.csv file into the Oxo internal neo4j instance, but nothing else (not the mappings)
echo "INFO: OXO - Load datasets... ($SECONDS sec)"
$DOCKERRUN -v "$OXOCONFIGDIR"/oxo-config.ini:/mnt/config.ini \
    -v "$NEO4J_IMPORT_DIR":/var/lib/neo4j/import \
    --network "$NETWORK" \
    -it "$EBISPOT_OXOLOADER" python /opt/oxo-loader/OxoNeo4jLoader.py -c /mnt/config.ini -W -d datasources.csv

# 8. This process extracts the xref mappings from OLS and exports them into OxO format.
# The result of this process are the two files terms.csv and mappings.csv
echo "INFO: OXO - Extract mappings... ($SECONDS sec)"
$DOCKERRUN -v "$OXOCONFIGDIR"/oxo-config.ini:/mnt/config.ini \
    -v "$NEO4J_IMPORT_DIR":/mnt/neo4j \
    --network "$NETWORK" \
    -it $CUSTOM_OXOLOADER python /opt/oxo-loader/OlsMappingExtractor.py -c /mnt/config.ini -t /mnt/neo4j/terms.csv -m /mnt/neo4j/mappings.csv

# 9. This process finally loads the mappings into Neo4j.
echo "INFO: OXO - Load mappings... ($SECONDS sec)"
$DOCKERRUN -v "$OXOCONFIGDIR"/oxo-config.ini:/mnt/config.ini \
    -v "$NEO4J_IMPORT_DIR":/var/lib/neo4j/import \
    --network "$NETWORK" \
    -it $EBISPOT_OXOLOADER python /opt/oxo-loader/OxoNeo4jLoader.py -c /mnt/config.ini -t terms.csv -m mappings.csv

# 10. Finally, the mappings are indexed in SOLR.
echo "INFO: OXO - Index mappings... ($SECONDS sec)"
$DOCKERRUN --network "$NETWORK" \
           -e spring.data.solr.host=$OXO_SOLR \
           -e oxo.neo.uri=http://neo4j:dba@oxo-neo4j:7474 $EBISPOT_OXOINDEXER

echo "Running Zooma"
sleep 50
$DOCKERCOMPOSE up -d zooma-web

echo "INFO: Redploying Custom OLS/OXO pipeline completed in $SECONDS seconds!"
