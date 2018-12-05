<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="urn:isbn:1-931666-22-9"
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    
    <!-- 
        This XSLT 2.0 stylesheet transforms MARCXML exported from the library catalog into EAD for ingest to ArchivesSpace.
        It attempts to adhere to local LSU Special Collections EAD templates and guidelines. 
        
        The stylesheet was originally based on the XSLT at https://github.com/MSU-Libraries/MARCtoEADforASpace.  
        
        Notes on source data: XML files exported from LSU's catalog had no namespace declarations.
        Holdings records were combined with bibliographic records using the XSLT stylesheet marcxml_holdings_merge.xsl. 
        The resulting files (and the source data for this stylesheet) are *not* valid MARCXML.  
        
    -->
    
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

    <xsl:param name="author" select="'LSU Libraries Special Collections Staff'"/>
    
    <xsl:template match="/">
        <ead xmlns="urn:isbn:1-931666-22-9" 
            xmlns:xlink="http://www.w3.org/1999/xlink"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd"
            relatedencoding="MARC21">
            <eadheader countryencoding="iso3166-1" dateencoding="iso8601" repositoryencoding="iso15511"
                langencoding="iso639-2b" scriptencoding="iso15924">
                <xsl:element name="eadid">
                    <xsl:attribute name="mainagencycode">
                        <xsl:text>US-lu</xsl:text>
                    </xsl:attribute>
                    <xsl:attribute name="countrycode">
                        <xsl:text>US</xsl:text>
                    </xsl:attribute>
                    <!-- If 856$u is present, use its value in the 'url' attribute, with .xml extension -->
                    <xsl:if
                        test="//record/datafield[@tag = '856'][@ind1 = '4'][@ind2 = '2']/subfield[@code = 'u'][contains(., 'findaid')]">
                        <xsl:attribute name="url">
                            <xsl:value-of
                                select="replace((//record/datafield[@tag = '856'][@ind1 = '4'][@ind2 = '2']/subfield[@code = 'u'])[contains(., 'findaid')], '.pdf', '.xml')"
                            />
                        </xsl:attribute>
                    </xsl:if>
                </xsl:element>
                
                <filedesc>
                    <titlestmt>
                        <titleproper>
                            <xsl:text>A Guide to the </xsl:text>
                            <!-- Insert contents of 245a field, removing punctuation characters from the end of the title.
                            Capitalizes first letter of each word in the title. -->
                            <xsl:for-each select="//record/datafield[@tag = '245']">
                                <xsl:variable name="text" select="replace(normalize-space(subfield[@code = 'a']), '\p{P}$', '')"/>
                                <xsl:for-each select="tokenize($text,' ')">
                                    <xsl:value-of select="upper-case(substring(.,1,1))" />
                                    <xsl:value-of select="substring(.,2)" />
                                    <xsl:if test="position() != last()">
                                        <xsl:text> </xsl:text>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:for-each>
                        </titleproper>
                        <subtitle>
                            <xsl:text>A Collection in the Louisiana and Lower Mississippi Valley Collections</xsl:text>
                        </subtitle>
                        <author>
                            <xsl:value-of select="$author"/>
                        </author>
                    </titlestmt>
                    <!-- Default value for publicationstmt -->
                    <publicationstmt>
                        <publisher>
                            <xsl:text>LSU Libraries Special Collections</xsl:text>
                        </publisher>
                        <address>
                            <addressline>
                                <xsl:text>Hill Memorial Library</xsl:text>
                            </addressline>
                            <addressline>
                                <xsl:text>95 Field House Drive</xsl:text>
                            </addressline>
                            <addressline>
                                <xsl:text>Baton Rouge, LA 70803</xsl:text>
                            </addressline>
                        </address>
                        <date>
                            <!-- Inserts current year -->
                            <xsl:value-of select="substring(string(current-date()), 1, 4)"/>
                        </date>
                    </publicationstmt>
                </filedesc>
            </eadheader>
            <xsl:apply-templates/>
        </ead>
    </xsl:template>

    <xsl:template match="record[not(parent::holdings)]">
        <archdesc level="collection" type="inventory" relatedencoding="MARC21">
            <did>
                <!-- Uses 245$a + $b as unittitle -->
                <xsl:for-each select="datafield[@tag = '245']">
                    <unittitle encodinganalog="245$a">
                        <xsl:if test="subfield[@code = 'a']">
                            <xsl:variable name="text" select="replace(normalize-space(subfield[@code = 'a']), '\p{P}$', '')"/>
                            <xsl:for-each select="tokenize($text,' ')">
                                <xsl:value-of select="upper-case(substring(.,1,1))" />
                                <xsl:value-of select="substring(.,2)" />
                                <xsl:if test="position() != last()">
                                    <xsl:text> </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:if>
                        <xsl:if test="subfield[@code = 'b']">
                            <xsl:text>: </xsl:text>
                            <xsl:variable name="text" select="replace(normalize-space(subfield[@code = 'b']), '\p{P}$', '')"/>
                            <xsl:for-each select="tokenize($text,' ')">
                                <xsl:value-of select="upper-case(substring(.,1,1))" />
                                <xsl:value-of select="substring(.,2)" />
                                <xsl:if test="position() != last()">
                                    <xsl:text> </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:if>
                    </unittitle>
                </xsl:for-each>
                
                <!-- For unitid, use first available of (in this order): 
                    - 500$a, text following 'accessioned as Mss.'
                    - 524$a, text between 'Mss.' and next string matching comma-space-letter
                    - 099$a (concatenate all instances with space delimiting)
                    - the string "No Mss. Number"
                -->
                <unitid countrycode="US" encodinganalog="099"
                    repositorycode="US-lu">
                    <xsl:variable name="mss_number">
                        <xsl:choose>
                            <xsl:when
                                test="/record/datafield[@tag = '500'][contains(subfield[@code = 'a'], 'accessioned as Mss.')]">
                                <xsl:analyze-string
                                    select="/record/datafield[@tag = '500']/subfield[@code = 'a'][contains(., 'accessioned as Mss.')]"
                                    regex="(accessioned as Mss\.)([\d\s,andetc\.]+)">
                                    <xsl:matching-substring>
                                        <xsl:text>Mss. </xsl:text>
                                        <xsl:value-of
                                            select="normalize-space(replace(regex-group(2), '\p{P}$', ''))"
                                        />
                                    </xsl:matching-substring>
                                </xsl:analyze-string>
                            </xsl:when>
                            <xsl:when
                                test="/record/datafield[@tag = '524'][contains(subfield[@code = 'a'], 'Mss.')]">
                                <xsl:analyze-string
                                    select="/record/datafield[@tag = '524']/subfield[@code = 'a'][contains(., 'Mss.')]"
                                    regex="(Mss\.)([\d\s,andetc\.]+)(,\s[A-Za-z]{{1}})">
                                    <xsl:matching-substring>
                                        <xsl:text>Mss. </xsl:text>
                                        <xsl:value-of select="normalize-space(regex-group(2))"/>
                                    </xsl:matching-substring>
                                </xsl:analyze-string>
                            </xsl:when>
                            <xsl:when test="/record/datafield[@tag = '099']/subfield[@code = 'a']">
                                <xsl:for-each
                                    select="/record/datafield[@tag = '099']/subfield[@code = 'a']">
                                    <xsl:value-of select="normalize-space(.)"/>
                                    <xsl:if test="position() != last()">
                                        <xsl:text> </xsl:text>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>No Mss. Number</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>

                    <xsl:value-of select="$mss_number"/>
                </unitid>
                
                <!-- Use 245$f for unitdate @type=inclusive;
                        Call template to normalize date for @normal;
                        Replace abbreviations in date values and remove ending period -->
                <xsl:for-each select="datafield[@tag = '245']/subfield[@code = 'f']">
                    <xsl:element name="unitdate">
                        <xsl:attribute name="type">
                            <xsl:text>inclusive</xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="encodinganalog">
                            <xsl:text>245$f</xsl:text>
                        </xsl:attribute>
                        <xsl:call-template name="normal_date">
                            <xsl:with-param name="input_date" select="text()"/>
                        </xsl:call-template>
                        <xsl:value-of select="replace(normalize-space(replace(replace(.,'ca\.','circa '),'n.d','undated')),'\.$','')"/>
                    </xsl:element>
                </xsl:for-each>
                
                <!-- Use 245$g for unitdate @type=inclusive;
                        Remove string 'bulk' as well as parentheses;
                        Call template to normalize date for @normal;
                        Replace abbreviations in date values and remove ending period -->
                <xsl:for-each select="datafield[@tag = '245']/subfield[@code = 'g']">
                    <xsl:variable name="de-bulked">
                    <xsl:choose>
                        <xsl:when test="matches(.,'bulk','i')">
                            <xsl:value-of select="normalize-space(replace(substring-before(substring-after(., 'bulk'), ')'),':',''))"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="replace(normalize-space(replace(replace(.,'ca\.','circa '),'n.d','undated')),'\.$','')"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    </xsl:variable>
                    <xsl:element name="unitdate">
                        <xsl:attribute name="type">
                            <xsl:text>bulk</xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="encodinganalog">
                            <xsl:text>245$g</xsl:text>
                        </xsl:attribute>
                        <xsl:call-template name="normal_date">
                            <xsl:with-param name="input_date" select="text()"/>
                        </xsl:call-template>
                        <xsl:value-of select="$de-bulked"/>
                    </xsl:element>
                </xsl:for-each>
                
                <!-- Use 100 for Creator origination/persname or 110 for origination/corpname -->
                <xsl:if test="datafield[@tag = '100'] or datafield[@tag = '110']">
                    <origination>
                        <xsl:for-each select="datafield[@tag = '100']">
                            <persname encodinganalog="100">
                                <xsl:value-of
                                    select="replace(normalize-space(.), '\.$', '')"/>
                            </persname>
                        </xsl:for-each>
                        <xsl:for-each select="datafield[@tag = '110']">
                            <corpname encodinganalog="110">
                                <xsl:value-of select="replace(normalize-space(.), '\.$', '')"/>
                            </corpname>
                        </xsl:for-each>
                    </origination>
                </xsl:if>
                
                <!-- Use 700 for Contributor origination/persname or 710 for origination/corpname -->
                <xsl:if test="datafield[@tag = '700'] or datafield[@tag = '710']">
                    <origination>
                        <xsl:for-each select="datafield[@tag = '700']">
                            <persname encodinganalog="700">
                                <xsl:value-of
                                    select="replace(normalize-space(.), '\.$', '')"/>
                            </persname>
                        </xsl:for-each>
                        <xsl:for-each select="datafield[@tag = '710']">
                            <corpname encodinganalog="710">
                                <xsl:value-of select="replace(normalize-space(.), '\.$', '')"/>
                            </corpname>
                        </xsl:for-each>
                    </origination>
                </xsl:if>
                
                <!-- Use 300$a and $f for physdesc -->
                <xsl:if test="datafield[@tag = '300']">
                    <physdesc>
                        <xsl:for-each select="datafield[@tag = '300']">
                            <extent encodinganalog="300$a">
                                <xsl:choose>
                                    <xsl:when test="matches(subfield[@code = 'a'],'\sp\.\)$')">
                                        <xsl:value-of select="replace(subfield[@code = 'a'],'p\.','pages')"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="normalize-space(replace(subfield[@code = 'a'], '[,;:]{1}$', ''))"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <xsl:if test="subfield[@code = 'f']">
                                    <xsl:text> </xsl:text>
                                    <xsl:for-each select="subfield[@code = 'f']">
                                        <!-- Replaces certain abbreviated terms -->
                                        <xsl:choose>
                                            <xsl:when test="matches(., 'p\.')">
                                                <xsl:value-of select="replace(normalize-space(.), 'p.', 'pages')"/>
                                            </xsl:when>
                                            <xsl:when test="matches(., 'v\.')">
                                                <xsl:value-of select="replace(normalize-space(.), 'v.', 'volumes')"/>
                                            </xsl:when>
                                            <xsl:when test="matches(., 'ft\.')">
                                                <xsl:value-of select="replace(normalize-space(.), 'ft.', 'feet')"/>
                                            </xsl:when>
                                            <xsl:when test="matches(., 'in\.')">
                                                <xsl:value-of select="replace(normalize-space(.), 'in.', 'inches')"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="replace(normalize-space(.), '\p{P}$', '')"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:for-each>
                                </xsl:if>
                            </extent>
                        </xsl:for-each>
                    </physdesc>
                </xsl:if>
                
                <!-- Use 041$a for langmaterial/language -->
                <!-- Rather than require a lookup, explicitly translates the limited number of values 
                    present in LSU records. List came from XQUERY of MARCXML records:
                        
                        for $record in collection('all_records')/record
                            for $lang in $record/datafield[@tag = '041']/subfield[@code = 'a'] 
                            let $non-eng := $lang[not(contains(text(), 'eng'))]
                        group by $non-eng
                        order by $non-eng
                        return concat($non-eng, '&#xa;') -->
                        
                <xsl:for-each select="datafield[@tag = '041']">
                    <langmaterial encodinganalog="546$a">
                        <xsl:for-each select="subfield[@code = 'a']">
                            <xsl:element name="language">
                                <xsl:attribute name="langcode">
                                    <xsl:value-of select="."/>
                                </xsl:attribute>
                                <xsl:choose>
                                    <xsl:when test="matches(., 'eng') or matches(., 'en')">
                                        <xsl:text>English</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'ara')">
                                        <xsl:text>Arabic</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'dan')">
                                        <xsl:text>Danish</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'fre')">
                                        <xsl:text>French</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'ger')">
                                        <xsl:text>German</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'grc')">
                                        <xsl:text>Greek, Ancient (to 1453)</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'gre')">
                                        <xsl:text>Greek, Modern (1453-)</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'hun')">
                                        <xsl:text>Hungarian</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'ita')">
                                        <xsl:text>Italian</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'jpn')">
                                        <xsl:text>Japanese</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'lat')">
                                        <xsl:text>Latin</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'nor')">
                                        <xsl:text>Norwegian</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'por')">
                                        <xsl:text>Portuguese</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'roa')">
                                        <xsl:text>Romance languages</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'rus')">
                                        <xsl:text>Russian</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'spa')">
                                        <xsl:text>Spanish</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'swe')">
                                        <xsl:text>Swedish</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'vie')">
                                        <xsl:text>Vietnamese</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="matches(., 'yid')">
                                        <xsl:text>Yiddish</xsl:text>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="."/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:element>
                        </xsl:for-each>
                    </langmaterial>
                </xsl:for-each>
                
                <!-- Use default value for repository -->
                <repository encodinganalog="852$a">
                    <corpname>
                        <xsl:text>LSU Libraries Special Collections</xsl:text>
                    </corpname>
                    <subarea>
                        <xsl:text>Louisiana and Lower Mississippi Valley Collection</xsl:text>
                    </subarea>
                </repository>
                
                <!-- Use 852$z for physloc -->
                <xsl:if test="//holdings/record/datafield[@tag = '852'][subfield[@code = 'h']]">
                    <physloc encodinganalog="852$h">
                        <xsl:for-each select="//datafield[@tag = '852'][subfield[@code = 'h']]">
                            <xsl:value-of select="normalize-space(subfield[@code = 'h'])"/>
                            <xsl:if test="position() != last()">
                                <xsl:text>; </xsl:text>
                            </xsl:if>
                        </xsl:for-each>
                    </physloc>
                </xsl:if>
                
            </did>
            
            <!-- Use 506$a for accessrestrict, or insert default text --> 
            <accessrestrict encodinganalog="506">
                <p>
                    <xsl:choose>
                        <xsl:when test="datafield[@tag = '506'][subfield[@code = 'a']]">
                            <xsl:value-of select="normalize-space(datafield[@tag = '506'][subfield[@code = 'a']])"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>There are no restrictions on access.</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </p>
            </accessrestrict>
            
            <!-- Use 540$a for userestrict, or insert default text -->
            <userestrict encodinganalog="540">
                <xsl:choose>
                    <xsl:when test="datafield[@tag = '540'][subfield[@code = 'a']]">
                        <xsl:for-each select="datafield[@tag = '540'][subfield[@code = 'a']]">
                            <p>
                                <xsl:value-of select="normalize-space(.)"/>
                            </p>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <p>
                            <xsl:text>Physical rights are retained by the LSU Libraries. For those materials not in the public domain, copyright is retained by the descendants of the creators in accordance with U.S. copyright law.</xsl:text>
                        </p>
                    </xsl:otherwise>
                </xsl:choose>
                
            </userestrict>
            
            <!-- Use 544 with first indicator 1 for relatedmaterial, or omit -->
            <xsl:call-template name="ThisOrNone">
                <xsl:with-param name="datafield" select="datafield[@tag = '544'][@ind1 = '1']"/>
                <xsl:with-param name="element" select="'relatedmaterial'"/>
                <xsl:with-param name="encodinganalog" select="'544 1'"/>
            </xsl:call-template>
            
            <!-- Use 524 for prefercite, or omit -->
            <xsl:call-template name="ThisOrNone">
                <xsl:with-param name="datafield" select="datafield[@tag = '524']"/>
                <xsl:with-param name="element" select="'prefercite'"/>
                <xsl:with-param name="encodinganalog" select="'524'"/>
            </xsl:call-template>
            
            <!-- Use 351 for arrangement, or omit -->
            <xsl:call-template name="ThisOrNone">
                <xsl:with-param name="datafield" select="datafield[@tag = '351']"/>
                <xsl:with-param name="element" select="'arrangement'"/>
                <xsl:with-param name="encodinganalog" select="'351'"/>
            </xsl:call-template>
            
            <!-- The following section is designated 'optional' in local EAD templates -->
            
            <!-- Use 535 for originalsloc, or omit -->
            <xsl:call-template name="ThisOrNone">
                <xsl:with-param name="datafield" select="datafield[@tag = '535']"/>
                <xsl:with-param name="element" select="'originalsloc'"/>
                <xsl:with-param name="encodinganalog" select="'535'"/>
            </xsl:call-template>
            
            <!-- Use 544 with first indicator 0 for separatedmaterial, or omit -->
            <xsl:call-template name="ThisOrNone">
                <xsl:with-param name="datafield" select="datafield[@tag = '544'][@ind1 = '0']"/>
                <xsl:with-param name="element" select="'separatedmaterial'"/>
                <xsl:with-param name="encodinganalog" select="'544 0'"/>
            </xsl:call-template>
            
            <!-- Use 530 for altformavail, or omit -->
            <xsl:call-template name="ThisOrNone">
                <xsl:with-param name="datafield" select="datafield[@tag = '530']"/>
                <xsl:with-param name="element" select="'altformavail'"/>
                <xsl:with-param name="encodinganalog" select="'530'"/>
            </xsl:call-template>
            
            <!-- Use 541 for acqinfo, or omit -->
            <xsl:call-template name="ThisOrNone">
                <xsl:with-param name="datafield" select="datafield[@tag = '541']"/>
                <xsl:with-param name="element" select="'acqinfo'"/>
                <xsl:with-param name="encodinganalog" select="'541'"/>
            </xsl:call-template>
            
            <!-- Use 583 for processinfo, or omit -->
            <xsl:call-template name="ThisOrNone">
                <xsl:with-param name="datafield" select="datafield[@tag = '583']"/>
                <xsl:with-param name="element" select="'processinfo'"/>
                <xsl:with-param name="encodinganalog" select="'583'"/>
            </xsl:call-template>
            
            <!-- End 'optional' section -->

            <!-- Use 545 for bioghist, or omit -->
            <xsl:call-template name="ThisOrNone">
                <xsl:with-param name="datafield" select="datafield[@tag = '545']"/>
                <xsl:with-param name="element" select="'bioghist'"/>
                <xsl:with-param name="encodinganalog" select="'545'"/>
            </xsl:call-template>
            
            <!-- Use 520 for scopecontent, or omit -->
            <xsl:call-template name="ThisOrNone">
                <xsl:with-param name="datafield" select="datafield[@tag = '520']"/>
                <xsl:with-param name="element" select="'scopecontent'"/>
                <xsl:with-param name="encodinganalog" select="'520'"/>
            </xsl:call-template>
            
            <!-- Use 561 for custodhist, or omit -->
            <xsl:call-template name="ThisOrNone">
                <xsl:with-param name="datafield" select="datafield[@tag = '561']"/>
                <xsl:with-param name="element" select="'custodhist'"/>
                <xsl:with-param name="encodinganalog" select="'561'"/>
            </xsl:call-template>
            
            <!-- Use 584 for accruals, or omit -->
            <xsl:call-template name="ThisOrNone">
                <xsl:with-param name="datafield" select="datafield[@tag = '584']"/>
                <xsl:with-param name="element" select="'accruals'"/>
                <xsl:with-param name="encodinganalog" select="'584'"/>
            </xsl:call-template>
            
            <!-- Use 504 for bibref, or omit -->
            <xsl:call-template name="ThisOrNone">
                <xsl:with-param name="datafield" select="datafield[@tag = '504']"/>
                <xsl:with-param name="element" select="'bibref'"/>
                <xsl:with-param name="encodinganalog" select="'504'"/>
            </xsl:call-template>
                        
            <!-- Use 538 for phystech, or omit -->
            <xsl:call-template name="ThisOrNone">
                <xsl:with-param name="datafield" select="datafield[@tag = '538']"/>
                <xsl:with-param name="element" select="'phystech'"/>
                <xsl:with-param name="encodinganalog" select="'538'"/>
            </xsl:call-template>
            
            <!-- Use 581 for bibliography, or omit -->
            <xsl:call-template name="ThisOrNone">
                <xsl:with-param name="datafield" select="datafield[@tag = '581']"/>
                <xsl:with-param name="element" select="'bibliography'"/>
                <xsl:with-param name="encodinganalog" select="'581'"/>
            </xsl:call-template>
            
            <!-- Use 555 for otherfindaid, or omit -->
            <xsl:call-template name="ThisOrNone">
                <xsl:with-param name="datafield" select="datafield[@tag = '555']"/>
                <xsl:with-param name="element" select="'otherfindaid'"/>
                <xsl:with-param name="encodinganalog" select="'555'"/>
            </xsl:call-template>
            
            
            <!-- Use 6XX datafields for controlaccess -->
            
            <controlaccess>
                <!-- Use 600 for persname -->
                <xsl:call-template name="controlaccess">
                    <xsl:with-param name="datafield" select="datafield[@tag = '600'][@ind1 != '3']"/>
                    <xsl:with-param name="element" select="'persname'"/>
                    <xsl:with-param name="source" select="'lcnaf'"/>
                    <xsl:with-param name="encodinganalog" select="'600'"/>    
                </xsl:call-template>
                
                <!-- Use 600 with first indicator 3 for famname -->
                <xsl:call-template name="controlaccess">
                    <xsl:with-param name="datafield" select="datafield[@tag = '600'][@ind1 = '3']"/>
                    <xsl:with-param name="element" select="'famname'"/>
                    <xsl:with-param name="source" select="'lcnaf'"/>
                    <xsl:with-param name="encodinganalog" select="'600 3'"/>    
                </xsl:call-template>
                
                <!-- Use 610 for corpname -->
                <xsl:call-template name="controlaccess">
                    <xsl:with-param name="datafield" select="datafield[@tag = '610']"/>
                    <xsl:with-param name="element" select="'corpname'"/>
                    <xsl:with-param name="source" select="'lcnaf'"/>
                    <xsl:with-param name="encodinganalog" select="'610'"/>    
                </xsl:call-template>
                
                <!-- Use 650 for subject -->
                <xsl:call-template name="controlaccess">
                    <xsl:with-param name="datafield" select="datafield[@tag = '650']"/>
                    <xsl:with-param name="element" select="'subject'"/>
                    <xsl:with-param name="source" select="'lcsh'"/>
                    <xsl:with-param name="encodinganalog" select="'650'"/>    
                </xsl:call-template>
                
                <!-- Use 651 for geogname -->
                <xsl:call-template name="controlaccess">
                    <xsl:with-param name="datafield" select="datafield[@tag = '651']"/>
                    <xsl:with-param name="element" select="'geogname'"/>
                    <xsl:with-param name="source" select="'lcsh'"/>
                    <xsl:with-param name="encodinganalog" select="'651'"/>    
                </xsl:call-template>
                
                <!-- Use 655 for genreform, excluding subfield $2 -->
                <xsl:call-template name="controlaccess">
                    <xsl:with-param name="datafield" select="datafield[@tag = '655']"/>
                    <xsl:with-param name="element" select="'genreform'"/>
                    <xsl:with-param name="source" select="'aat'"/>
                    <xsl:with-param name="encodinganalog" select="'655'"/>    
                </xsl:call-template>
                
                <!-- Use 656 for occupation -->
                <xsl:call-template name="controlaccess">
                    <xsl:with-param name="datafield" select="datafield[@tag = '656']"/>
                    <xsl:with-param name="element" select="'occupation'"/>
                    <xsl:with-param name="source" select="'lcsh'"/>
                    <xsl:with-param name="encodinganalog" select="'656'"/>    
                </xsl:call-template>
                
                <!-- Use 630 for title with @render="italic" -->
                <xsl:call-template name="controlaccess">
                    <xsl:with-param name="datafield" select="datafield[@tag = '630']"/>
                    <xsl:with-param name="element" select="'title'"/>
                    <xsl:with-param name="source" select="'lcsh'"/>
                    <xsl:with-param name="render" select="'italic'"/>
                    <xsl:with-param name="encodinganalog" select="'630'"/>    
                </xsl:call-template>
                
            </controlaccess>
            
            <!-- DSC information is derived from the MARC holdings fields --> 
            <dsc>
                <xsl:variable name="collection_title">
                    <xsl:variable name="text"
                        select="replace(normalize-space(datafield[@tag = '245']/subfield[@code = 'a']), '\p{P}$', '')"/>
                    <xsl:for-each select="tokenize($text, ' ')">
                        <xsl:value-of select="upper-case(substring(., 1, 1))"/>
                        <xsl:value-of select="substring(., 2)"/>
                        <xsl:if test="position() != last()">
                            <xsl:text> </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:for-each select="holdings/record/datafield[@tag = '866']">
                    <xsl:variable name="call_number"
                        select="../datafield[@tag = '852']/subfield[@code = 'h']"/>
                    <xsl:variable name="container">
                        <xsl:variable name="text"
                            select="replace(normalize-space(subfield[@code = 'a']), '\p{P}$', '')"/>
                        <xsl:for-each select="tokenize($text, ' ')">
                            <xsl:value-of select="upper-case(substring(., 1, 1))"/>
                            <xsl:value-of select="substring(., 2)"/>
                            <xsl:if test="position() != last()">
                                <xsl:text> </xsl:text>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:variable>
                    <c01 level="collection">
                        <did>
                            <unittitle>
                                <xsl:value-of select="$collection_title"/>
                            </unittitle>
                            <container>
                                <xsl:value-of select="$container"/>
                            </container>
                            <physloc>
                                <xsl:value-of select="$call_number"/>
                            </physloc>
                        </did>
                    </c01>
                </xsl:for-each>
                
            </dsc>
            
        </archdesc>
        
    </xsl:template>
    
    <!--
        It was determined that empty fields will cause ingest failures in ArchivesSpace, and so all logic involving this 
        template has been removed.
        
        <xsl:template name="ThisOrEmpty">
        <!-\- 
            This template creates an EAD element with a <p> subelement, taking a set of parameters.
            If the specified MARCXML datafield is not present in the source record, the element is created with an empty <p/> subelement.
        -\->
        <xsl:param name="datafield"/>
        <xsl:param name="element"/>
        <xsl:param name="encodinganalog"/>
        <xsl:element name="{$element}">
                <xsl:attribute name="encodinganalog">
                    <xsl:value-of select="$encodinganalog"/>
                </xsl:attribute>
                <xsl:choose>
                    <xsl:when test="$datafield">
                        <xsl:for-each select="$datafield">
                            <p>
                                <xsl:value-of select="normalize-space(.)"/>
                            </p>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <p/>
                    </xsl:otherwise>
                </xsl:choose>
        </xsl:element>
    </xsl:template>-->
    
    <xsl:template name="ThisOrNone">
        <!-- 
            This template creates an EAD element with a <p> subelement, taking a set of parameters.
            If the specified MARCXML datafield is not present in the source record, the element is omitted.
        -->
        <xsl:param name="datafield"/>
        <xsl:param name="element"/>
        <xsl:param name="encodinganalog"/>
        <xsl:if test="$datafield">
            <xsl:element name="{$element}">
                <xsl:attribute name="encodinganalog">
                    <xsl:value-of select="$encodinganalog"/>
                </xsl:attribute>
                <xsl:for-each select="$datafield">
                    <p>
                        <xsl:value-of select="normalize-space(.)"/>
                    </p>
                </xsl:for-each>
            </xsl:element>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="controlaccess">
        <!-- 
            This template creates EAD subelements within the <controlaccess> element, taking a set of parameters.
            The subelement is created ONLY IF the specified MARCXML datafield is present in the source record.
        -->
        <xsl:param name="datafield"/>
        <xsl:param name="element"/>
        <xsl:param name="source"/>
        <xsl:param name="encodinganalog"/>
        <xsl:param name="render"/>
        <xsl:if test="$datafield">
                <xsl:for-each select="$datafield">
                    <xsl:element name="{$element}">
                        <xsl:attribute name="source">
                            <!-- If the MARC field’s second indicator is 7, the source attribute will use subfield $2;
                                Subfield $2 is otherwise not included in the field value -->
                            <xsl:choose>
                                <xsl:when test="@ind2 = '7'">
                                    <xsl:value-of select="subfield[@code = '2']"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$source"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:if test="$render">
                            <xsl:attribute name="render">
                                <xsl:value-of select="$render"/>
                            </xsl:attribute>
                        </xsl:if>
                        <xsl:attribute name="encodinganalog">
                            <xsl:value-of select="$encodinganalog"/>
                        </xsl:attribute>
                        <xsl:for-each select="subfield">
                            <!-- Logic for delimiting between subfields: 
                            No delimiter is added preceding subfield $a;
                            A space-double-hyphen-space delimiter is added preceding subfields $v, $x, $y, or $z;
                            A single space delimiter is added preceding other subfields. -->
                            <xsl:choose>
                                <xsl:when test="@code = 'a'">
                                    <xsl:value-of select="normalize-space(.)"/>
                                </xsl:when>
                                <xsl:when test="@code = '2'"/>
                                <xsl:when
                                    test="@code = 'v' or @code = 'x' or @code = 'y' or @code = 'z'">
                                    <xsl:text> -- </xsl:text>
                                    <xsl:value-of select="normalize-space(.)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text> </xsl:text>
                                    <xsl:value-of select="normalize-space(.)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:element>
                </xsl:for-each>
            </xsl:if>        
    </xsl:template>
    
    <xsl:template name="normal_date">
        <!--
            This template is used for the <unitdate> field. It takes uncontrolled date values as input;
            It analyzes the string for groups of 4 digits with the assumption that these are years,
            and creates a string concatenating all matches;
            If this string is not empty, the @normal attribute is added:
                The first four characters of the concatenated-year-string are inserted;
                If the string is longer than 4 characters, then '/' followed by
                the last four characters of the string are inserted.
        -->
        <xsl:param name="input_date"/>
        <xsl:variable name="years">
            <xsl:analyze-string select="$input_date" regex="[0-9]{{4}}">
                <xsl:matching-substring>
                    <xsl:value-of select="."/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:if test="$years != ''">
            <xsl:attribute name="normal">
                <xsl:value-of select="substring($years, 1, 4)"/>
                <xsl:if test="string-length($years) > 4">
                    <xsl:text>/</xsl:text>
                    <xsl:value-of
                        select="substring($years, (string-length($years) - 3), (string-length($years)))"
                    />
                </xsl:if>
            </xsl:attribute>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>