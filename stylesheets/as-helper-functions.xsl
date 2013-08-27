<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns2="http://www.w3.org/1999/xlink" xmlns:local="http://www.yoursite.org/namespace" xmlns:ead="urn:isbn:1-931666-22-9" version="2.0"  exclude-result-prefixes="#all">
    <!--
        *******************************************************************
        *                                                                 *
        * VERSION:          1.0                                           *
        *                                                                 *
        * AUTHOR:           Winona Salesky                                *
        *                   wsalesky@gmail.com                            *
        *                                                                 *
        * DATE:             2013-08-14                                    *
        *                                                                 *
        * ABOUT:            This file has been created for use with       *
        *                   EAD xml files exported from the               *
        *                   ArchivesSpace web application.                *
        *                                                                 *
        *******************************************************************
    -->
    <xsl:strip-space elements="*"/>
    <xsl:output encoding="utf-8" indent="yes"/>
    <!-- A local function to check for element ids and generate an id if no id exists -->
    <xsl:function name="local:buildID">
        <xsl:param name="element"/>
        <xsl:choose>
            <xsl:when test="$element/@id">
                <xsl:value-of select="$element/@id"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="generate-id($element)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- 
        A local function to name all child elements with no head tag. 
        Tag names addapted from EAD tag library (http://www.loc.gov/ead/tglib/element_index.html)
    -->
    <xsl:function name="local:tagName">
        <!-- element node as parameter -->
        <xsl:param name="elementNode"/>
        <!-- Name of element -->
        <xsl:variable name="tag" select="name($elementNode)"/>
        <!-- Find element name -->
        <xsl:choose>
            <xsl:when test="$elementNode/ead:head"><xsl:value-of select="$elementNode/ead:head"/></xsl:when>
            <xsl:when test="$tag = 'did'">Summary Information</xsl:when>
            <xsl:when test="$tag = 'abstract'">Abstract</xsl:when>
            <xsl:when test="$tag = 'accruals'">Accruals</xsl:when>  
            <xsl:when test="$tag = 'acqinfo'">Acquisition Information</xsl:when>
            <xsl:when test="$tag = 'address'">Address</xsl:when>  
            <xsl:when test="$tag = 'altformavail'">Alternative Form Available</xsl:when>
            <xsl:when test="$tag = 'appraisal'">Appraisal Information</xsl:when>   
            <xsl:when test="$tag = 'arc'">Arc</xsl:when>
            <xsl:when test="$tag = 'archref'">Archival Reference</xsl:when>   
            <xsl:when test="$tag = 'arrangement'">Arrangement</xsl:when>
            <xsl:when test="$tag = 'author'">Author</xsl:when>   
            <xsl:when test="$tag = 'bibref'">Bibliographic Reference</xsl:when>
            <xsl:when test="$tag = 'bibseries'">Bibliographic Series</xsl:when>   
            <xsl:when test="$tag = 'bibliography'">Bibliography</xsl:when>
            <xsl:when test="$tag = 'bioghist'">Biography or History</xsl:when>    
            <xsl:when test="$tag = 'change'">Change</xsl:when>
            <xsl:when test="$tag = 'chronlist'">Chronology List</xsl:when>    
            <xsl:when test="$tag = 'accessrestrict'">Conditions Governing Access</xsl:when>
            <xsl:when test="$tag = 'userestrict'">Conditions Governing Use</xsl:when>   
            <xsl:when test="$tag = 'controlaccess'">Controlled Access Headings</xsl:when>
            <xsl:when test="$tag = 'corpname'">Corporate Name</xsl:when>   
            <xsl:when test="$tag = 'creation'">Creation</xsl:when>
            <xsl:when test="$tag = 'custodhist'">Custodial History</xsl:when>   
            <xsl:when test="$tag = 'date'">Date</xsl:when>    
            <xsl:when test="$tag = 'descgrp'">Description Group</xsl:when>
            <xsl:when test="$tag = 'dsc'">Collection Inventory</xsl:when>   
            <xsl:when test="$tag = 'descrules'">Descriptive Rules</xsl:when>     
            <xsl:when test="$tag = 'dao'">Digital Object</xsl:when>
            <xsl:when test="$tag = 'daodesc'">Digital Object Description</xsl:when>
            <xsl:when test="$tag = 'daogrp'">Digital Object Group</xsl:when>     
            <xsl:when test="$tag = 'daoloc'">Digital Object Location</xsl:when> 
            <xsl:when test="$tag = 'dimensions'">Dimensions</xsl:when>
            <xsl:when test="$tag = 'edition'">Edition</xsl:when>     
            <xsl:when test="$tag = 'editionstmt'">Edition Statement</xsl:when>
            <xsl:when test="$tag = 'event'">Event</xsl:when>     
            <xsl:when test="$tag = 'eventgrp'">Event Group</xsl:when>
            <xsl:when test="$tag = 'expan'">Expansion</xsl:when> 
            <xsl:when test="$tag = 'extptr'">Extended Pointer</xsl:when>
            <xsl:when test="$tag = 'extptrloc'">Extended Pointer Location</xsl:when>
            <xsl:when test="$tag = 'extref'">Extended Reference</xsl:when>
            <xsl:when test="$tag = 'extrefloc'">Extended Reference Location</xsl:when>
            <xsl:when test="$tag = 'extent'">Extent</xsl:when>
            <xsl:when test="$tag = 'famname'">Family Name</xsl:when>
            <xsl:when test="$tag = 'filedesc'">File Description</xsl:when>
            <xsl:when test="$tag = 'fileplan'">File Plan</xsl:when>
            <xsl:when test="$tag = 'frontmatter'">Front Matter</xsl:when>
            <xsl:when test="$tag = 'function'">Function</xsl:when>
            <xsl:when test="$tag = 'genreform'">Genre/Physical Characteristic</xsl:when>
            <xsl:when test="$tag = 'geogname'">Geographic Name</xsl:when>
            <xsl:when test="$tag = 'imprint'">Imprint</xsl:when>
            <xsl:when test="$tag = 'index'">Index</xsl:when>
            <xsl:when test="$tag = 'indexentry'">Index Entry</xsl:when>
            <xsl:when test="$tag = 'item'">Item</xsl:when>
            <xsl:when test="$tag = 'language'">Language</xsl:when>
            <xsl:when test="$tag = 'langmaterial'">Language of the Material</xsl:when>
            <xsl:when test="$tag = 'langusage'">Language Usage</xsl:when>
            <xsl:when test="$tag = 'legalstatus'">Legal Status</xsl:when>
            <xsl:when test="$tag = 'linkgrp'">Linking Group</xsl:when>
            <xsl:when test="$tag = 'originalsloc'">Location of Originals</xsl:when>
            <xsl:when test="$tag = 'materialspec'">Material Specific Details</xsl:when>
            <xsl:when test="$tag = 'name'">Name</xsl:when>
            <xsl:when test="$tag = 'namegrp'">Name Group</xsl:when>
            <xsl:when test="$tag = 'note'">Note</xsl:when>
            <xsl:when test="$tag = 'notestmt'">Note Statement</xsl:when>
            <xsl:when test="$tag = 'occupation'">Occupation</xsl:when>
            <xsl:when test="$tag = 'origination'">Origination</xsl:when>
            <xsl:when test="$tag = 'odd'">Other Descriptive Data</xsl:when>
            <xsl:when test="$tag = 'otherfindaid'">Other Finding Aid</xsl:when>
            <xsl:when test="$tag = 'persname'">Personal Name</xsl:when>
            <xsl:when test="$tag = 'phystech'">Physical Characteristics and Technical Requirements</xsl:when>
            <xsl:when test="$tag = 'physdesc'">Physical Description</xsl:when>
            <xsl:when test="$tag = 'physfacet'">Physical Facet</xsl:when>
            <xsl:when test="$tag = 'physloc'">Physical Location</xsl:when>
            <xsl:when test="$tag = 'ptr'">Pointer</xsl:when>
            <xsl:when test="$tag = 'ptrgrp'">Pointer Group</xsl:when>
            <xsl:when test="$tag = 'ptrloc'">Pointer Location</xsl:when>
            <xsl:when test="$tag = 'prefercite'">Preferred Citation</xsl:when>
            <xsl:when test="$tag = 'processinfo'">Processing Information</xsl:when>
            <xsl:when test="$tag = 'profiledesc'">Profile Description</xsl:when>
            <xsl:when test="$tag = 'publicationstmt'">Publication Statement</xsl:when>
            <xsl:when test="$tag = 'publisher'">Publisher</xsl:when> 
            <xsl:when test="$tag = 'ref'">Reference</xsl:when>
            <xsl:when test="$tag = 'refloc'">Reference Location</xsl:when>
            <xsl:when test="$tag = 'relatedmaterial'">Related Material</xsl:when>
            <xsl:when test="$tag = 'repository'">Repository</xsl:when>
            <xsl:when test="$tag = 'resource'">Resource</xsl:when>
            <xsl:when test="$tag = 'revisiondesc'">Revision Description</xsl:when>
            <xsl:when test="$tag = 'runner'">Runner</xsl:when>
            <xsl:when test="$tag = 'scopecontent'">Scope and Content</xsl:when>
            <xsl:when test="$tag = 'separatedmaterial'">Separated Material</xsl:when>
            <xsl:when test="$tag = 'seriesstmt'">Series Statement</xsl:when>
            <xsl:when test="$tag = 'sponsor'">Sponsor</xsl:when>
            <xsl:when test="$tag = 'subject'">Subject</xsl:when>
            <xsl:when test="$tag = 'subarea'">Subordinate Area</xsl:when>
            <xsl:when test="$tag = 'subtitle'">Subtitle</xsl:when>
            <xsl:when test="$tag = 'div'">Text Division</xsl:when>
            <xsl:when test="$tag = 'title'">Title</xsl:when>
            <xsl:when test="$tag = 'unittitle'">Title</xsl:when>
            <xsl:when test="$tag = 'unitdate'">Date</xsl:when>
            <xsl:when test="$tag = 'unitid'">ID</xsl:when>
            <xsl:when test="$tag = 'titlepage'">Title Page</xsl:when>
            <xsl:when test="$tag = 'titleproper'">Title Proper of the Finding Aid</xsl:when>
            <xsl:when test="$tag = 'titlestmt'">Title Statement</xsl:when>   
            <!-- eac-cpf fields -->
            <xsl:when test="$tag = 'identity'">Name(s)</xsl:when>
            <xsl:when test="$tag = 'description'">Description</xsl:when>
            <xsl:when test="$tag = 'relations'">Relations</xsl:when>
            <xsl:when test="$tag = 'structureOrGenealogy'">Structure Or Genealogy</xsl:when>
            <xsl:when test="$tag = 'localDescription'">Local Description</xsl:when>
            <xsl:when test="$tag= 'generalContext'">General Context</xsl:when>
            <xsl:when test="$tag= 'alternativeSet'">Alternative Set</xsl:when>
            <xsl:when test="$tag= 'functions'">Functions</xsl:when>
            <xsl:when test="$tag= 'biogHist'">Biography or History</xsl:when>
            
        </xsl:choose>
    </xsl:function>
   
    <!-- 
        A local function to parse ISO dates into more readable dates.
        Takes a date formatted like this: 2009-11-18T10:16-0500
        Returns: November 18, 2009
    -->
    <xsl:function name="local:parseDate">
        <xsl:param name="dateString"/>
        <xsl:variable name="month">
            <xsl:choose>
                <xsl:when test="substring($dateString,6,2) = '01'">January</xsl:when>
                <xsl:when test="substring($dateString,6,2) = '02'">February</xsl:when>
                <xsl:when test="substring($dateString,6,2) = '03'">March</xsl:when>
                <xsl:when test="substring($dateString,6,2) = '04'">April</xsl:when>
                <xsl:when test="substring($dateString,6,2) = '05'">May</xsl:when>
                <xsl:when test="substring($dateString,6,2) = '06'">June</xsl:when>
                <xsl:when test="substring($dateString,6,2) = '07'">July</xsl:when>
                <xsl:when test="substring($dateString,6,2) = '08'">August</xsl:when>
                <xsl:when test="substring($dateString,6,2) = '09'">September</xsl:when>
                <xsl:when test="substring($dateString,6,2) = '10'">October</xsl:when>
                <xsl:when test="substring($dateString,6,2) = '11'">November</xsl:when>
                <xsl:when test="substring($dateString,6,2) = '12'">December</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="concat($month,' ',substring($dateString,9,2),', ',substring($dateString,1,4))"/>
    </xsl:function>
    
    <!-- 
        Prints out full language name from abbreviation. 
        List based on the ISO 639-2b three-letter language codes (http://www.loc.gov/standards/iso639-2/php/code_list.php). 
    -->
    <xsl:template match="ead:language">
        <xsl:choose>
            <xsl:when test="@langcode = 'No_linguistic_content'">No linguistic content</xsl:when>
                <xsl:when test="@langcode = 'und'">Undetermined</xsl:when>
                <xsl:when test="@langcode = 'abk'">Abkhaz</xsl:when>
                <xsl:when test="@langcode = 'ace'">Achinese</xsl:when>
                <xsl:when test="@langcode = 'ach'">Acoli</xsl:when>
                <xsl:when test="@langcode = 'ada'">Adangme</xsl:when>
                <xsl:when test="@langcode = 'ady'">Adygei</xsl:when>
                <xsl:when test="@langcode = 'aar'">Afar</xsl:when>
                <xsl:when test="@langcode = 'afh'">Afrihili</xsl:when>
                <xsl:when test="@langcode = 'afr'">Afrikaans</xsl:when>
                <xsl:when test="@langcode = 'afa'">Afroasiatic (Other)</xsl:when>
                <xsl:when test="@langcode = 'aka'">Akan</xsl:when>
                <xsl:when test="@langcode = 'akk'">Akkadian</xsl:when>
                <xsl:when test="@langcode = 'alb'">Albanian</xsl:when>
                <xsl:when test="@langcode = 'ale'">Aleut</xsl:when>
                <xsl:when test="@langcode = 'alg'">Algonquian (Other)</xsl:when>
                <xsl:when test="@langcode = 'tut'">Altaic (Other)</xsl:when>
                <xsl:when test="@langcode = 'amh'">Amharic</xsl:when>
                <xsl:when test="@langcode = 'apa'">Apache languages</xsl:when>
                <xsl:when test="@langcode = 'ara'">Arabic</xsl:when>
                <xsl:when test="@langcode = 'arg'">Aragonese Spanish</xsl:when>
                <xsl:when test="@langcode = 'arc'">Aramaic</xsl:when>
                <xsl:when test="@langcode = 'arp'">Arapaho</xsl:when>
                <xsl:when test="@langcode = 'arw'">Arawak</xsl:when>
                <xsl:when test="@langcode = 'arm'">Armenian</xsl:when>
                <xsl:when test="@langcode = 'art'">Artificial (Other)</xsl:when>
                <xsl:when test="@langcode = 'asm'">Assamese</xsl:when>
                <xsl:when test="@langcode = 'ath'">Athapascan (Other)</xsl:when>
                <xsl:when test="@langcode = 'aus'">Australian languages</xsl:when>
                <xsl:when test="@langcode = 'map'">Austronesian (Other)</xsl:when>
                <xsl:when test="@langcode = 'ava'">Avaric</xsl:when>
                <xsl:when test="@langcode = 'ave'">Avestan</xsl:when>
                <xsl:when test="@langcode = 'awa'">Awadhi</xsl:when>
                <xsl:when test="@langcode = 'aym'">Aymara</xsl:when>
                <xsl:when test="@langcode = 'aze'">Azerbaijani</xsl:when>
                <xsl:when test="@langcode = 'ast'">Bable</xsl:when>
                <xsl:when test="@langcode = 'ban'">Balinese</xsl:when>
                <xsl:when test="@langcode = 'bat'">Baltic (Other)</xsl:when>
                <xsl:when test="@langcode = 'bal'">Baluchi</xsl:when>
                <xsl:when test="@langcode = 'bam'">Bambara</xsl:when>
                <xsl:when test="@langcode = 'bai'">Bamileke languages</xsl:when>
                <xsl:when test="@langcode = 'bad'">Banda</xsl:when>
                <xsl:when test="@langcode = 'bnt'">Bantu (Other)</xsl:when>
                <xsl:when test="@langcode = 'bas'">Basa</xsl:when>
                <xsl:when test="@langcode = 'bak'">Bashkir</xsl:when>
                <xsl:when test="@langcode = 'baq'">Basque</xsl:when>
                <xsl:when test="@langcode = 'btk'">Batak</xsl:when>
                <xsl:when test="@langcode = 'bej'">Beja</xsl:when>
                <xsl:when test="@langcode = 'bel'">Belarusian</xsl:when>
                <xsl:when test="@langcode = 'bem'">Bemba</xsl:when>
                <xsl:when test="@langcode = 'ben'">Bengali</xsl:when>
                <xsl:when test="@langcode = 'ber'">Berber (Other)</xsl:when>
                <xsl:when test="@langcode = 'bho'">Bhojpuri</xsl:when>
                <xsl:when test="@langcode = 'bih'">Bihari</xsl:when>
                <xsl:when test="@langcode = 'bik'">Bikol</xsl:when>
                <xsl:when test="@langcode = 'bis'">Bislama</xsl:when>
                <xsl:when test="@langcode = 'bos'">Bosnian</xsl:when>
                <xsl:when test="@langcode = 'bra'">Braj</xsl:when>
                <xsl:when test="@langcode = 'bre'">Breton</xsl:when>
                <xsl:when test="@langcode = 'bug'">Bugis</xsl:when>
                <xsl:when test="@langcode = 'bul'">Bulgarian</xsl:when>
                <xsl:when test="@langcode = 'bua'">Buriat</xsl:when>
                <xsl:when test="@langcode = 'bur'">Burmese</xsl:when>
                <xsl:when test="@langcode = 'cad'">Caddo</xsl:when>
                <xsl:when test="@langcode = 'car'">Carib</xsl:when>
                <xsl:when test="@langcode = 'cat'">Catalan</xsl:when>
                <xsl:when test="@langcode = 'cau'">Caucasian (Other)</xsl:when>
                <xsl:when test="@langcode = 'ceb'">Cebuano</xsl:when>
                <xsl:when test="@langcode = 'cel'">Celtic (Other)</xsl:when>
                <xsl:when test="@langcode = 'cai'">Central American Indian (Other)</xsl:when>
                <xsl:when test="@langcode = 'chg'">Chagatai</xsl:when>
                <xsl:when test="@langcode = 'cmc'">Chamic languages</xsl:when>
                <xsl:when test="@langcode = 'cha'">Chamorro</xsl:when>
                <xsl:when test="@langcode = 'che'">Chechen</xsl:when>
                <xsl:when test="@langcode = 'chr'">Cherokee</xsl:when>
                <xsl:when test="@langcode = 'chy'">Cheyenne</xsl:when>
                <xsl:when test="@langcode = 'chb'">Chibcha</xsl:when>
                <xsl:when test="@langcode = 'chi'">Chinese</xsl:when>
                <xsl:when test="@langcode = 'chn'">Chinook jargon</xsl:when>
                <xsl:when test="@langcode = 'chp'">Chipewyan</xsl:when>
                <xsl:when test="@langcode = 'cho'">Choctaw</xsl:when>
                <xsl:when test="@langcode = 'chu'">Church Slavic</xsl:when>
                <xsl:when test="@langcode = 'chv'">Chuvash</xsl:when>
                <xsl:when test="@langcode = 'cop'">Coptic</xsl:when>
                <xsl:when test="@langcode = 'cor'">Cornish</xsl:when>
                <xsl:when test="@langcode = 'cos'">Corsican</xsl:when>
                <xsl:when test="@langcode = 'cre'">Cree</xsl:when>
                <xsl:when test="@langcode = 'mus'">Creek</xsl:when>
                <xsl:when test="@langcode = 'crp'">Creoles and Pidgins(Other)</xsl:when>
                <xsl:when test="@langcode = 'cpe'">Creoles and Pidgins, English-based (Other)</xsl:when>
                <xsl:when test="@langcode = 'cpf'">Creoles and Pidgins, French-based (Other)</xsl:when>
                <xsl:when test="@langcode = 'cpp'">Creoles and Pidgins, Portuguese-based (Other)</xsl:when>
                <xsl:when test="@langcode = 'crh'">Crimean Tatar</xsl:when>
                <xsl:when test="@langcode = 'scr'">Croatian</xsl:when>
                <xsl:when test="@langcode = 'cus'">Cushitic (Other)</xsl:when>
                <xsl:when test="@langcode = 'cze'">Czech</xsl:when>
                <xsl:when test="@langcode = 'dak'">Dakota</xsl:when>
                <xsl:when test="@langcode = 'dan'">Danish</xsl:when>
                <xsl:when test="@langcode = 'dar'">Dargwa</xsl:when>
                <xsl:when test="@langcode = 'day'">Dayak</xsl:when>
                <xsl:when test="@langcode = 'del'">Delaware</xsl:when>
                <xsl:when test="@langcode = 'din'">Dinka</xsl:when>
                <xsl:when test="@langcode = 'div'">Divehi</xsl:when>
                <xsl:when test="@langcode = 'doi'">Dogri</xsl:when>
                <xsl:when test="@langcode = 'dgr'">Dogrib</xsl:when>
                <xsl:when test="@langcode = 'dra'">Dravidian (Other)</xsl:when>
                <xsl:when test="@langcode = 'dua'">Duala</xsl:when>
                <xsl:when test="@langcode = 'dut'">Dutch</xsl:when>
                <xsl:when test="@langcode = 'dum'">Dutch, Middle (ca. 1050-1350)</xsl:when>
                <xsl:when test="@langcode = 'dyu'">Dyula</xsl:when>
                <xsl:when test="@langcode = 'dzo'">Dzongkha</xsl:when>
                <xsl:when test="@langcode = 'bin'">Edo</xsl:when>
                <xsl:when test="@langcode = 'efi'">Efik</xsl:when>
                <xsl:when test="@langcode = 'egy'">Egyptian (Ancient)</xsl:when>
                <xsl:when test="@langcode = 'eka'">Ekajuk</xsl:when>
                <xsl:when test="@langcode = 'elx'">Elamite</xsl:when>
                <xsl:when test="@langcode = 'eng'">English</xsl:when>
                <xsl:when test="@langcode = 'enm'">English, Middle (1100-1500)</xsl:when>
                <xsl:when test="@langcode = 'ang'">English, Old (ca.450-1100)</xsl:when>
                <xsl:when test="@langcode = 'epo'">Esperanto</xsl:when>
                <xsl:when test="@langcode = 'est'">Estonian</xsl:when>
                <xsl:when test="@langcode = 'gez'">Ethiopic</xsl:when>
                <xsl:when test="@langcode = 'ewe'">Ewe</xsl:when>
                <xsl:when test="@langcode = 'ewo'">Ewondo</xsl:when>
                <xsl:when test="@langcode = 'fan'">Fang</xsl:when>
                <xsl:when test="@langcode = 'fat'">Fanti</xsl:when>
                <xsl:when test="@langcode = 'fao'">Faroese</xsl:when>
                <xsl:when test="@langcode = 'fij'">Fijian</xsl:when>
                <xsl:when test="@langcode = 'fin'">Finnish</xsl:when>
                <xsl:when test="@langcode = 'fiu'">Finno-Ugrian (Other)</xsl:when>
                <xsl:when test="@langcode = 'fon'">Fon</xsl:when>
                <xsl:when test="@langcode = 'fre'">French</xsl:when>
                <xsl:when test="@langcode = 'frm'">French, Middle (ca.1400-1600)</xsl:when>
                <xsl:when test="@langcode = 'fro'">French, Old (ca.842-1400)</xsl:when>
                <xsl:when test="@langcode = 'fry'">Frisian</xsl:when>
                <xsl:when test="@langcode = 'fur'">Friulian</xsl:when>
                <xsl:when test="@langcode = 'ful'">Fula</xsl:when>
                <xsl:when test="@langcode = 'gaa'">Gã</xsl:when>
                <xsl:when test="@langcode = 'glg'">Galician</xsl:when>
                <xsl:when test="@langcode = 'lug'">Ganda</xsl:when>
                <xsl:when test="@langcode = 'gay'">Gayo</xsl:when>
                <xsl:when test="@langcode = 'gba'">Gbaya</xsl:when>
                <xsl:when test="@langcode = 'geo'">Georgian</xsl:when>
                <xsl:when test="@langcode = 'ger'">German</xsl:when>
                <xsl:when test="@langcode = 'gmh'">German, Middle High (ca.1050-1500)</xsl:when>
                <xsl:when test="@langcode = 'goh'">German, Old High (ca.750-1050)</xsl:when>
                <xsl:when test="@langcode = 'gem'">Germanic (Other)</xsl:when>
                <xsl:when test="@langcode = 'gil'">Gilbertese</xsl:when>
                <xsl:when test="@langcode = 'gon'">Gondi</xsl:when>
                <xsl:when test="@langcode = 'gor'">Gorontalo</xsl:when>
                <xsl:when test="@langcode = 'got'">Gothic</xsl:when>
                <xsl:when test="@langcode = 'grb'">Grebo</xsl:when>
                <xsl:when test="@langcode = 'grc'">Greek, Ancient (to 1453)</xsl:when>
                <xsl:when test="@langcode = 'gre'">Greek, Modern (1453-)</xsl:when>
                <xsl:when test="@langcode = 'grn'">Guarani</xsl:when>
                <xsl:when test="@langcode = 'guj'">Gujarati</xsl:when>
                <xsl:when test="@langcode = 'gwi'">Gwich'in</xsl:when>
                <xsl:when test="@langcode = 'hai'">Haida</xsl:when>
                <xsl:when test="@langcode = 'hat'">Haitian French Creole</xsl:when>
                <xsl:when test="@langcode = 'hau'">Hausa</xsl:when>
                <xsl:when test="@langcode = 'haw'">Hawaiian</xsl:when>
                <xsl:when test="@langcode = 'heb'">Hebrew</xsl:when>
                <xsl:when test="@langcode = 'her'">Herero</xsl:when>
                <xsl:when test="@langcode = 'hil'">Hiligaynon</xsl:when>
                <xsl:when test="@langcode = 'him'">Himachali</xsl:when>
                <xsl:when test="@langcode = 'hin'">Hindi</xsl:when>
                <xsl:when test="@langcode = 'hmo'">Hiri Motu</xsl:when>
                <xsl:when test="@langcode = 'hit'">Hittite</xsl:when>
                <xsl:when test="@langcode = 'hmn'">Hmong</xsl:when>
                <xsl:when test="@langcode = 'hun'">Hungarian</xsl:when>
                <xsl:when test="@langcode = 'hup'">Hupa</xsl:when>
                <xsl:when test="@langcode = 'iba'">Iban</xsl:when>
                <xsl:when test="@langcode = 'ice'">Icelandic</xsl:when>
                <xsl:when test="@langcode = 'ido'">Ido</xsl:when>
                <xsl:when test="@langcode = 'ibo'">Igbo</xsl:when>
                <xsl:when test="@langcode = 'ijo'">Ijo</xsl:when>
                <xsl:when test="@langcode = 'ilo'">Iloko</xsl:when>
                <xsl:when test="@langcode = 'smn'">Inari Sami</xsl:when>
                <xsl:when test="@langcode = 'inc'">Indic (Other)</xsl:when>
                <xsl:when test="@langcode = 'ine'">Indo-European (Other)</xsl:when>
                <xsl:when test="@langcode = 'ind'">Indonesian</xsl:when>
                <xsl:when test="@langcode = 'inh'">Ingush</xsl:when>
                <xsl:when test="@langcode = 'ina'">Interlingua (International Auxiliary Language Association)</xsl:when>
                <xsl:when test="@langcode = 'ile'">Interlingue</xsl:when>
                <xsl:when test="@langcode = 'iku'">Inuktitut</xsl:when>
                <xsl:when test="@langcode = 'ipk'">Inupiaq</xsl:when>
                <xsl:when test="@langcode = 'ira'">Iranian (Other)</xsl:when>
                <xsl:when test="@langcode = 'gle'">Irish</xsl:when>
                <xsl:when test="@langcode = 'mga'">Irish, Middle (ca.1110-1550)</xsl:when>
                <xsl:when test="@langcode = 'sga'">Irish, Old (to 1100)</xsl:when>
                <xsl:when test="@langcode = 'iro'">Iroquoian (Other)</xsl:when>
                <xsl:when test="@langcode = 'ita'">Italian</xsl:when>
                <xsl:when test="@langcode = 'jpn'">Japanese</xsl:when>
                <xsl:when test="@langcode = 'jav'">Javanese</xsl:when>
                <xsl:when test="@langcode = 'jrb'">Judeo-Arabic</xsl:when>
                <xsl:when test="@langcode = 'jpr'">Judeo-Persian</xsl:when>
                <xsl:when test="@langcode = 'kbd'">Kabardian</xsl:when>
                <xsl:when test="@langcode = 'kab'">Kabyle</xsl:when>
                <xsl:when test="@langcode = 'kac'">Kachin</xsl:when>
                <xsl:when test="@langcode = 'kal'">Kalâtdlisut</xsl:when>
                <xsl:when test="@langcode = 'xal'">Kalmyk</xsl:when>
                <xsl:when test="@langcode = 'kam'">Kamba</xsl:when>
                <xsl:when test="@langcode = 'kan'">Kannada</xsl:when>
                <xsl:when test="@langcode = 'kau'">Kanuri</xsl:when>
                <xsl:when test="@langcode = 'kaa'">Kara-Kalpak</xsl:when>
                <xsl:when test="@langcode = 'kar'">Karen</xsl:when>
                <xsl:when test="@langcode = 'kas'">Kashmiri</xsl:when>
                <xsl:when test="@langcode = 'kaw'">Kawi</xsl:when>
                <xsl:when test="@langcode = 'kaz'">Kazakh</xsl:when>
                <xsl:when test="@langcode = 'kha'">Khasi</xsl:when>
                <xsl:when test="@langcode = 'khm'">Khmer</xsl:when>
                <xsl:when test="@langcode = 'khi'">Khoisan (Other)</xsl:when>
                <xsl:when test="@langcode = 'kho'">Khotanese</xsl:when>
                <xsl:when test="@langcode = 'kik'">Kikuyu</xsl:when>
                <xsl:when test="@langcode = 'kmb'">Kimbundu</xsl:when>
                <xsl:when test="@langcode = 'kin'">Kinyarwanda</xsl:when>
                <xsl:when test="@langcode = 'kom'">Komi</xsl:when>
                <xsl:when test="@langcode = 'kon'">Kongo</xsl:when>
                <xsl:when test="@langcode = 'kok'">Konkani</xsl:when>
                <xsl:when test="@langcode = 'kor'">Korean</xsl:when>
                <xsl:when test="@langcode = 'kpe'">Kpelle</xsl:when>
                <xsl:when test="@langcode = 'kro'">Kru (Other)</xsl:when>
                <xsl:when test="@langcode = 'kua'">Kuanyama</xsl:when>
                <xsl:when test="@langcode = 'kum'">Kumyk</xsl:when>
                <xsl:when test="@langcode = 'kur'">Kurdish</xsl:when>
                <xsl:when test="@langcode = 'kru'">Kurukh</xsl:when>
                <xsl:when test="@langcode = 'kos'">Kusaie</xsl:when>
                <xsl:when test="@langcode = 'kut'">Kutenai</xsl:when>
                <xsl:when test="@langcode = 'kir'">Kyrgyz</xsl:when>
                <xsl:when test="@langcode = 'lad'">Ladino</xsl:when>
                <xsl:when test="@langcode = 'lah'">Lahnda</xsl:when>
                <xsl:when test="@langcode = 'lam'">Lamba</xsl:when>
                <xsl:when test="@langcode = 'lao'">Lao</xsl:when>
                <xsl:when test="@langcode = 'lat'">Latin</xsl:when>
                <xsl:when test="@langcode = 'lav'">Latvian</xsl:when>
                <xsl:when test="@langcode = 'ltz'">Letzeburgesch</xsl:when>
                <xsl:when test="@langcode = 'lez'">Lezgian</xsl:when>
                <xsl:when test="@langcode = 'lim'">Limburgish</xsl:when>
                <xsl:when test="@langcode = 'lin'">Lingala</xsl:when>
                <xsl:when test="@langcode = 'lit'">Lithuanian</xsl:when>
                <xsl:when test="@langcode = 'nds'">Low German</xsl:when>
                <xsl:when test="@langcode = 'loz'">Lozi</xsl:when>
                <xsl:when test="@langcode = 'lub'">Luba-Katanga</xsl:when>
                <xsl:when test="@langcode = 'lua'">Luba-Lulua</xsl:when>
                <xsl:when test="@langcode = 'lui'">Luiseño</xsl:when>
                <xsl:when test="@langcode = 'smj'">Lule Sami</xsl:when>
                <xsl:when test="@langcode = 'lun'">Lunda</xsl:when>
                <xsl:when test="@langcode = 'luo'">Luo (Kenya and Tanzania)</xsl:when>
                <xsl:when test="@langcode = 'lus'">Lushai</xsl:when>
                <xsl:when test="@langcode = 'mac'">Macedonian</xsl:when>
                <xsl:when test="@langcode = 'mad'">Madurese</xsl:when>
                <xsl:when test="@langcode = 'mag'">Magahi</xsl:when>
                <xsl:when test="@langcode = 'mai'">Maithili</xsl:when>
                <xsl:when test="@langcode = 'mak'">Makasar</xsl:when>
                <xsl:when test="@langcode = 'mlg'">Malagasy</xsl:when>
                <xsl:when test="@langcode = 'may'">Malay</xsl:when>
                <xsl:when test="@langcode = 'mal'">Malayalam</xsl:when>
                <xsl:when test="@langcode = 'mlt'">Maltese</xsl:when>
                <xsl:when test="@langcode = 'mnc'">Manchu</xsl:when>
                <xsl:when test="@langcode = 'mdr'">Mandar</xsl:when>
                <xsl:when test="@langcode = 'man'">Mandingo</xsl:when>
                <xsl:when test="@langcode = 'mni'">Manipuri</xsl:when>
                <xsl:when test="@langcode = 'mno'">Manobo languages</xsl:when>
                <xsl:when test="@langcode = 'glv'">Manx</xsl:when>
                <xsl:when test="@langcode = 'mao'">Maori</xsl:when>
                <xsl:when test="@langcode = 'arn'">Mapuche</xsl:when>
                <xsl:when test="@langcode = 'mar'">Marathi</xsl:when>
                <xsl:when test="@langcode = 'chm'">Mari</xsl:when>
                <xsl:when test="@langcode = 'mah'">Marshallese</xsl:when>
                <xsl:when test="@langcode = 'mwr'">Marwari</xsl:when>
                <xsl:when test="@langcode = 'mas'">Masai</xsl:when>
                <xsl:when test="@langcode = 'myn'">Mayan languages</xsl:when>
                <xsl:when test="@langcode = 'men'">Mende</xsl:when>
                <xsl:when test="@langcode = 'mic'">Micmac</xsl:when>
                <xsl:when test="@langcode = 'min'">Minangkabau</xsl:when>
                <xsl:when test="@langcode = 'mis'">Miscellaneous languages</xsl:when>
                <xsl:when test="@langcode = 'moh'">Mohawk</xsl:when>
                <xsl:when test="@langcode = 'mol'">Moldavian</xsl:when>
                <xsl:when test="@langcode = 'mkh'">Mon-Khmer (Other)</xsl:when>
                <xsl:when test="@langcode = 'lol'">Mongo-Nkundu</xsl:when>
                <xsl:when test="@langcode = 'mon'">Mongolian</xsl:when>
                <xsl:when test="@langcode = 'mos'">Mooré</xsl:when>
                <xsl:when test="@langcode = 'mul'">Multiple languages</xsl:when>
                <xsl:when test="@langcode = 'mun'">Munda (Other)</xsl:when>
                <xsl:when test="@langcode = 'nah'">Nahuatl</xsl:when>
                <xsl:when test="@langcode = 'nau'">Nauru</xsl:when>
                <xsl:when test="@langcode = 'nav'">Navajo</xsl:when>
                <xsl:when test="@langcode = 'nbl'">Ndebele (South Africa)</xsl:when>
                <xsl:when test="@langcode = 'nde'">Ndebele (Zimbabwe)</xsl:when>
                <xsl:when test="@langcode = 'ndo'">Ndonga</xsl:when>
                <xsl:when test="@langcode = 'nap'">Neapolitan Italian</xsl:when>
                <xsl:when test="@langcode = 'nep'">Nepali</xsl:when>
                <xsl:when test="@langcode = 'new'">Newari</xsl:when>
                <xsl:when test="@langcode = 'nia'">Nias</xsl:when>
                <xsl:when test="@langcode = 'nic'">Niger-Kordofanian (Other)</xsl:when>
                <xsl:when test="@langcode = 'ssa'">Nilo-Saharan (Other)</xsl:when>
                <xsl:when test="@langcode = 'niu'">Niuean</xsl:when>
                <xsl:when test="@langcode = 'nog'">Nogai</xsl:when>
                <xsl:when test="@langcode = 'nai'">North American Indian (Other)</xsl:when>
                <xsl:when test="@langcode = 'sme'">Northern Sami</xsl:when>
                <xsl:when test="@langcode = 'nso'">Northern Sotho</xsl:when>
                <xsl:when test="@langcode = 'nor'">Norwegian</xsl:when>
                <xsl:when test="@langcode = 'nob'">Norwegian Bokmål</xsl:when>
                <xsl:when test="@langcode = 'nno'">Norwegian Nynorsk</xsl:when>
                <xsl:when test="@langcode = 'nub'">Nubian languages</xsl:when>
                <xsl:when test="@langcode = 'nym'">Nyamwezi</xsl:when>
                <xsl:when test="@langcode = 'nya'">Nyanja</xsl:when>
                <xsl:when test="@langcode = 'nyn'">Nyankole</xsl:when>
                <xsl:when test="@langcode = 'nyo'">Nyoro</xsl:when>
                <xsl:when test="@langcode = 'nzi'">Nzima</xsl:when>
                <xsl:when test="@langcode = 'oci'">Occitan (post-1500)</xsl:when>
                <xsl:when test="@langcode = 'oji'">Ojibwa</xsl:when>
                <xsl:when test="@langcode = 'non'">Old Norse</xsl:when>
                <xsl:when test="@langcode = 'peo'">Old Persian (ca.600-400 B.C.)</xsl:when>
                <xsl:when test="@langcode = 'ori'">Oriya</xsl:when>
                <xsl:when test="@langcode = 'orm'">Oromo</xsl:when>
                <xsl:when test="@langcode = 'osa'">Osage</xsl:when>
                <xsl:when test="@langcode = 'oss'">Ossetic</xsl:when>
                <xsl:when test="@langcode = 'oto'">Otomian languages</xsl:when>
                <xsl:when test="@langcode = 'pal'">Pahlavi</xsl:when>
                <xsl:when test="@langcode = 'pau'">Palauan</xsl:when>
                <xsl:when test="@langcode = 'pli'">Pali</xsl:when>
                <xsl:when test="@langcode = 'pam'">Pampanga</xsl:when>
                <xsl:when test="@langcode = 'pag'">Pangasinan</xsl:when>
                <xsl:when test="@langcode = 'pan'">Panjabi</xsl:when>
                <xsl:when test="@langcode = 'pap'">Papiamento</xsl:when>
                <xsl:when test="@langcode = 'paa'">Papuan (Other)</xsl:when>
                <xsl:when test="@langcode = 'per'">Persian</xsl:when>
                <xsl:when test="@langcode = 'phi'">Philippine (Other)</xsl:when>
                <xsl:when test="@langcode = 'phn'">Phoenician</xsl:when>
                <xsl:when test="@langcode = 'pol'">Polish</xsl:when>
                <xsl:when test="@langcode = 'pon'">Ponape</xsl:when>
                <xsl:when test="@langcode = 'por'">Portuguese</xsl:when>
                <xsl:when test="@langcode = 'pra'">Prakrit languages</xsl:when>
                <xsl:when test="@langcode = 'pro'">Provençal (to 1500)</xsl:when>
                <xsl:when test="@langcode = 'pus'">Pushto</xsl:when>
                <xsl:when test="@langcode = 'que'">Quechua</xsl:when>
                <xsl:when test="@langcode = 'roh'">Raeto-Romance</xsl:when>
                <xsl:when test="@langcode = 'raj'">Rajasthani</xsl:when>
                <xsl:when test="@langcode = 'rap'">Rapanui</xsl:when>
                <xsl:when test="@langcode = 'rar'">Rarotongan</xsl:when>
                <xsl:when test="@langcode = 'qaa-qtz'">Reserved for local user</xsl:when>
                <xsl:when test="@langcode = 'roa'">Romance (Other)</xsl:when>
                <xsl:when test="@langcode = 'rom'">Romani</xsl:when>
                <xsl:when test="@langcode = 'rum'">Romanian</xsl:when>
                <xsl:when test="@langcode = 'run'">Rundi</xsl:when>
                <xsl:when test="@langcode = 'rus'">Russian</xsl:when>
                <xsl:when test="@langcode = 'sal'">Salishan languages</xsl:when>
                <xsl:when test="@langcode = 'sam'">Samaritan Aramaic</xsl:when>
                <xsl:when test="@langcode = 'smi'">Sami</xsl:when>
                <xsl:when test="@langcode = 'smo'">Samoan</xsl:when>
                <xsl:when test="@langcode = 'sad'">Sandawe</xsl:when>
                <xsl:when test="@langcode = 'sag'">Sango (Ubangi Creole)</xsl:when>
                <xsl:when test="@langcode = 'san'">Sanskrit</xsl:when>
                <xsl:when test="@langcode = 'sat'">Santali</xsl:when>
                <xsl:when test="@langcode = 'srd'">Sardinian</xsl:when>
                <xsl:when test="@langcode = 'sas'">Sasak</xsl:when>
                <xsl:when test="@langcode = 'sco'">Scots</xsl:when>
                <xsl:when test="@langcode = 'gla'">Scottish Gaelic</xsl:when>
                <xsl:when test="@langcode = 'sel'">Selkup</xsl:when>
                <xsl:when test="@langcode = 'sem'">Semitic (Other)</xsl:when>
                <xsl:when test="@langcode = 'scc'">Serbian</xsl:when>
                <xsl:when test="@langcode = 'srr'">Serer</xsl:when>
                <xsl:when test="@langcode = 'shn'">Shan</xsl:when>
                <xsl:when test="@langcode = 'sna'">Shona</xsl:when>
                <xsl:when test="@langcode = 'iii'">Sichuan Yi</xsl:when>
                <xsl:when test="@langcode = 'sid'">Sidamo</xsl:when>
                <xsl:when test="@langcode = 'sgn'">Sign languages</xsl:when>
                <xsl:when test="@langcode = 'bla'">Siksika</xsl:when>
                <xsl:when test="@langcode = 'snd'">Sindhi</xsl:when>
                <xsl:when test="@langcode = 'sin'">Sinhalese</xsl:when>
                <xsl:when test="@langcode = 'sit'">Sino-Tibetan (Other)</xsl:when>
                <xsl:when test="@langcode = 'sio'">Siouan (Other)</xsl:when>
                <xsl:when test="@langcode = 'sms'">Skolt Sami</xsl:when>
                <xsl:when test="@langcode = 'den'">Slave</xsl:when>
                <xsl:when test="@langcode = 'sla'">Slavic (Other)</xsl:when>
                <xsl:when test="@langcode = 'slo'">Slovak</xsl:when>
                <xsl:when test="@langcode = 'slv'">Slovenian</xsl:when>
                <xsl:when test="@langcode = 'sog'">Sogdian</xsl:when>
                <xsl:when test="@langcode = 'som'">Somali</xsl:when>
                <xsl:when test="@langcode = 'son'">Songhai</xsl:when>
                <xsl:when test="@langcode = 'snk'">Soninke</xsl:when>
                <xsl:when test="@langcode = 'wen'">Sorbian languages</xsl:when>
                <xsl:when test="@langcode = 'sot'">Sotho</xsl:when>
                <xsl:when test="@langcode = 'sai'">South American Indian (Other)</xsl:when>
                <xsl:when test="@langcode = 'sma'">Southern Sami</xsl:when>
                <xsl:when test="@langcode = 'spa'">Spanish</xsl:when>
                <xsl:when test="@langcode = 'suk'">Sukuma</xsl:when>
                <xsl:when test="@langcode = 'sux'">Sumerian</xsl:when>
                <xsl:when test="@langcode = 'sun'">Sundanese</xsl:when>
                <xsl:when test="@langcode = 'sus'">Susu</xsl:when>
                <xsl:when test="@langcode = 'swa'">Swahili</xsl:when>
                <xsl:when test="@langcode = 'ssw'">Swazi</xsl:when>
                <xsl:when test="@langcode = 'swe'">Swedish</xsl:when>
                <xsl:when test="@langcode = 'syr'">Syriac</xsl:when>
                <xsl:when test="@langcode = 'tgl'">Tagalog</xsl:when>
                <xsl:when test="@langcode = 'tah'">Tahitian</xsl:when>
                <xsl:when test="@langcode = 'tai'">Tai (Other)</xsl:when>
                <xsl:when test="@langcode = 'tgk'">Tajik</xsl:when>
                <xsl:when test="@langcode = 'tmh'">Tamashek</xsl:when>
                <xsl:when test="@langcode = 'tam'">Tamil</xsl:when>
                <xsl:when test="@langcode = 'tat'">Tatar</xsl:when>
                <xsl:when test="@langcode = 'tel'">Telugu</xsl:when>
                <xsl:when test="@langcode = 'tem'">Temne</xsl:when>
                <xsl:when test="@langcode = 'ter'">Terena</xsl:when>
                <xsl:when test="@langcode = 'tet'">Tetum</xsl:when>
                <xsl:when test="@langcode = 'tha'">Thai</xsl:when>
                <xsl:when test="@langcode = 'tib'">Tibetan</xsl:when>
                <xsl:when test="@langcode = 'tig'">Tigré</xsl:when>
                <xsl:when test="@langcode = 'tir'">Tigrinya</xsl:when>
                <xsl:when test="@langcode = 'tiv'">Tiv</xsl:when>
                <xsl:when test="@langcode = 'tli'">Tlingit</xsl:when>
                <xsl:when test="@langcode = 'tpi'">Tok Pisin</xsl:when>
                <xsl:when test="@langcode = 'tkl'">Tokelauan</xsl:when>
                <xsl:when test="@langcode = 'tog'">Tonga (Nyasa)</xsl:when>
                <xsl:when test="@langcode = 'ton'">Tongan</xsl:when>
                <xsl:when test="@langcode = 'chk'">Truk</xsl:when>
                <xsl:when test="@langcode = 'tsi'">Tsimshian</xsl:when>
                <xsl:when test="@langcode = 'tso'">Tsonga</xsl:when>
                <xsl:when test="@langcode = 'tsn'">Tswana</xsl:when>
                <xsl:when test="@langcode = 'tum'">Tumbuka</xsl:when>
                <xsl:when test="@langcode = 'tup'">Tupi languages</xsl:when>
                <xsl:when test="@langcode = 'tur'">Turkish</xsl:when>
                <xsl:when test="@langcode = 'ota'">Turkish, Ottoman</xsl:when>
                <xsl:when test="@langcode = 'tuk'">Turkmen</xsl:when>
                <xsl:when test="@langcode = 'tvl'">Tuvaluan</xsl:when>
                <xsl:when test="@langcode = 'tyv'">Tuvinian</xsl:when>
                <xsl:when test="@langcode = 'twi'">Twi</xsl:when>
                <xsl:when test="@langcode = 'udm'">Udmurt</xsl:when>
                <xsl:when test="@langcode = 'uga'">Ugaritic</xsl:when>
                <xsl:when test="@langcode = 'uig'">Uighur</xsl:when>
                <xsl:when test="@langcode = 'ukr'">Ukrainian</xsl:when>
                <xsl:when test="@langcode = 'umb'">Umbundu</xsl:when>
                <xsl:when test="@langcode = 'und'">Undetermined</xsl:when>
                <xsl:when test="@langcode = 'urd'">Urdu</xsl:when>
                <xsl:when test="@langcode = 'uzb'">Uzbek</xsl:when>
                <xsl:when test="@langcode = 'vai'">Vai</xsl:when>
                <xsl:when test="@langcode = 'ven'">Venda</xsl:when>
                <xsl:when test="@langcode = 'vie'">Vietnamese</xsl:when>
                <xsl:when test="@langcode = 'vol'">Volapük</xsl:when>
                <xsl:when test="@langcode = 'vot'">Votic</xsl:when>
                <xsl:when test="@langcode = 'wak'">Wakashan languages</xsl:when>
                <xsl:when test="@langcode = 'wal'">Walamo</xsl:when>
                <xsl:when test="@langcode = 'wln'">Walloon</xsl:when>
                <xsl:when test="@langcode = 'war'">Waray</xsl:when>
                <xsl:when test="@langcode = 'was'">Washo</xsl:when>
                <xsl:when test="@langcode = 'wel'">Welsh</xsl:when>
                <xsl:when test="@langcode = 'wol'">Wolof</xsl:when>
                <xsl:when test="@langcode = 'xho'">Xhosa</xsl:when>
                <xsl:when test="@langcode = 'sah'">Yakut</xsl:when>
                <xsl:when test="@langcode = 'yao'">Yao (Africa)</xsl:when>
                <xsl:when test="@langcode = 'yap'">Yapese</xsl:when>
                <xsl:when test="@langcode = 'yid'">Yiddish</xsl:when>
                <xsl:when test="@langcode = 'yor'">Yoruba</xsl:when>
                <xsl:when test="@langcode = 'ypk'">Yupik languages</xsl:when>
                <xsl:when test="@langcode = 'znd'">Zande</xsl:when>
                <xsl:when test="@langcode = 'zap'">Zapotec</xsl:when>
                <xsl:when test="@langcode = 'zen'">Zenaga</xsl:when>
                <xsl:when test="@langcode = 'zha'">Zhuang</xsl:when>
                <xsl:when test="@langcode = 'zul'">Zulu</xsl:when>
                <xsl:when test="@langcode = 'zun'">Zuni</xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <!-- Prnts full subject authority names -->
    <xsl:template name="subjectSource">
        <xsl:choose>
            <xsl:when test="@source = 'aat'"> [Source: Art &amp; Architecture Thesaurus]</xsl:when>
            <xsl:when test="@source = 'dot'"> [Source:Dictionary of Occupational Titles]</xsl:when>
            <xsl:when test="@source = 'rbgenr'"> [Source:Genre Terms: A Thesaurus for Use in Rare Book and Special Collections Cataloging]</xsl:when>
            <xsl:when test="@source = 'georeft'"> [Source:GeoRef Thesaurus]</xsl:when>
            <xsl:when test="@source = 'tgn'"> [Source:Getty Thesaurus of Geographic Names]</xsl:when>
            <xsl:when test="@source = 'lcsh'"> [Source:Library of Congress Subject Headings]</xsl:when>
            <xsl:when test="@source = 'local'"> [Source:Local sources]</xsl:when>
            <xsl:when test="@source = 'mesh'"> [Source:Medical Subject Headings]</xsl:when>
            <xsl:when test="@source = 'gmgpc'"> [Source:Thesaurus for Graphic Materials]</xsl:when>
            <xsl:when test="@source = 'ingest'"/>
            <xsl:otherwise> [Source:<xsl:value-of select="@source"/>]</xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
