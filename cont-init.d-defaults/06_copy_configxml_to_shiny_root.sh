#!/bin/bash 

# Copy container ENV variables to .Reviron so they will be available to shiny
mkdir -p $LIB_DIR/config_mount
cp -rf $LIB_DIR/config_mount $WWW_DIR