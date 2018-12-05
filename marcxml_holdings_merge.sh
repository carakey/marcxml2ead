#!/bin/bash

for d in sample_data/catalog_export/* 
do 
	java -jar saxon9he.jar -s:marcxml_holdings_merge.xsl -xsl:marcxml_holdings_merge.xsl current_folder="$d"
done 