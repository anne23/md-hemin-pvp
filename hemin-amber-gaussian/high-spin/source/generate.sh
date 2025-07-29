#!/bin/bash
set -e

## Run using AmberTools25

## Based loosely on:
# - https://ambermd.org/tutorials/advanced/tutorial20/mcpbpy.php
# - https://ambermd.org/tutorials/advanced/tutorial20/mcpbpy_heme.php

## Prepare HEM.pdb
# We're using one with no Cl for now, will add Cl- ions later
# Original sdf file: https://files.rcsb.org/ligands/download/HEM_ideal.sdf
# - linked from https://www.rcsb.org/ligand/HEM
# - converted to pdb (TODO: script that too)
cp HEM_from_sdf.pdb HEM.pdb

## Protoporphyrin IX

# Everything except the Fe
awk '$1=="HETATM"' HEM.pdb | awk '$3!="FE"' > PIX.pdb
sed -i '' 's/UNK/PIX/g' PIX.pdb
pdb4amber -i PIX.pdb -o PIX_renum.pdb

# Charge: using -2 here because
# - the Fe will be +3, and we want +1 overall
# - the HEM_H pdb in the mcpbpy_heme tutorial uses -4 but the structure we've based
#   things on here has a couple of extra Hs attached to outer Cs compared to that
# Using gaff2 rather than the default because that's supposed to be better for this type of molecule
antechamber -fi pdb -fo mol2 -i PIX_renum.pdb -o PIX.mol2 -c bcc -pf y -nc -2 -at gaff2

# Generate the frcmod file
parmchk2 -i PIX.mol2 -o PIX.frcmod -f mol2

## Fe

# Make a separate FE pdb
awk '$1=="HETATM"' HEM.pdb | awk '$3=="FE"'> FE.pdb
sed -i '' 's/UNK/FE/g' FE.pdb

# Fe 3+
metalpdb2mol2.py -i FE.pdb -o FE.mol2 -c 3

## Make a combined pdb

cat PIX_renum.pdb FE.pdb | awk '$1!="END"' > HEM_combined.pdb
pdb4amber -i HEM_combined.pdb -o HEM_combined_renum.pdb

## Run MCPB.py

# Note: HEM_mcpb.in was created manually
# - ion_ids set to 75 because that's Fe in HEM_combined_renum.pdb
# - software_version is g16 because I think that's the version we're using
# - cut_off is 2.8 because that's the default other things seem to use
MCPB.py -i HEM_mcpb.in -s 1


## Prepare files for gaussian
# - HEM_small_opt.com
# - HEM_small_fc.com
# - HEM_large_mk.com
# - script file for the gaussian commands to run
tar -czvf hemin-gaussian.tar.gz \
    HEM_small_opt.com \
    HEM_small_fc.com \
    HEM_large_mk.com \
    gaussian-commands.sh \
    generate.sh \
    HEM_mcpb.in \
    HEM.pdb \
    PIX.pdb \
    PIX.mol2 \
    PIX.frcmod \
    FE.pdb \
    FE.mol2 \
    HEM_combined.pdb \
    README.txt
