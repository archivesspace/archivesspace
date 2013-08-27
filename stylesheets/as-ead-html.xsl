<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xlink="http://www.w3.org/1999/xlink" 
    xmlns:ns2="http://www.w3.org/1999/xlink" 
    xmlns:local="http://www.yoursite.org/namespace" 
    xmlns:ead="urn:isbn:1-931666-22-9" version="2.0"  exclude-result-prefixes="#all">
    <!--
        *******************************************************************
        *                                                                 *
        * VERSION:          1.0                                           *
        *                                                                 *
        * AUTHOR:           Winona Salesky                                *
        *                   wsalesky@gmail.com                            *
        *                                                                 *
        * DATE:             2013-08-21                                    *
        *                                                                 *
        * ABOUT:            This file has been created for use with       *
        *                   EAD xml files exported from the               *
        *                   ArchivesSpace web application.                *
        *                                                                 *
        *******************************************************************
    -->
    <xsl:output indent="yes" method="xml" 
        doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"  
        doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
        exclude-result-prefixes="#all"
        omit-xml-declaration="yes"
        encoding="utf-8"/>
    
    <xsl:strip-space elements="*"/>
    <!-- Calls a stylesheet with local functions and lists for languages and subject authorities -->
    <xsl:include href="as-helper-functions.xsl"/>   
    
    <!-- HTML metadata tags -->
    <xsl:template name="metadata">
        <meta http-equiv="Content-Type" name="dc.title" content="{/ead:ead/ead:eadheader/ead:filedesc/ead:titlestmt/ead:titleproper}"/>
        <meta http-equiv="Content-Type" name="dc.author" content="{/ead:ead/ead:archdesc/ead:did/ead:origination}" />
        <xsl:for-each select="/ead:ead/ead:archdesc/ead:controlaccess/descendant::*">
            <meta http-equiv="Content-Type" name="dc.subject" content="{.}" />
        </xsl:for-each>
        <meta http-equiv="Content-Type" name="dc.type" content="text" />
        <meta http-equiv="Content-Type" name="dc.format" content="manuscripts" />
        <meta http-equiv="Content-Type" name="dc.format" content="finding aids" />
    </xsl:template>
    
    <!-- CSS styles -->
    <xsl:template name="css">
        <style type="text/css">
            /*
                Style Guide
                font-family: Verdana, Arial, Helvetica, sans-serif;
                font color: #333
                font color (menu, links): #14a6dc
                background color (body, h2):  #f0f0f0
                background color (main div): #f9f9f9
                borders: #e1e1e8
            */
            html {
                margin: 0;
                padding: 0; 
            }
            body{
                color: #333;
                font-size: 100%;
                font-family: Verdana, Arial, Helvetica, sans-serif;
                background-color: #f0f0f0;
           }
            
            /* layout */
            #main {
                font-size: .87em;
                background-color: #f9f9f9;
                border:1px solid #e1e1e8;
                margin: 1em;
                padding: 1em;
                clear:both;
            }
            /* header*/
            #header {margin-left:1em;}
            
            /*Fixed position table of contents*/
            #toc {
                margin: 0;
                padding: 1.25em 1em;
                font-size: .85em;
                width: 20%;
                float:left;
                clear:left;
                position:fixed;
                max-height: 600px;
                overflow:scroll;
                
            }
            #toc ul {
                background-color: #ffffff;
                border:1px solid #e1e1e8;
                margin:0; 
                padding:0; 
            }   
            #toc li { 
                list-style: none;
                border-bottom: 1px solid #e1e1e8;
                overflow:hidden;
                margin-left: 1em;
            }
            #toc a, .top a{
                color:#14a6dc;
                display:block;
                /*height:25px;*/
                line-height: 2em;                   
                text-decoration:none;
            }
            #toc ul li a:hover, #toc ul li .current {background:#f9f9f9;}
            #toc li.submenu {margin-left: 1.75em;}
            #toc li.submenu2 {margin-left: 2.5em;}
            
            /* Main content div*/
            #content {
                border:1px solid #e1e1e8;
                background-color: #ffffff;
                margin: 1em 0 0 25%;
                padding: 0;
            }
            
            .section {
                background-color: #fafafa;
                border:1px solid #e1e1e8;
                margin:1em;
                padding:0;
            }
            .sectionContent {
                border:1px solid #e1e1e8;
                background-color: #ffffff;
                margin:.5em;
                padding:.25em .5em;
            }
            
            dl.summary {
                width:100%;
                overflow:hidden;
                clear:both;
            }
            dl.summary dt {
                float:left;
                width:25%; 
                text-align:right;
                clear:left;
            }
            dl.summary dd {
                margin-left: 30%;
                width:70%;
                clear:right;
            }
            
            /* typography */
            #header h1 {
                font-size: 1.75em;
                margin-bottom:0;
                padding-bottom:0;
            }
            #header h2 {
                background-color:#ffffff; 
                margin:0; 
                padding:0;
                border:none;
            }
            h2 {
                font-size: 1.25em;
                font-weight: 500;
                margin: 0;
                padding: .25em 1em;
                background-color: #f0f0f0;
                border-bottom: 1px solid #e1e1e8;
            }
            h3 {
                font-size: 1em;
                font-weight: 500;
                margin: 0;
                padding: .25em 1em;
                background-color: #f0f0f0;
                border-bottom: 1px solid #e1e1e8;
            }
            h4 {
                font-weight:600;
                color:#666666;
                margin: 0;
            }
            
            dt {}
            dd {margin-bottom:1em;}
            .block {display:block;}
            .list {margin:.5em; padding-left:.5em;}
            
            /* Table styles */
            table {width: 98%; margin:1em 2em; background-color:#f0f0f0;}
            td {background-color:#ffffff; padding:.25em .75em; vertical-align:top;}
            .thead td {background-color:#f0f0f0;}
            .tlist {width: 50%;}
            .even td{background-color:#f7f7f9;}
            
            /* List styles */
            .simple{list-style-type: none;}
            .arabic {list-style-type: decimal}
            .upperalpha{list-style-type: upper-alpha}
            .loweralpha{list-style-type: lower-alpha}
            .upperroman{list-style-type: upper-roman}
            .lowerroman{list-style-type: lower-roman}
            
            /* Render styles */
            .smcaps {font-variant: small-caps;}
            .underline {text-decoration: underline;}
            .strong {font-weight: 600;}
            
            /* Address line */
            .addressLine {display:block;}
            
            /* publication statement*/
            .publication {display:block; float: right; margin-right:2em; font-size:.75em;}
            
            /* Collection Inventory */
            table.dsc {text-align:left; margin:.5em; padding:0; font-size: .85em;}
            .dsc th {text-align:left; padding:.5em; font-weight:normal;  border-top: 2px solid #ccc; border-bottom:1px dotted #ccc; vertical-align:top;}
            .headers th {background-color:#f7f7f9; font-weight:bold; border-top: none; vertical-align:top;}
            .dsc dt {}
            .dsc dd {margin-bottom:.5em;}
            .dsc h3 {font-weight:bold; border:none; padding:0;}
            .dsc .didTitle {display:block;}
            .dscSeries {margin-left:.5em;}
            .dscSeries p {margin: 0 .5em .5em;}
            table.dsc td p {margin: 0 .5em .5em}
            .dscHeaders {text-decoration: underline;}
            
            /*--- Clevel Margins ---*/
            table td.c{padding-left: 0;}
            table td.c01{padding-left: 0;}
            table td.c02{padding-left: 1em;}                
            table td.c03{padding-left: 2em;}
            table td.c04{padding-left: 3em;}
            table td.c05{padding-left: 4em;}
            table td.c06{padding-left: 5em;}
            table td.c07{padding-left: 6em;}
            table td.c08{padding-left: 7em;}
            table td.c09{padding-left: 8em;}
            table td.c10{padding-left: 9em;}
            table td.c11{padding-left: 10em;}
            table td.c12{padding-left: 11em;}
        </style>
    </xsl:template>
    
    <!-- Named template for a generic p element with a link back to the the top of the page  -->
    <xsl:template name="top">
        <p class="top"><a href="#main"><strong>^</strong> Top</a></p>
    </xsl:template>
    
    <!-- Build html page -->
    <xsl:template match="/">
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
                <title><xsl:value-of select="concat(ead:ead/ead:eadheader/ead:filedesc/ead:titlestmt/ead:titleproper[1],' ',ead:ead/ead:eadheader/ead:filedesc/ead:titlestmt/ead:subtitle)"/></title>
                <xsl:call-template name="metadata"/>
                <xsl:call-template name="css"/>
            </head>
            <body>
                <div class="publication"><xsl:apply-templates select="ead:ead/ead:eadheader/ead:filedesc/ead:publicationstmt/ead:publisher"/></div>
                <div id="main">
                    <xsl:apply-templates select="ead:ead/ead:archdesc" mode="toc"/>
                    <xsl:apply-templates select="ead:ead/ead:archdesc"/>
                </div>
            </body>
        </html>
    </xsl:template>
    
    <!-- Build table of contents -->
    <xsl:template match="ead:archdesc" mode="toc">
        <div id="toc">
            <ul>
                <xsl:if test="ead:did">
                    <li><a href="#{local:buildID(ead:did)}"><xsl:value-of select="local:tagName(ead:did)"/></a></li>
                </xsl:if>
                <xsl:if test="ead:bioghist">
                    <li><a href="#{local:buildID(ead:bioghist[1])}"><xsl:value-of select="local:tagName(ead:bioghist[1])"/></a></li>   
                </xsl:if>
                <xsl:if test="ead:scopecontent">
                    <li><a href="#{local:buildID(ead:scopecontent[1])}"><xsl:value-of select="local:tagName(ead:scopecontent[1])"/></a></li>  
                </xsl:if>
                <xsl:if test="ead:arrangement">
                    <li><a href="#{local:buildID(ead:arrangement[1])}"><xsl:value-of select="local:tagName(ead:arrangement[1])"/></a></li>  
                </xsl:if>
                <xsl:if test="ead:fileplan">
                    <li><a href="#{local:buildID(ead:fileplan[1])}"><xsl:value-of select="local:tagName(ead:fileplan[1])"/></a></li>   
                </xsl:if>
                
                <!-- Administrative Information  -->
                <xsl:if test="ead:accessrestrict or ead:userestrict or
                    ead:custodhist or ead:accruals or ead:altformavail or ead:acqinfo or 
                    ead:processinfo or ead:appraisal or ead:originalsloc or 
                    /ead:ead/ead:eadheader/ead:filedesc/ead:publicationstmt or /ead:ead/ead:eadheader/ead:revisiondesc">
                    <li><a href="#adminInfo">Administrative Information</a></li>
                </xsl:if>
                
                <!-- Related Materials -->
                <xsl:if test="ead:relatedmaterial or ead:separatedmaterial">
                    <li><a href="#relMat">Related Materials</a></li>
                </xsl:if>
                
                <xsl:if test="ead:controlaccess">
                    <li><a href="#{local:buildID(ead:controlaccess[1])}"><xsl:value-of select="local:tagName(ead:controlaccess[1])"/></a></li>   
                </xsl:if>
                <xsl:if test="ead:otherfindaid">
                    <li><a href="#{local:buildID(ead:otherfindaid[1])}"><xsl:value-of select="local:tagName(ead:otherfindaid[1])"/></a></li>   
                </xsl:if>
                <xsl:if test="ead:phystech">
                    <li><a href="#{local:buildID(ead:phystech[1])}"><xsl:value-of select="local:tagName(ead:phystech[1])"/></a></li>   
                </xsl:if>
                <xsl:if test="ead:odd">
                    <li><a href="#{local:buildID(ead:odd[1])}"><xsl:value-of select="local:tagName(ead:odd[1])"/></a></li>   
                </xsl:if>
                <xsl:if test="ead:bibliography">
                    <li><a href="#{local:buildID(ead:bibliography[1])}"><xsl:value-of select="local:tagName(ead:bibliography[1])"/></a></li>   
                </xsl:if>
                <xsl:if test="ead:index">
                    <li><a href="#{local:buildID(ead:index[1])}"><xsl:value-of select="local:tagName(ead:index[1])"/></a></li>   
                </xsl:if> 
               
               <!-- Build Container List menu and submenu -->
                <xsl:for-each select="ead:dsc">
                    <xsl:if test="child::*">
                        <li><a href="#{local:buildID(.)}"><xsl:value-of select="local:tagName(.)"/></a></li>                   
                    </xsl:if>
                    <!--Creates a submenu for collections, record groups and series and fonds-->
                    <xsl:for-each select="child::*[@level = 'collection'] 
                        | child::*[@level = 'recordgrp']  | child::*[@level = 'series'] | child::*[@level = 'fonds']">
                        <li class="submenu">
                            <a href="#{local:buildID(.)}">
                                <xsl:choose>
                                    <xsl:when test="ead:head">
                                        <xsl:apply-templates select="child::*/ead:head"/>        
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:apply-templates select="child::*/ead:unittitle"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </a>
                        </li>
                        <!-- Creates a submenu for subfonds, subgrp or subseries -->    
                        <xsl:for-each select="child::*[@level = 'subfonds'] | child::*[@level = 'subgrp']  | child::*[@level = 'subseries']">
                            <li class="submenu2">
                                <a href="#{local:buildID(.)}">
                                    <xsl:choose>
                                        <xsl:when test="ead:head">
                                            <xsl:apply-templates select="child::*/ead:head"/>        
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:apply-templates select="child::*/ead:unittitle"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </a>
                            </li>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:for-each>
            </ul>
        </div>
    </xsl:template>
    
    <!-- 
        Formats children of archdesc. This template orders the children of the archdesc, 
        if order is changed, remeber to also change it in the table of contents as well.
    -->
    <!-- Calls and organizes children of the archdesc -->
    <xsl:template match="ead:archdesc">  
        <div id="content">
            <xsl:apply-templates select="/ead:ead/ead:eadheader/ead:filedesc/ead:titlestmt"/>
            <xsl:apply-templates select="ead:did"/>
            <xsl:apply-templates select="ead:bioghist"/>
            <xsl:apply-templates select="ead:scopecontent"/>
            <xsl:apply-templates select="ead:arrangement"/>
            <xsl:apply-templates select="ead:fileplan"/>
            
            <!-- Administrative Information  -->
            <xsl:if test="ead:accessrestrict or ead:userestrict or
                ead:custodhist or ead:accruals or ead:altformavail or ead:acqinfo or 
                ead:processinfo or ead:appraisal or ead:originalsloc or 
                /ead:ead/ead:eadheader/ead:filedesc/ead:publicationstmt or /ead:ead/ead:eadheader/ead:revisiondesc">
                <div class="section">
                    <h2 id="adminInfo">Administrative Information</h2>
                    <xsl:apply-templates select="ead:accessrestrict | ead:userestrict |
                        ead:custodhist | ead:accruals | ead:altformavail | ead:acqinfo |  
                        ead:processinfo | ead:appraisal | ead:originalsloc | 
                        /ead:ead/ead:eadheader/ead:filedesc/ead:publicationstmt | /ead:ead/ead:eadheader/ead:revisiondesc"/>
                    <xsl:call-template name="top"/>
                </div>
            </xsl:if>
            
            <!-- Related Materials -->
            <xsl:if test="ead:relatedmaterial or ead:separatedmaterial">
                <div class="section">
                    <h2 id="relMat">Related Materials</h2>
                    <xsl:apply-templates select="ead:relatedmaterial | ead:separatedmaterial"/>
                    <xsl:call-template name="top"/>
                </div>
            </xsl:if>
            
            <xsl:apply-templates select="ead:controlaccess"/>
            <xsl:apply-templates select="ead:otherfindaid"/>
            <xsl:apply-templates select="ead:phystech"/>
            <xsl:apply-templates select="ead:odd"/>
            <xsl:apply-templates select="ead:bibliography"/>
            <xsl:apply-templates select="ead:index"/>
            <xsl:apply-templates select="ead:dsc"/>        
            
        </div>
    </xsl:template>
    
    <!-- Finding aid title -->
    <xsl:template match="ead:titlestmt">
        <div id="header">
            <h1>
                <xsl:choose>
                    <xsl:when test="ead:titleproper[@type='filing']">
                        <xsl:apply-templates select="ead:titleproper[@type='filing']"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="ead:titleproper[1]"/>
                    </xsl:otherwise>
                </xsl:choose>
            </h1>
            <xsl:if test="ead:subtitle">
                <h2><xsl:apply-templates select="ead:subtitle"/></h2>
            </xsl:if>            
        </div>
    </xsl:template>
    
    <!-- Formats archdesc did -->
    <xsl:template match="ead:archdesc/ead:did">
        <div class="section">
            <h2 id="{local:buildID(.)}">Summary Information</h2>
            <div class="sectionContent">
                <!-- 
                    Determines the order in wich elements from the archdesc did appear, 
                    to change the order of appearance for the children of did
                    by changing the order of the following statements.
                -->
                <dl class="summary">
                    <xsl:apply-templates select="ead:repository" mode="overview"/>
                    <xsl:apply-templates select="ead:origination" mode="overview"/>
                    <xsl:apply-templates select="ead:unittitle" mode="overview"/>    
                    <xsl:apply-templates select="ead:unitid" mode="overview"/>
                    <xsl:apply-templates select="ead:unitdate" mode="overview"/>
                    <xsl:apply-templates select="ead:physdesc" mode="overview"/>        
                    <xsl:apply-templates select="ead:physloc" mode="overview"/> 
                    <xsl:apply-templates select="ead:dao" mode="overview"/>
                    <xsl:apply-templates select="ead:daogrp" mode="overview"/>
                    <xsl:apply-templates select="ead:langmaterial" mode="overview"/>
                    <xsl:apply-templates select="ead:materialspec" mode="overview"/>
                    <xsl:apply-templates select="ead:container" mode="overview"/>
                    <xsl:apply-templates select="ead:abstract" mode="overview"/> 
                    <xsl:apply-templates select="ead:note" mode="overview"/>
                </dl>
                <xsl:apply-templates select="../ead:prefercite" mode="overview"/>
            </div>
            <xsl:call-template name="top"/>
        </div>
    </xsl:template>
    
    <!-- Formats prefercite in the summary -->
    <xsl:template match="ead:prefercite" mode="overview">
        <div class="citation">
            <div class="section">
                <h3><xsl:value-of select="local:tagName(.)"/></h3>
                <div class="sectionContent">
                <xsl:apply-templates/>
                </div>
            </div>
        </div>    
    </xsl:template>
    
    <!-- Formats children of arcdesc/did -->
    <xsl:template match="ead:repository | ead:origination | ead:unittitle | ead:unitdate | ead:unitid  
        | ead:physdesc | ead:physloc | ead:dao | ead:daogrp | ead:langmaterial | ead:materialspec | ead:container 
        | ead:abstract | ead:note" mode="overview">
        <dt>
            <xsl:choose>
                <!-- Test for label attribute used by origination element -->
                <xsl:when test="@label">
                    <xsl:value-of select="concat(upper-case(substring(@label,1,1)),substring(@label,2))"></xsl:value-of>
                    <xsl:if test="@type"> [<xsl:value-of select="@type"/>]</xsl:if>
                    <xsl:if test="self::ead:origination">
                        <xsl:choose>
                            <xsl:when test="ead:persname[@role != ''] and contains(ead:persname/@role,' (')">
                                - <xsl:value-of select="substring-before(ead:persname/@role,' (')"/>
                            </xsl:when>
                            <xsl:when test="ead:persname[@role != '']">
                                - <xsl:value-of select="ead:persname/@role"/>  
                            </xsl:when>
                            <xsl:otherwise/>
                        </xsl:choose>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="local:tagName(.)"/>
                    <!-- Test for type attribute used by unitdate -->
                    <xsl:if test="@type"> [<xsl:value-of select="@type"/>]</xsl:if>
                </xsl:otherwise>
            </xsl:choose>: 
        </dt>
        <dd><xsl:apply-templates/></dd>
    </xsl:template>
    <!-- Adds space between extents -->
    <xsl:template match="ead:extent"><xsl:apply-templates/><xsl:text> </xsl:text></xsl:template>  
    
    <!-- Formats children of arcdesc -->
    <xsl:template match="ead:bibliography | ead:odd | ead:phystech | ead:otherfindaid | 
        ead:bioghist | ead:scopecontent | ead:arrangement | ead:fileplan">
        <div class="section">
            <h2 id="{local:buildID(.)}"><xsl:value-of select="local:tagName(.)"/></h2>
            <div class="sectionContent">
                <xsl:apply-templates/>
            </div>
            <xsl:call-template name="top"/>
        </div>
    </xsl:template>

    <!-- Formats children of arcdesc in administrative and related materials sections -->
    <xsl:template match="ead:relatedmaterial | ead:separatedmaterial | ead:accessrestrict | ead:userestrict |
        ead:custodhist | ead:accruals | ead:altformavail | ead:acqinfo |  
        ead:processinfo | ead:appraisal | ead:originalsloc">
        <div class="section">
            <h3 id="{local:buildID(.)}"><xsl:value-of select="local:tagName(.)"/></h3>
            <div class="sectionContent">
                <xsl:apply-templates/>
            </div>
        </div>
    </xsl:template>
    
    <!-- Publication statement included in administrative information section -->
    <xsl:template match="ead:publicationstmt">
        <div class="section">
            <h3 id="{local:buildID(.)}"><xsl:value-of select="local:tagName(.)"/></h3>
            <div class="sectionContent">
                <p><xsl:apply-templates select="ead:publisher"/>
                    <xsl:if test="ead:date"><xsl:text> </xsl:text><xsl:apply-templates select="ead:date"/></xsl:if>
                </p>    
                <xsl:apply-templates select="ead:address"/>
            </div>
        </div>
    </xsl:template>
    
    <!-- Formats address elements -->
    <xsl:template match="ead:address">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="ead:addressline">
        <xsl:choose>
            <xsl:when test="contains(.,'@')">
                <span class="addressLine">
                    <a href="mailto:{.}"><xsl:apply-templates/></a>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <span class="addressLine">
                    <xsl:apply-templates/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Formats revision description  -->
    <xsl:template match="ead:revisiondesc">
        <div class="section">
        <h3 id="{local:buildID(.)}"><xsl:value-of select="local:tagName(.)"/></h3>
            <div class="sectionContent">
                <p>
                    <xsl:if test="ead:change/ead:item"><xsl:apply-templates select="ead:change/ead:item"/></xsl:if>
                    <xsl:if test="ead:change/ead:date"><xsl:text> </xsl:text><xsl:apply-templates select="ead:change/ead:date"/></xsl:if>
                </p>
            </div>
        </div>
    </xsl:template>

    <!-- Formats controlled access terms -->
    <xsl:template match="ead:controlaccess">
        <div class="section">
            <h2 id="{local:buildID(.)}"><xsl:value-of select="local:tagName(.)"/></h2>
            <div class="sectionContent">
                    <ul>
                        <xsl:apply-templates/>
                    </ul>    
            </div>
            <xsl:call-template name="top"/>
        </div>
        <!-- 
            To sort by type change the above to:
            <xsl:for-each-group select="child::*" group-by="name(.)">
                <xsl:sort select="current-grouping-key()"/>
                <h2 id="{local:buildID(.)}"><xsl:value-of select="local:tagName(.)"/></h2>
                <div class="sectionContent">
                    <ul>
                        <xsl:for-each select="current-group()">
                            <li><xsl:apply-templates/></li>
                        </xsl:for-each>
                    </ul>
                </div>
            </xsl:for-each-group>
        -->
    </xsl:template>
    <xsl:template match="ead:controlaccess/child::*">
        <li><xsl:apply-templates/></li>
    </xsl:template>
    
    <!-- Formats index and child elements, groups indexentry elements by type (i.e. corpname, subject...)    -->
    <xsl:template match="ead:index">
        <div class="section">        
            <h2 id="{local:buildID(.)}"><xsl:value-of select="local:tagName(.)"/></h2>
            <div class="sectionContent">
                <xsl:apply-templates select="child::*[not(self::ead:indexentry)]"/>
                    <ul>
                        <xsl:apply-templates select="ead:indexentry"/>
                    </ul>    
            </div>
            <xsl:call-template name="top"/>
        </div>
    </xsl:template>
    <xsl:template match="ead:indexentry">
        <li><xsl:apply-templates/></li>
    </xsl:template>
    <xsl:template match="ead:indexentry/ead:ref">
        <span class="ref"><xsl:apply-templates/></span>
    </xsl:template> 
       
    <!--Formats a simple table. The width of each column is defined by the colwidth attribute in a colspec element. -->
    <xsl:template match="ead:table">
            <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="ead:table/ead:thead">
        <h4><xsl:apply-templates/></h4>
    </xsl:template>
    <xsl:template match="ead:tgroup">
        <table>
            <xsl:apply-templates/>
        </table>
    </xsl:template>
    <xsl:template match="ead:colspec">
        <td width="{@colwidth}"/>
    </xsl:template>
    <xsl:template match="ead:thead">
        <xsl:apply-templates mode="thead"/>
    </xsl:template>
    <xsl:template match="ead:tbody">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="ead:row" mode="thead">
        <tr class="thead"><xsl:apply-templates/></tr>
    </xsl:template>
    <xsl:template match="ead:row">
        <tr><xsl:apply-templates/></tr>
    </xsl:template>
    <xsl:template match="ead:entry">
        <td><xsl:apply-templates/></td>
    </xsl:template>
    
    <!--Bibref citation inline, if there is a p parent element.-->
    <xsl:template match="ead:p/ead:bibref">
        <xsl:choose>
            <xsl:when test="@*:href">
                <a href="{@*:href}"><xsl:apply-templates/></a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--Bibref citation on its own line, typically when it is a child of the bibliography element-->
    <xsl:template match="ead:bibref">
        <p class="list">
            <xsl:choose>
                <xsl:when test="@*:href">
                    <a href="{@*:href}"><xsl:apply-templates/></a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </p>
    </xsl:template>
    
    <!-- Output for a variety of list types -->
    <xsl:template match="ead:list">
        <xsl:apply-templates select="ead:head"/>
        <!-- Selects list type -->
        <xsl:choose>
            <xsl:when test="ead:listhead">
                <table class="tlist">
                    <tr>
                        <th><xsl:value-of select="ead:listhead/ead:head01"/></th>
                        <th><xsl:value-of select="ead:listhead/ead:head02"/></th>
                    </tr>
                    <xsl:apply-templates select="ead:defitem" mode="listTable"/>
                </table>
            </xsl:when>
            <xsl:when test="@type = 'simple'">
                <ul class="simple">
                    <xsl:apply-templates select="ead:item"/>
                </ul>
            </xsl:when>
            <xsl:when test="@type = 'deflist'">
                <dl>
                    <xsl:apply-templates select="ead:defitem"/>
                </dl>
            </xsl:when>
            <xsl:when test="@type = 'marked'">
                <ul>
                    <xsl:apply-templates select="ead:item"/>                    
                </ul>
            </xsl:when>
            <xsl:when test="@type = 'ordered'">
                <ol>
                    <xsl:if test="@numeration">
                        <xsl:attribute name="class"><xsl:value-of select="@numeration"/></xsl:attribute>
                    </xsl:if>
                    <xsl:apply-templates select="ead:item"/>
                </ol>
            </xsl:when>
            <xsl:otherwise>
                <ul class="simple">
                    <xsl:apply-templates select="ead:item"/>
                </ul>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template> 
    <xsl:template match="ead:list/ead:item">
        <li><xsl:apply-templates/></li>
    </xsl:template>
    <xsl:template match="ead:defitem">
        <dt><xsl:apply-templates select="ead:label"/></dt>
        <dd><xsl:apply-templates select="ead:item"/></dd>
    </xsl:template>
    
    <!-- Formats list as tabel if list has listhead element  -->         
    <xsl:template match="ead:defitem" mode="listTable">
        <tr>
            <td><xsl:apply-templates select="ead:label"/></td>
            <td><xsl:apply-templates select="ead:item"/></td>
        </tr>
    </xsl:template>
    
    <!-- Output chronlist and children in a table -->
    <xsl:template match="ead:chronlist">
        <table>
            <xsl:apply-templates/>
        </table>
    </xsl:template>
    <xsl:template match="ead:chronlist/ead:listhead">
        <tr>
            <th><xsl:apply-templates select="ead:head01"/></th>
            <th><xsl:apply-templates select="ead:head02"/></th>
        </tr>
    </xsl:template>
    <xsl:template match="ead:chronlist/ead:head">
        <tr>
            <th colspan="2"><xsl:apply-templates/></th>
        </tr>
    </xsl:template>
    <xsl:template match="ead:chronitem">
        <tr>
            <!-- Adds alternating colors to table rows -->
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="(position() mod 2 = 0)">odd</xsl:when>
                    <xsl:otherwise>even</xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <td><xsl:apply-templates select="ead:date"/></td>
            <td><xsl:apply-templates select="descendant::ead:event"/></td>
        </tr>
    </xsl:template>
    <xsl:template match="ead:event">
        <xsl:choose>
            <xsl:when test="following-sibling::*">
                <xsl:apply-templates/><br/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Formats notestmt and notes -->
    <xsl:template match="ead:notestmt">
        <h4>Note</h4>
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="ead:note">
        <xsl:choose>
            <xsl:when test="parent::ead:notestmt">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="@label"><h4><xsl:value-of select="@label"/></h4><xsl:apply-templates/></xsl:when>
                    <xsl:otherwise><h4>Note</h4><xsl:apply-templates/></xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Formats legalstatus -->
    <xsl:template match="ead:legalstatus">
        <p><span class="strong"><xsl:value-of select="local:tagName(.)"/>:</span><xsl:text> </xsl:text><xsl:apply-templates/></p>
    </xsl:template>
    
    <!-- General headings -->
    <!-- Most head tags are handled by local:tagName function --> 
    <xsl:template match="ead:head[parent::*/parent::ead:archdesc]"/>
    <xsl:template match="ead:head">
        <h4 id="{local:buildID(parent::*)}"><xsl:apply-templates/></h4>
    </xsl:template>
    
   <!-- Linking elmenets -->
    <xsl:template match="ead:ref">
        <a href="#{@target}">
            <xsl:if test="@*:title">
                <xsl:attribute name="title"><xsl:value-of select="@*:title"/></xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="text()">
                    <xsl:value-of select="."/>
                </xsl:when>
                <xsl:when test="@*:title">
                    <xsl:value-of select="@*:title"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@target"/>
                </xsl:otherwise>
            </xsl:choose>
        </a>
    </xsl:template>
    <xsl:template match="ead:ptr">
        <a href="#{@taget}">
            <xsl:if test="@*:title">
                <xsl:attribute name="title"><xsl:value-of select="@*:title"/></xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="child::*">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:when test="@*:title">
                    <xsl:value-of select="@*:title"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@target"/>
                </xsl:otherwise>
            </xsl:choose>
        </a>
    </xsl:template>
    <xsl:template match="ead:extref">
        <a href="{@*:href}">
            <xsl:if test="@*:title">
                <xsl:attribute name="title"><xsl:value-of select="@*:title"/></xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="text()">
                    <xsl:value-of select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@*:href"/>
                </xsl:otherwise>
            </xsl:choose>
        </a>
    </xsl:template>
    <xsl:template match="ead:extrefloc">
        <a href="{@*:href}">
            <xsl:if test="@*:title">
                <xsl:attribute name="title"><xsl:value-of select="@*:title"/></xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="text()">
                    <xsl:value-of select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@*:href"/>
                </xsl:otherwise>
            </xsl:choose>
        </a>
    </xsl:template>    
    <xsl:template match="ead:extptr[@*:entityref]">
        <a href="{@*:entityref}">
            <xsl:choose>
                <xsl:when test="@*:title"><xsl:value-of select="@*:title"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="@*:entityref"/></xsl:otherwise>
            </xsl:choose>        
        </a>
    </xsl:template>
    <xsl:template match="ead:extptr[@*:href]">
        <a href="{@*:href}">
            <xsl:choose>
                <xsl:when test="@*:title"><xsl:value-of select="@*:title"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="@*:href"/></xsl:otherwise>
            </xsl:choose>        
        </a>
    </xsl:template>
    <xsl:template match="ead:dao">
        <a href="{@*:href}">
            <xsl:if test="@*:title">
                <xsl:attribute name="title"><xsl:value-of select="@*:title"/></xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="child::*">
                    <xsl:value-of select="."/>
                </xsl:when>
                <xsl:when test="@*:title">
                    <xsl:value-of select="@*:title"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@*:href"/>
                </xsl:otherwise>
            </xsl:choose>
        </a>
    </xsl:template>
    <xsl:template match="ead:daogrp">
        <div>
            <xsl:apply-templates/>            
        </div>
    </xsl:template>
    <xsl:template match="ead:daoloc">
        <a href="{@*:href}">
            <xsl:if test="@*:title">
                <xsl:attribute name="title"><xsl:value-of select="@*:title"/></xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="text()">
                    <xsl:value-of select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@*:href"/>
                </xsl:otherwise>
            </xsl:choose>
        </a>
    </xsl:template>
    
    <!--Render elements -->
    <xsl:template match="*[@render = 'bold'] | *[@altrender = 'bold'] ">
        <xsl:if test="preceding-sibling::*"> <xsl:text> </xsl:text></xsl:if><strong><xsl:apply-templates/></strong>
    </xsl:template>
    <xsl:template match="*[@render = 'bolddoublequote'] | *[@altrender = 'bolddoublequote']">
        <xsl:if test="preceding-sibling::*"> <xsl:text> </xsl:text></xsl:if><strong>"<xsl:apply-templates/>"</strong>
    </xsl:template>
    <xsl:template match="*[@render = 'boldsinglequote'] | *[@altrender = 'boldsinglequote']">
        <xsl:if test="preceding-sibling::*"> <xsl:text> </xsl:text></xsl:if><strong>'<xsl:apply-templates/>'</strong>
    </xsl:template>
    <xsl:template match="*[@render = 'bolditalic'] | *[@altrender = 'bolditalic']">
        <xsl:if test="preceding-sibling::*"> <xsl:text> </xsl:text></xsl:if><strong><em><xsl:apply-templates/></em></strong>
    </xsl:template>
    <xsl:template match="*[@render = 'boldsmcaps'] | *[@altrender = 'boldsmcaps']">
        <xsl:if test="preceding-sibling::*"> <xsl:text> </xsl:text></xsl:if><strong><span class="smcaps"><xsl:apply-templates/></span></strong>
    </xsl:template>
    <xsl:template match="*[@render = 'boldunderline'] | *[@altrender = 'boldunderline']">
        <xsl:if test="preceding-sibling::*"> <xsl:text> </xsl:text></xsl:if><strong><span class="underline"><xsl:apply-templates/></span></strong>
    </xsl:template>
    <xsl:template match="*[@render = 'doublequote'] | *[@altrender = 'doublequote']">
        <xsl:if test="preceding-sibling::*"> <xsl:text> </xsl:text></xsl:if>"<xsl:apply-templates/>"
    </xsl:template>
    <xsl:template match="*[@render = 'italic'] | *[@altrender = 'italic']">
        <xsl:if test="preceding-sibling::*"> <xsl:text> </xsl:text></xsl:if><em><xsl:apply-templates/></em>
    </xsl:template>
    <xsl:template match="*[@render = 'singlequote'] | *[@altrender = 'singlequote']">
        <xsl:if test="preceding-sibling::*"> <xsl:text> </xsl:text></xsl:if>'<xsl:apply-templates/>'
    </xsl:template>
    <xsl:template match="*[@render = 'smcaps'] | *[@altrender = 'smcaps']">
        <xsl:if test="preceding-sibling::*"> <xsl:text> </xsl:text></xsl:if><span class="smcaps"><xsl:apply-templates/></span>
    </xsl:template>
    <xsl:template match="*[@render = 'sub'] | *[@altrender = 'sub']">
        <xsl:if test="preceding-sibling::*"> <xsl:text> </xsl:text></xsl:if><sub><xsl:apply-templates/></sub>
    </xsl:template>
    <xsl:template match="*[@render = 'super'] | *[@altrender = 'super']">
        <xsl:if test="preceding-sibling::*"> <xsl:text> </xsl:text></xsl:if><sup><xsl:apply-templates/></sup>
    </xsl:template>
    <xsl:template match="*[@render = 'underline'] | *[@altrender = 'underline']">
        <xsl:if test="preceding-sibling::*"> <xsl:text> </xsl:text></xsl:if><span class="underline"><xsl:apply-templates/></span>
    </xsl:template>
   
    <!-- formatting elements -->
    <xsl:template match="ead:p">
        <p><xsl:apply-templates/></p>
    </xsl:template>
    <xsl:template match="ead:lb"><br/></xsl:template>
    <xsl:template match="ead:blockquote">
        <blockquote><xsl:apply-templates/></blockquote>
    </xsl:template>
    <xsl:template match="ead:emph[not(@render)]"><em><xsl:apply-templates/></em></xsl:template>
    
    <!-- Collection Inventory (dsc) templates -->
    <xsl:template match="ead:archdesc/ead:dsc">
        <div class="section">        
            <h2 id="{local:buildID(.)}"><xsl:value-of select="local:tagName(.)"/></h2>
                <table class="dsc">
                    <xsl:if test="child::*[@level][1][@level='item' or @level='file' or @level='otherlevel']">
                        <xsl:call-template name="tableHeaders"/>
                    </xsl:if>
                    <xsl:apply-templates select="*[not(self::ead:head)]"/>
                    <tr>
                        <td/>
                        <td style="width: 12%;"/>
                        <td style="width: 12%;"/>
                        <td style="width: 12%;"/>
                    </tr>
                </table>
        </div>
    </xsl:template>
    
    <!--
        Calls the clevel template passes the calculates the level of current component in xml tree and passes it to clevel template via the level parameter
        Adds a row to with a link to top if level series
    -->
    <xsl:template match="ead:c | ead:c01 | ead:c02 | ead:c03 | ead:c04 | ead:c05 | ead:c06 | ead:c07 | ead:c08 | ead:c09 | ead:c10 | ead:c11 | ead:c12">
        <xsl:variable name="findClevel" select="count(ancestor::*[not(ead:dsc or ead:archdesc or ead:ead)])"/>
        <xsl:call-template name="clevel">
            <xsl:with-param name="level" select="$findClevel"></xsl:with-param>
        </xsl:call-template>
        <xsl:if test="self::*[@level='series']">
            <tr>
                <td colspan="4">
                    <xsl:call-template name="top"/>
                </td>
            </tr>    
        </xsl:if>
    </xsl:template>

    <!--This is a named template that processes all the components  -->
    <xsl:template name="clevel">
        <!-- 
            Establishes which level is being processed in order to provided indented displays. 
            Indents handled by CSS margins
        -->
        <xsl:param name="level" />
        <xsl:variable name="clevelMargin">
            <xsl:choose>
                <xsl:when test="$level = 1">c01</xsl:when>
                <xsl:when test="$level = 2">c02</xsl:when>
                <xsl:when test="$level = 3">c03</xsl:when>
                <xsl:when test="$level = 4">c04</xsl:when>
                <xsl:when test="$level = 5">c05</xsl:when>
                <xsl:when test="$level = 6">c06</xsl:when>
                <xsl:when test="$level = 7">c07</xsl:when>
                <xsl:when test="$level = 8">c08</xsl:when>
                <xsl:when test="$level = 9">c09</xsl:when>
                <xsl:when test="$level = 10">c10</xsl:when>
                <xsl:when test="$level = 11">c11</xsl:when>
                <xsl:when test="$level = 12">c12</xsl:when>
            </xsl:choose>
        </xsl:variable>
            <xsl:choose>
                <!--Formats Series and Groups  -->
                <xsl:when test="@level='subcollection' or @level='subgrp' or @level='series' 
                    or @level='subseries' or @level='collection'or @level='fonds' or 
                    @level='recordgrp' or @level='subfonds' or @level='class' or (@level='otherlevel' and not(child::ead:did/ead:container))">
                    <tr id="{local:buildID(.)}">
                        <xsl:attribute name="class">
                            <xsl:choose>
                                <xsl:when test="@level='subcollection' or @level='subgrp' or @level='subseries' or @level='subfonds'">subseries</xsl:when>
                                <xsl:otherwise>series</xsl:otherwise>
                            </xsl:choose>    
                        </xsl:attribute>
                        <th class="{$clevelMargin}" rowspan="{count(ead:did/ead:container[@label]) + 1}">
                            <xsl:if test="not(ead:did/ead:container)">
                                <xsl:attribute name="colspan">4</xsl:attribute>  
                            </xsl:if>
                            <xsl:apply-templates select="ead:did" mode="dscSeriesTitle"/>
                            <div class="dscSeries">
                                <xsl:apply-templates select="ead:did" mode="dscSeries"/>
                                <xsl:apply-templates select="child::*[not(ead:did) and not(self::ead:did)]" mode="dsc"/>
                            </div>
                        </th>
                    </tr>
                    <!-- Adds grouped instances if they exist -->
                    <xsl:for-each-group select="ead:did/ead:container" group-starting-with=".[@label]">
                        <tr>
                            <xsl:apply-templates select="current-group()" mode="series"/>
                            <xsl:choose>
                                <xsl:when test="count(current-group()) = 1">
                                    <th><span class="containerType"/></th>
                                    <th><span class="containerType"/></th>
                                </xsl:when>
                                <xsl:when test="count(current-group()) = 2">
                                    <th><span class="containerType"/></th>
                                </xsl:when>
                                <xsl:when test="count(current-group()) = 3"/>
                            </xsl:choose>
                        </tr>
                    </xsl:for-each-group>
                    <!-- Adds table headers if child is item or file -->
                    <xsl:if test="child::*[@level][1][@level = 'item' or @level='file' or @level = 'otherlevel']">
                        <xsl:call-template name="tableHeaders"/>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="ead:did/ead:container[@label]">
                    <tr class="item">
                        <td class="{$clevelMargin}" rowspan="{count(ead:did/ead:container[@label]) + 1}">
                            <xsl:apply-templates select="ead:did" mode="dsc"/>  
                            <xsl:apply-templates mode="dsc" select="*[not(self::ead:did) and 
                                not(self::ead:c) and not(self::ead:c02) and not(self::ead:c03) and
                                not(self::ead:c04) and not(self::ead:c05) and not(self::ead:c06) and not(self::ead:c07)
                                and not(self::ead:c08) and not(self::ead:c09) and not(self::ead:c10) and not(self::ead:c11) and not(self::ead:c12)]"/>          
                        </td>
                    </tr>
                    <!-- Groups instances by label attribute, the way they are grouped in ArchivesSpace -->
                    <xsl:for-each-group select="ead:did/ead:container" group-starting-with=".[@label]">
                        <tr>
                            <xsl:apply-templates select="current-group()" />
                            <xsl:choose>
                                <xsl:when test="count(current-group()) &lt; 2">
                                    <td><span class="containerType"/></td>
                                    <td><span class="containerType"/></td>
                                </xsl:when>
                                <xsl:when test="count(current-group()) &lt; 3">
                                    <td><span class="containerType"/></td>
                                </xsl:when>
                            </xsl:choose>
                        </tr>
                    </xsl:for-each-group>
                </xsl:when>
               <!-- For finding aids with no @label attribute, only accounts for three containers -->
                <xsl:otherwise>
                    <tr class="item">
                        <td class="{$clevelMargin}" rowspan="{count(ead:did/ead:container[@label]) + 1}">
                            <xsl:apply-templates select="ead:did" mode="dsc"/>  
                            <xsl:apply-templates mode="dsc" select="*[not(self::ead:did) and 
                                not(self::ead:c) and not(self::ead:c02) and not(self::ead:c03) and
                                not(self::ead:c04) and not(self::ead:c05) and not(self::ead:c06) and not(self::ead:c07)
                                and not(self::ead:c08) and not(self::ead:c09) and not(self::ead:c10) and not(self::ead:c11) and not(self::ead:c12)]"/>          
                        </td>
                        <td>
                            <span class="containerType"><xsl:value-of select="ead:did/ead:container[1]/@type"/></span><xsl:text> </xsl:text><xsl:value-of select="ead:did/ead:container[1]"/>
                        </td>
                        <td class="container">
                            <span class="containerType"><xsl:value-of select="ead:did/ead:container[2]/@type"/></span><xsl:text> </xsl:text><xsl:value-of select="ead:did/ead:container[2]"/>
                        </td>
                        <td class="container">
                            <span class="containerType"><xsl:value-of select="ead:did/ead:container[3]/@type"/></span><xsl:text> </xsl:text><xsl:value-of select="ead:did/ead:container[3]"/>
                        </td>
                    </tr>
                </xsl:otherwise>
            </xsl:choose>
        <!-- Calls child components -->
        <xsl:apply-templates select="ead:c | ead:c01 | ead:c02 | ead:c03 | ead:c04 | ead:c05 | ead:c06 | ead:c07 | ead:c08 | ead:c09 | ead:c10 | ead:c11 | ead:c12"/>
    </xsl:template>
    <!-- Named template for table headers -->
    <xsl:template name="tableHeaders">
        <tr class="headers">
            <th>Title/Description</th>
            <th colspan="3">Instances</th>
        </tr>
    </xsl:template>
    <!-- Formats did containers -->
    <xsl:template match="ead:container">
        <td>
            <span class="containerType"><xsl:value-of select="@type"/></span><xsl:text> </xsl:text><xsl:value-of select="."/>
        </td>
    </xsl:template>
    <xsl:template match="ead:container" mode="series">
        <th>
            <span class="containerType"><xsl:value-of select="@type"/></span><xsl:text> </xsl:text><xsl:value-of select="."/>
        </th>
    </xsl:template>

    <!-- Series titles -->
    <xsl:template match="ead:did" mode="dscSeriesTitle">
        <div id="{local:buildID(.)}">
            <h3>
<!--                
            <xsl:if test="ead:unitid">
                <xsl:choose>
                    <xsl:when test="../@level='series'">Series <xsl:value-of select="ead:unitid"/>: </xsl:when>
                    <xsl:when test="../@level='subseries'">Subseries <xsl:value-of select="ead:unitid"/>: </xsl:when>
                    <xsl:when test="../@level='subsubseries'">Sub-Subseries <xsl:value-of select="ead:unitid"/>: </xsl:when>
                    <xsl:when test="../@level='collection'">Collection <xsl:value-of select="ead:unitid"/>: </xsl:when>
                    <xsl:when test="../@level='subcollection'">Subcollection <xsl:value-of select="ead:unitid"/>: </xsl:when>
                    <xsl:when test="../@level='fonds'">Fonds <xsl:value-of select="ead:unitid"/>: </xsl:when>
                    <xsl:when test="../@level='subfonds'">Subfonds <xsl:value-of select="ead:unitid"/>: </xsl:when>
                    <xsl:when test="../@level='recordgrp'">Record Group <xsl:value-of select="ead:unitid"/>: </xsl:when>
                    <xsl:when test="../@level='subgrp'">Subgroup <xsl:value-of select="ead:unitid"/>: </xsl:when>
                    <xsl:otherwise><xsl:value-of select="ead:unitid"/>: </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            -->
            <xsl:apply-templates select="ead:unittitle"/>
                <xsl:if test="(string-length(ead:unittitle[1]) &gt; 1) and (string-length(ead:unitdate[1]) &gt; 1)">, </xsl:if>
            <xsl:apply-templates select="ead:unitdate" mode="did"/>
            </h3>
        </div>
    </xsl:template>
    <!-- Formats unitdates -->
    <xsl:template match="ead:unitdate[@type = 'bulk']" mode="did">
        (<xsl:apply-templates/>)
    </xsl:template>
    <xsl:template match="ead:unitdate" mode="did"><xsl:apply-templates/></xsl:template>
    
    <!-- Series child elements -->
    <xsl:template match="ead:did" mode="dscSeries">            
        <xsl:apply-templates select="ead:repository" mode="dsc"/>            
        <xsl:apply-templates select="ead:origination" mode="dsc"/>            
        <xsl:apply-templates select="ead:unitdate" mode="dsc"/>            
        <xsl:apply-templates select="ead:physdesc" mode="dsc"/>                    
        <xsl:apply-templates select="ead:physloc" mode="dsc"/>             
        <xsl:apply-templates select="ead:dao" mode="dsc"/>            
        <xsl:apply-templates select="ead:daogrp" mode="dsc"/>            
        <xsl:apply-templates select="ead:langmaterial" mode="dsc"/>            
        <xsl:apply-templates select="ead:materialspec" mode="dsc"/>            
        <xsl:apply-templates select="ead:abstract" mode="dsc"/>             
        <xsl:apply-templates select="ead:note" mode="dsc"/>
    </xsl:template>
    
    <!-- Unittitles and all other clevel elements -->
    <xsl:template match="ead:did" mode="dsc">
           <span class="didTitle">
               <xsl:apply-templates select="ead:unittitle"/>
               <xsl:if test="(string-length(ead:unittitle[1]) &gt; 1) and (string-length(ead:unitdate[1]) &gt; 1)">, </xsl:if>
               <xsl:apply-templates select="ead:unitdate" mode="did"/>   
           </span> 
        <xsl:apply-templates select="ead:repository" mode="dsc"/>            
        <xsl:apply-templates select="ead:origination" mode="dsc"/>            
        <xsl:apply-templates select="ead:unitdate" mode="dsc"/>            
        <xsl:apply-templates select="ead:physdesc" mode="dsc"/>                    
        <xsl:apply-templates select="ead:physloc" mode="dsc"/>             
        <xsl:apply-templates select="ead:dao" mode="dsc"/>            
        <xsl:apply-templates select="ead:daogrp" mode="dsc"/>            
        <xsl:apply-templates select="ead:langmaterial" mode="dsc"/>            
        <xsl:apply-templates select="ead:materialspec" mode="dsc"/>            
        <xsl:apply-templates select="ead:abstract" mode="dsc"/>             
        <xsl:apply-templates select="ead:note" mode="dsc"/>
    </xsl:template>
   
    <!-- Special formatting for elements in the collection inventory list -->
    <xsl:template match="ead:repository | ead:origination | ead:unitdate | ead:unitid  
        | ead:physdesc | ead:physloc | ead:daogrp | ead:langmaterial | ead:materialspec | ead:container 
        | ead:abstract | ead:note" mode="dsc">
        <xsl:if test="child::*">
            <p>
                <span class="dscHeaders">
                <xsl:choose>
                    <!-- Test for label attribute used by origination element -->
                    <xsl:when test="@label">
                        <xsl:value-of select="concat(upper-case(substring(@label,1,1)),substring(@label,2))"></xsl:value-of>
                        <xsl:if test="@type"> [<xsl:value-of select="@type"/>]</xsl:if>
                        <xsl:if test="self::ead:origination">
                            <xsl:choose>
                                <xsl:when test="ead:persname[@role != ''] and contains(ead:persname/@role,' (')">
                                    - <xsl:value-of select="substring-before(ead:persname/@role,' (')"/>
                                </xsl:when>
                                <xsl:when test="ead:persname[@role != '']">
                                    - <xsl:value-of select="ead:persname/@role"/>  
                                </xsl:when>
                                <xsl:otherwise/>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="local:tagName(.)"/>
                        <!-- Test for type attribute used by unitdate -->
                        <xsl:if test="@type"> [<xsl:value-of select="@type"/>]</xsl:if>
                    </xsl:otherwise>
                </xsl:choose></span>: <xsl:apply-templates/>
            </p>            
        </xsl:if>
    </xsl:template>
    <xsl:template match="ead:relatedmaterial | ead:separatedmaterial | ead:accessrestrict | ead:userestrict |
        ead:custodhist | ead:accruals | ead:altformavail | ead:acqinfo |  
        ead:processinfo | ead:appraisal | ead:originalsloc" mode="dsc">
        <p>
            <span class="dscHeaders"><xsl:value-of select="local:tagName(.)"/>: </span>
                <xsl:apply-templates select="child::*[not(self::ead:head)]"/>
        </p>
    </xsl:template>
    <xsl:template match="ead:index" mode="dsc">
        <xsl:apply-templates select="child::*[not(self::ead:indexentry)]"/>
            <ul>                
                <xsl:apply-templates select="ead:indexentry"/>                    
            </ul>    
    </xsl:template>
    <xsl:template match="ead:controlaccess" mode="dsc">
        <p class="dscHeaders"><xsl:value-of select="local:tagName(.)"/>:</p>
            <ul>
                   <xsl:apply-templates/>
            </ul>    
    </xsl:template>
    <xsl:template match="ead:dao" mode="dsc">
        <p>
            <span class="dscHeaders"><xsl:value-of select="local:tagName(.)"/>:</span>
            <a href="{@*:href}">
                <xsl:if test="@*:title">
                    <xsl:attribute name="title"><xsl:value-of select="@*:title"/></xsl:attribute>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="child::*">
                        <xsl:value-of select="."/>
                    </xsl:when>
                    <xsl:when test="@*:title">
                        <xsl:value-of select="@*:title"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@*:href"/>
                    </xsl:otherwise>
                </xsl:choose>
            </a>
        </p> 
    </xsl:template>
    <!-- Formats all other children of the dsc -->
    <xsl:template mode="dsc" match="*">
        <xsl:if test="child::*">
            <xsl:apply-templates/>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>