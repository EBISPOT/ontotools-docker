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

echo "INFO: Shutting down ols-web for indexing... ($SECONDS sec)"
$DOCKERCOMPOSE rm -f -s -v ols-web
sleep 5

echo "INFO: OLS - Importing config... ($SECONDS sec)"
$DOCKERRUN --network "$NETWORK" -v "$OLSCONFIGDIR":/config \
           -e spring.data.mongodb.host=ols-mongo "$EBISPOT_OLSCONFIGIMPORTER"

echo "INFO: OLS - Indexing OLS... ($SECONDS sec)"
$DOCKERRUN --network "$NETWORK" -v "$OLS_NEO4J_DATA":/mnt/neo4j -v "$OLS_NEO4J_DOWNLOADS":/mnt/downloads \
           -e spring.data.mongodb.host=ols-mongo \
           -e spring.data.solr.host="$OLS_SOLR" "$EBISPOT_OLSINDEXER"

echo "INFO: Firing up OLS again ($SECONDS sec)"
$DOCKERCOMPOSE up -d ols-web
sleep 30 # Giving the services some time to start. 

echo "INFO: OXO - Extract datasets... ($SECONDS sec)"
$DOCKERRUN -v "$OXOCONFIGDIR"/oxo-config.ini:/mnt/config.ini \
    -v "$OXOCONFIGDIR"/idorg.xml:/mnt/idorg.xml \
    -v "$NEO4J_IMPORT_DIR":/mnt/neo4j \
    --network "$NETWORK" \
    -it "$EBISPOT_OXOLOADER" python /opt/oxo-loader/OlsDatasetExtractor.py -c /mnt/config.ini -i /mnt/idorg.xml -d /mnt/neo4j/datasources.csv

echo "INFO: OXO - Load datasets... ($SECONDS sec)"
$DOCKERRUN -v "$OXOCONFIGDIR"/oxo-config.ini:/mnt/config.ini \
    -v "$NEO4J_IMPORT_DIR":/var/lib/neo4j/import \
    --network "$NETWORK" \
    -it "$EBISPOT_OXOLOADER" python /opt/oxo-loader/OxoNeo4jLoader.py -c /mnt/config.ini -W -d datasources.csv

echo "INFO: OXO - Extract mappings... ($SECONDS sec)"
$DOCKERRUN -v "$OXOCONFIGDIR"/oxo-config.ini:/mnt/config.ini \
    -v "$NEO4J_IMPORT_DIR":/mnt/neo4j \
    --network "$NETWORK" \
    -it $CUSTOM_OXOLOADER python /opt/oxo-loader/OlsMappingExtractor.py -c /mnt/config.ini -t /mnt/neo4j/terms.csv -m /mnt/neo4j/mappings.csv

echo "INFO: OXO - Load mappings... ($SECONDS sec)"
$DOCKERRUN -v "$OXOCONFIGDIR"/oxo-config.ini:/mnt/config.ini \
    -v "$NEO4J_IMPORT_DIR":/var/lib/neo4j/import \
    --network "$NETWORK" \
    -it $EBISPOT_OXOLOADER python /opt/oxo-loader/OxoNeo4jLoader.py -c /mnt/config.ini -t terms.csv -m mappings.csv

echo "INFO: OXO - Index mappings... ($SECONDS sec)"
$DOCKERRUN --network "$NETWORK" \
           -e spring.data.solr.host=$OXO_SOLR \
           -e oxo.neo.uri=http://neo4j:dba@oxo-neo4j:7474 $EBISPOT_OXOINDEXER

echo "INFO: ZOOMA - Updating Zooma mappings... ($SECONDS sec)"
$DOCKERCOMPOSE rm -f -s -v zooma-web
$DOCKERCOMPOSE up -d zooma-web

echo "INFO: Reindexing CUSTOM OLS/OXO pipeline completed in $SECONDS seconds!"

