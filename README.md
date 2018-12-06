# MARCXML to EAD for LSU ArchivesSpace

## About MARCXML2EAD

This repository features an XSLT 2.0 stylesheet, _marcxml2ead.xsl_, which transforms MARCXML exported from the library catalog into EAD for ingest to ArchivesSpace. It attempts to adhere as closely as possible to local LSU Special Collections EAD templates and guidelines.

Specific template logic is documented within the XSLT stylesheet itself.

The stylesheet was originally based on the XSLT at https://github.com/MSU-Libraries/MARCtoEADforASpace.  

Notes on source data:

- XML files exported from LSU's catalog had no namespace declarations
- Holdings records were combined with bibliographic records using the supporting XSLT stylesheet _marcxml_holdings_merge.xsl_; see section on [Merging Holdings into MARCXML](#merging-holdings-into-marcxml) for more information.


## Process  

To run _marcxml2ead.xsl_ with Saxon, execute the following:

`java -jar saxon9he.jar -s:sample_data/merged_records/ -xsl:marcxml2ead.xsl -o:sample_data/ead/`

- Update _-s_ with the path to your source directory.
- Update _-o_ with the path to your output directory.

See [Notes on Processing with Saxon](#notes-on-processing-with-saxon), below.


## Merging Holdings into MARCXML  

The export of MARCXML from the LSU catalog resulted in a set of directories containing one MARCXML bibliographic file each, plus its associated holdings record files.

The XSLT 2.0 stylesheet _marcxml_holdings_merge.xsl_ takes this structure as input, and creates a single file per directory combining the MARCXML bibliographic metadata and the holdings metadata.   

__NOTE: The resulting document is not valid MARCXML.__

- It merges the holdings files into the single MARCXML file with a <record> root element.
- It creates a <holdings> wrapper tag and copies the full <record> for each holdings record into this wrapper.
- It names the resulting file with an Mss. number identifier, the item title, and the name of the source directory.

To run this XSLT stylesheet with Saxon, pass the name of each MARCXML directory as the "current_folder" parameter. You can use the included bash script _marcxml_holdings_merge.sh_, which is a shortcut to the following:

```
java -jar saxon9he.jar -s:marcxml_holdings_merge.xsl -xsl:marcxml_holdings_merge.xsl current_folder=sample_data/catalog_export/2152
java -jar saxon9he.jar -s:marcxml_holdings_merge.xsl -xsl:marcxml_holdings_merge.xsl current_folder=sample_data/catalog_export/7229
java -jar saxon9he.jar -s:marcxml_holdings_merge.xsl -xsl:marcxml_holdings_merge.xsl current_folder=sample_data/catalog_export/8328
java -jar saxon9he.jar -s:marcxml_holdings_merge.xsl -xsl:marcxml_holdings_merge.xsl current_folder=sample_data/catalog_export/9922
java -jar saxon9he.jar -s:marcxml_holdings_merge.xsl -xsl:marcxml_holdings_merge.xsl current_folder=sample_data/catalog_export/10519
java -jar saxon9he.jar -s:marcxml_holdings_merge.xsl -xsl:marcxml_holdings_merge.xsl current_folder=sample_data/catalog_export/13030
```

Note that the command specifies the XSLT stylesheet as both the source (_-s_) and XSL (_-xsl_). The paths are specified within the stylesheet itself, and the folder name is passed as a parameter.

To reuse this XSLT stylesheet, update the local paths in the "folder_name" variable on line 20; the "export_number" variable on line 81, and the `<xsl:result-document> @href` on line 84.


## Notes on Processing with Saxon

First, be sure to have downloaded Saxon to your local machine. The example commands here (copied from above) assume that it is available from the root of the directory created when you clone this repository. If you downloaded it here, great! Otherwise, it may be useful to make a symbolic link/shortcut from the downloaded unzipped .jar location (shown as /opt/saxon) to this directory, as shown in the first step below:

* `ln -s /opt/saxon/saxon9he.jar saxon9he.jar`
* `java -jar saxon9he.jar -s:marcxml_holdings_merge.xsl -xsl:marcxml_holdings_merge.xsl current_folder=2152`
* `java -jar saxon9he.jar -s:sample_data/merged_records/ -xsl:marcxml2ead.xsl -o:sample_data/ead/`

Saxon HE is on SourceForge, somewhere like this: https://sourceforge.net/projects/saxon/files/Saxon-HE/9.8/
