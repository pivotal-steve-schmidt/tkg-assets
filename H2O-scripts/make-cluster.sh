#!/bin/bash

. ./config

cat ${TEMPLATE} | \
  sed -e "s/CLUSTERNAME/${PRODCLUSTERNAME}/" \
      -e "s/NAMESPACE/${NAMESPACE}/" \
      -e "s/VERSION/${VERSION}/" \
      -e "s/pacific-gold-storage-policy/${STORAGECLASS}/" \
        > ${PRODCLUSTERNAME}.yaml

cat ${TEMPLATE} | \
  sed -e "s/CLUSTERNAME/${TESTCLUSTERNAME}/" \
      -e "s/NAMESPACE/${NAMESPACE}/" \
      -e "s/VERSION/${VERSION}/" \
      -e "s/pacific-gold-storage-policy/${STORAGECLASS}/" \
        > ${TESTCLUSTERNAME}.yaml

echo "Created cluster config files:"
ls -l ${TESTCLUSTERNAME}.yaml ${PRODCLUSTERNAME}.yaml
