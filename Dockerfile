# Base image https://hub.docker.com/u/rocker/
ARG SRC_TAG=3.6.3
ARG SRC_IMAGE=artificiallyintelligent/shiny_lite
FROM $SRC_IMAGE:$SRC_TAG

ARG $BLD_DATE
ARG $SRC_REPO
ARG $SRC_BRANCH
ARG $SRC_COMMIT
ARG $DEST_IMAGE

ENV BUILD_DATE=$BLD_DATE
ENV SOURCE_DOCKER_IMAGE=$SRC_IMAGE:$SRC_TAG
ENV SOURCE_REPO=$SRC_REPO
ENV SOURCE_BRANCH=$SRC_BRANCH
ENV SOURCE_COMMIT=$SRC_COMMIT
ENV DOCKER_IMAGE=$DEST_IMAGE

## install package dependcies
ARG DISCOVERY=TRUE
ARG PROJECT_PACKAGES=
ARG PROJECT_PACKAGES_PLUS=config,shiny,shinycssloaders,shinyjs,shinyWidgets,stringr,scales,waiter,dplyr,data.table,geojson,mongolite,ggplot2,ggiraph,ggiraphExtra,RColorBrewer,viridis,hrbrthemes,lattice,leaflet,units
# removed from PROJECT_PACKAGES_PLUS,readxl,geojsonio,sf,RMySQL,sf,V8,DBI,pool,protolite,rgeos,jqr,RPostgres
ARG DEPENDENCY=ALL

ENV DISCOVER_PACKAGES=$DISCOVERY
ENV REQUIRED_PACKAGES=$PROJECT_PACKAGES
ENV REQUIRED_PACKAGES_PLUS=$PROJECT_PACKAGES_PLUS
ENV DEPENDENCY_INSTALL=$DEPENDENCY

# ADD Rscripts/packages.csv ${LIB_DIR}/default_install_packages.csv
# ADD cont-init.d-defaults/install_discovered_packages.R ${LIB_DIR}/install_discovered_packages.R
# ADD cont-init.d-defaults/03_install_package_dependencies.sh  ${LIB_DIR}/cont-init.d-defaults/03_install_package_dependencies.sh
# ADD cont-init.d-defaults/04_install_packages.sh  ${LIB_DIR}/cont-init.d-defaults/04_install_packages.sh

RUN chmod +x ${LIB_DIR}/cont-init.d-defaults/* && \ 
	${LIB_DIR}/cont-init.d-defaults/03_install_package_dependencies.sh && \
	${LIB_DIR}/cont-init.d-defaults/04_install_packages.sh

COPY Rscripts $WWW_DIR

RUN ${LIB_DIR}/cont-init.d-defaults/03_install_package_dependencies.sh && \
	${LIB_DIR}/cont-init.d-defaults/04_install_packages.sh

ENV INSTALL_PACKAGE_AT_RUNTIME=FALSE

## start shiny server
RUN ln -f ${LIB_DIR}/shiny-server.sh /usr/bin/shiny-server.sh \
	&& chmod +x /usr/bin/shiny-server.sh

CMD ["/usr/bin/shiny-server.sh"]