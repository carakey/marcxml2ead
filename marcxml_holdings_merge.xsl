<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="xsl">

    <!--   
    This XSLT 2.0 stylesheet takes as its source directories that hold one MARCXML bibliographic file each, plus its associated holdings record files. 
    It merges the holdings files into the single MARCXML file with a <record> root element. 
    It creates a <holdings> wrapper tag and copies the full <record> for each holdings record into this wrapper.
    It names the resulting file with an Mss. number identifer, the item title, and the name of the source directory.
    
    To run this XSLT with Saxon, pass the name of the directory as the "current_folder" parameter. 
    
    To reuse, update the local paths in the "folder_name" variable on line 20; the "export_number" variable on line 81, and the <xsl:result-document> @href on line 84.
    -->

    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    
    <xsl:param name="current_folder"/>
    <xsl:variable name="folder_name" select="concat('sample_data/catalog_export/',$current_folder)"/>
    
    <!-- $mss_directory = the directory of files related to a single collection -->
    <xsl:variable name="mss_directory" select="collection($folder_name)"/>
    
    <!-- $mss_bibrecord = the first file in the directory, which represents the bibliographic record for the collection -->
    <xsl:variable name="mss_bibrecord" select="$mss_directory[//record//datafield[@tag='999']]"/>
    
    <!-- $mss_holdings = the other files in the directory which contain the holdings info for the collection -->
    <xsl:variable name="mss_holdings" select="$mss_directory[//record//datafield[@tag='852']]"/>
    
    <xsl:template match="/">
        <!--
            Save each collection's combined record as a separate document;
            Set variables to create output document filename: 
                - manuscript number(s) where 500 field contains 'Mss.' or 524 field contains 'accessioned as Mss.'
                - otherwise, use 001 
        -->
        <xsl:variable name="mss_number">
            <!-- Use first available of (in this order): 
            - 500$a, text following 'accessioned as Mss.'
            - 524$a, text between 'Mss.' and next string matching comma-space-letter
            - the string "0-" plus the 001 field
            -->
            <xsl:choose>
                <xsl:when
                    test="$mss_bibrecord/record/datafield[@tag = '500'][contains(subfield[@code = 'a'], 'accessioned as Mss.')]">
                    <xsl:analyze-string
                        select="$mss_bibrecord/record/datafield[@tag = '500']/subfield[@code = 'a'][contains(., 'accessioned as Mss.')]"
                        regex="(accessioned as Mss\.)([\d\s,andetc\.]+)">
                        <xsl:matching-substring>
                            <xsl:text>Mss</xsl:text>
                            <xsl:value-of
                                select="normalize-space(replace(regex-group(2), '\p{P}$', ''))"
                            />
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>
                <xsl:when
                    test="$mss_bibrecord/record/datafield[@tag = '524'][contains(subfield[@code = 'a'], 'Mss.')]">
                    <xsl:analyze-string
                        select="$mss_bibrecord/record/datafield[@tag = '524']/subfield[@code = 'a'][contains(., 'Mss.')]"
                        regex="(Mss\.)([\d\s,andetc\.]+)(,\s[A-Za-z]{{1}})">
                        <xsl:matching-substring>
                            <xsl:text>Mss</xsl:text>
                            <xsl:value-of select="normalize-space(regex-group(2))"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>0-</xsl:text>
                    <xsl:value-of select="normalize-space($mss_bibrecord/record/controlfield[@tag = '001'])"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="identifier" select="replace(replace($mss_number, '\p{P}', '-'), ' ', '')"/>
        <xsl:variable name="title_beg">
            <xsl:value-of select="substring(replace(replace(normalize-space($mss_bibrecord/record/datafield[@tag = '245']/subfield[@code='a']), '\p{P}', ''), ' ', '_'),1,20)"/>
        </xsl:variable>
        <xsl:variable name="export_number">
            <xsl:value-of select="substring-before(substring-after(base-uri($mss_bibrecord),'/sample_data/catalog_export/'),'/')"/>
        </xsl:variable>
        
        <xsl:result-document href="sample_data/merged_records/{$identifier}_{$title_beg}_{$export_number}.xml" method="xml">
            
        <!-- 
        Create <record> root
        Copy the subelements of <record> from $mss_bibrecord
        Create arbitrary <holdings> element
        Copy each $mss_holdings record
        Close <holdings> element
        Close <record> root
        -->
            
            <record>
                <xsl:copy-of select="$mss_bibrecord/record/*"/>
                <holdings>
                    <xsl:for-each select="$mss_holdings">
                        <xsl:copy-of select="record"/>
                    </xsl:for-each>
                </holdings>
            </record>
            
        </xsl:result-document>
        
    </xsl:template>
   
</xsl:stylesheet>
