<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xlink="http://www.w3.org/1999/xlink" 
    xmlns:local="http://www.yoursite.org/namespace" 
    xmlns:eac="urn:isbn:1-931666-33-4" version="2.0"  
    exclude-result-prefixes="#all">
    <!--
        *******************************************************************
        *                                                                 *
        * VERSION:          1.0                                           *
        *                                                                 *
        * AUTHOR:           Winona Salesky                                *
        *                   wsalesky@gmail.com                            *
        *                                                                 *
        * DATE:             2013-08-22                                    *
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
    
    <!-- Title -->
    <xsl:variable name="title">
        <xsl:value-of select="/eac:eac-cpf/eac:cpfDescription/eac:identity/eac:nameEntry[eac:authorizedForm]/child::*[not(self::eac:authorizedForm)]"></xsl:value-of>
    </xsl:variable>
    
    <!-- HTML metadata tags -->
    <xsl:template name="metadata">
        <meta http-equiv="Content-Type" name="dc.title" content="{$title}"/>
        <meta http-equiv="Content-Type" name="dc.author" content="{/eac:eac-cpf/eac:control/eac:maintenanceAgency/eac:agencyName}" />
        <meta http-equiv="Content-Type" name="dc.type" content="text" />
        <meta http-equiv="Content-Type" name="dc.format" content="manuscripts" />
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
            /* publication statement*/
            .publication {display:block; float: right; margin-right:2em; font-size:.75em;}
            
            .maintenance {
                text-align:right;
                background-color: #f0f0f0;
                margin:1em;
                padding: .5em 2em;
            }
            dl.summary {
                width:100%;
                overflow:hidden;
                clear:both;
            }
            dl.summary dt {
                float:left;
                width:28%; 
                text-align:right;
                clear:left;
            }
            dl.summary dt.authorized {font-weight: 600; color:#666666;}
            dl.summary dt.alternative {margin-left: 1.5em;}
            dl.summary dd {
                margin-left: 30%;
                padding-left:1em;
                width:70%;
                clear:right;
            }
            dl.summary dd.authorized {font-weight: 600; color:#666666;}
            
            
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
            .level {margin-left:1em;}
            .noPadding{padding: .15em; margin:0;}
            .component {margin-bottom:1em;}
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
            
        </style>
    </xsl:template>
    
    <!-- Named template for a generic p element with a link back to the the top of the page  -->
    <xsl:template name="top">
        <p class="top"><a href="#main"><strong>^</strong> Top</a></p>
    </xsl:template>
    
    <!-- Build html page -->
    <xsl:template match="/eac:eac-cpf">
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
                <title><xsl:value-of select="$title"/></title>
                <xsl:call-template name="metadata"/>
                <xsl:call-template name="css"/>
            </head>
            <body>
                <div class="publication"><xsl:apply-templates select="eac:control/eac:maintenanceAgency/eac:agencyName"/></div>
                <div id="main">    
                    <xsl:apply-templates select="/eac:eac-cpf" mode="toc"/>
                    <div id="content">
                        <div id="header">
                            <h1><xsl:value-of select="$title"/></h1>
                        </div>
                        <xsl:apply-templates select="eac:cpfDescription"/>
                        <xsl:apply-templates select="eac:control"/>
                    </div>
                </div>
            </body>
        </html>
    </xsl:template>
    
    <!-- Build Table of Contents/Left Menu -->
    <xsl:template match="eac:eac-cpf" mode="toc">
        <div id="toc">
            <ul>
                <xsl:if test="eac:cpfDescription/eac:identity">
                    <li><a href="#{local:buildID(eac:cpfDescription/eac:identity)}"><xsl:value-of select="local:tagName(eac:cpfDescription/eac:identity)"/></a></li>
                </xsl:if>
                <xsl:if test="eac:cpfDescription/eac:description">
                    <li><a href="#{local:buildID(eac:cpfDescription/eac:description)}"><xsl:value-of select="local:tagName(eac:cpfDescription/eac:description)"/></a></li>
                </xsl:if>
                <xsl:if test="eac:cpfDescription/eac:relations">
                    <li><a href="#{local:buildID(eac:cpfDescription/eac:relations)}"><xsl:value-of select="local:tagName(eac:cpfDescription/eac:relations)"/></a></li>
                </xsl:if>
                <xsl:if test="eac:cpfDescription/eac:alternativeSet">
                    <li><a href="#{local:buildID(eac:cpfDescription/eac:alternativeSet)}"><xsl:value-of select="local:tagName(eac:cpfDescription/eac:alternativeSet)"/></a></li>
                </xsl:if>
                <xsl:if test="eac:control">
                    <li><a href="#{local:buildID(eac:control)}">Administrative Information</a></li>
                </xsl:if>
            </ul>
        </div>
    </xsl:template>
    
    <!-- Start control/administrative information-->
    <xsl:template match="eac:control">
        <div class="section">
            <h2 id="{local:buildID(.)}">Administrative Information</h2>
            <div class="sectionContent">
                <dl class="summary">
                    <xsl:apply-templates select="eac:recordId"/>
                    <xsl:apply-templates select="eac:maintenanceAgency"/>
                    <xsl:apply-templates select="eac:languageDeclaration"/>
                    <xsl:apply-templates select="eac:conventionDeclaration"/>
                    <xsl:apply-templates select="eac:sources"/>
                </dl>
                <xsl:apply-templates select="eac:maintenanceHistory"/>
            </div>
            <xsl:call-template name="top"/>
        </div>
    </xsl:template>
    <xsl:template match="eac:recordId">
        <dt>ID: </dt>
        <dd><xsl:apply-templates/></dd>
    </xsl:template>
    <xsl:template match="eac:maintenanceAgency">
        <dt>Maintenance Agency: </dt>
        <dd><xsl:apply-templates select="eac:agencyName"/></dd>
    </xsl:template>
    <xsl:template match="eac:languageDeclaration">
        <dt>Language: </dt>
        <dd><xsl:apply-templates select="eac:language"/></dd>
    </xsl:template>
    <xsl:template match="eac:script"/>
    <xsl:template match="eac:conventionDeclaration">
        <dt>Convention Declaration: </dt>
        <dd><xsl:apply-templates select="eac:citation"/> <xsl:if test="eac:abbreviation"> [<xsl:apply-templates select="eac:abbreviation"/>]</xsl:if></dd>
    </xsl:template>
    <xsl:template match="eac:citation[@xlink:href]">
        <a href="{@xlink:href}"><xsl:apply-templates/></a>
    </xsl:template>
    <xsl:template match="eac:sources">
        <dt>Sources: </dt>
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="eac:source">
        <dd><xsl:apply-templates/> <xsl:if test="@xlink:href"><br/><a href="{@xlink:href}"><xsl:value-of select="@xlink:href"/></a></xsl:if></dd>
    </xsl:template>
    <xsl:template match="eac:maintenanceHistory">
        <div class="maintenance">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="eac:maintenanceEvent">
        <strong><xsl:value-of select="eac:eventType"/> by <xsl:value-of select="eac:agent"/></strong>&#160;<xsl:value-of select="eac:eventDateTime"/><br/> 
    </xsl:template>
    
    <!-- Start  cpfDescription -->
    <!-- Names -->
    <xsl:template match="eac:identity">
        <div class="section">
            <h2 id="{local:buildID(.)}"><xsl:value-of select="local:tagName(.)"/> 
                <xsl:choose>
                    <xsl:when test="eac:entityType = 'person'"> - Person</xsl:when>
                    <xsl:when test="eac:entityType = 'family'"> - Family</xsl:when>
                    <xsl:when test="eac:entityType = 'corporateBody'"> - Corporate</xsl:when>
                </xsl:choose>
            </h2>
            <div class="sectionContent">
                <dl class="summary">
                    <xsl:apply-templates select="eac:nameEntry"/>
                </dl>
            </div>
            <xsl:call-template name="top"/>
        </div>
    </xsl:template>
    <xsl:template match="eac:nameEntry">
        <dt>
            <xsl:choose>
                <xsl:when test="eac:authorizedForm">
                    <xsl:attribute name="class">authorized</xsl:attribute>
                    Authorized Form [<xsl:value-of select="eac:authorizedForm"/>]: 
                </xsl:when>
                <xsl:when test="eac:alternativeForm">
                    <xsl:attribute name="class">alternative</xsl:attribute>
                    Alternative Form [<xsl:value-of select="eac:alternativeForm"/>]: 
                </xsl:when>
            </xsl:choose>
        </dt>
        <dd>
            <xsl:choose>
                <xsl:when test="eac:authorizedForm">
                    <xsl:attribute name="class">authorized</xsl:attribute> 
                </xsl:when>
                <xsl:when test="eac:alternativeForm">
                    <xsl:attribute name="class">alternative</xsl:attribute>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="eac:part"/>
        </dd>
    </xsl:template>
    <xsl:template match="eac:part">
        <xsl:if test="preceding-sibling::*"> </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- Description elements -->
    <xsl:template match="eac:description">
        <div class="section">
            <h2 id="{local:buildID(.)}"><xsl:value-of select="local:tagName(.)"/></h2>
            <div class="sectionContent">
                <dl class="summary">
                    <xsl:apply-templates select="eac:places | eac:place | eac:languageUsed | eac:occupations | eac:existDates | eac:localDescription"/>
                </dl>
            </div>
            <xsl:call-template name="top"/>
            <div class="sectionContent">
                <xsl:apply-templates select="eac:biogHist | eac:structureOrGenealogy | eac:generalContext | eac:functions | eac:function"/>
            </div>
        </div>
    </xsl:template>
    <!-- Place data -->
    <xsl:template match="eac:place | eac:languageUsed | eac:occupations | eac:existDates | eac:localDescription">
        <dt>
            <xsl:choose>
                <xsl:when test="self::eac:place">Place <xsl:apply-templates select="eac:placeRole"/></xsl:when>
                <xsl:when test="self::eac:languageUsed">Language Used</xsl:when>
                <xsl:when test="self::eac:occupations">Occupations</xsl:when>
                <xsl:when test="self::eac:existDates">Dates of existence</xsl:when>
                <xsl:when test="self::eac:localDescription"><xsl:value-of select="@localType"/></xsl:when>
            </xsl:choose>
        </dt>
        <dd>
            <xsl:apply-templates select="*[not(self::eac:placeRole)]"/>    
        </dd>
    </xsl:template>
    <xsl:template match="eac:placeRole">
         [<xsl:apply-templates/>] 
    </xsl:template>
    <xsl:template match="eac:dateRange">
        <xsl:apply-templates select="eac:fromDate"/> - <xsl:apply-templates select="eac:toDate"/>
    </xsl:template>
    <xsl:template match="eac:term">
        <xsl:apply-templates/> <xsl:if test="@vocabularySource"> [<xsl:value-of select="@vocabularySource"/>]</xsl:if><br/>
    </xsl:template>
    
    <!-- Build children of the description element -->   
    <xsl:template match="eac:biogHist | eac:structureOrGenealogy | eac:generalContext | eac:functions ">
        <div class="section">
            <h3><xsl:value-of select="local:tagName(.)"/></h3>
            <div class="sectionContent">
                <xsl:apply-templates/>
            </div>
            <xsl:call-template name="top"/>
        </div>
    </xsl:template>
    <xsl:template match="eac:function">
        <dl>
            <xsl:apply-templates/>
        </dl>
    </xsl:template>
    <xsl:template match="eac:function/eac:term">
        <dt><xsl:apply-templates/></dt>
    </xsl:template>
    <xsl:template match="eac:function/eac:descriptiveNote">
        <dd><xsl:apply-templates/></dd>
    </xsl:template>
    <xsl:template match="eac:function/eac:descriptiveNote/eac:p">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- Start relations templates -->
    <xsl:template match="eac:relations | eac:alternativeSet">
        <div class="section">
            <h2 id="{local:buildID(.)}"><xsl:value-of select="local:tagName(.)"/></h2>
            <div class="sectionContent">    
                <xsl:apply-templates/>
            </div>
            <xsl:call-template name="top"/>
        </div>
    </xsl:template>
    <xsl:template match="eac:resourceRelation">
        <h4><a href="@xlink:href"><xsl:apply-templates select="eac:relationEntry"/></a></h4>
        <xsl:apply-templates select="eac:descriptiveNote"/>
    </xsl:template>    
    <xsl:template match="eac:cpfRelation">
        <h4><a href="{@xlink:href}"><xsl:apply-templates select="eac:relationEntry"/></a></h4>
        <xsl:apply-templates select="eac:descriptiveNote"/>
    </xsl:template>
    
    <xsl:template match="eac:descriptiveNote[not(eac:p)]">
        <p><xsl:apply-templates/></p>
    </xsl:template>
    <xsl:template match="eac:abstract">
        <h4>Abstract</h4>
        <blockquote><p><xsl:apply-templates/></p></blockquote>
    </xsl:template>
    <xsl:template match="eac:chronList">
        <table>
            <xsl:apply-templates/>
            <tr><td width="25%"></td><td></td></tr>
        </table>
    </xsl:template>
    <xsl:template match="eac:chronItem">
        <tr>
            <!-- Adds alternating colors to table rows -->
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="(position() mod 2 = 0)">odd</xsl:when>
                    <xsl:otherwise>even</xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <td><xsl:apply-templates select="eac:date | eac:dateRange"/></td>
            <td><xsl:apply-templates select="descendant::eac:event"/></td>
        </tr>
    </xsl:template>
    <xsl:template match="eac:event">
        <xsl:choose>
            <xsl:when test="following-sibling::*">
                <xsl:apply-templates/><br/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="eac:setComponent">
        <div class="component">
            <xsl:apply-templates/>
            <br/>
            <xsl:if test="@xlink:href">
                <a href="{@xlink:href}"><xsl:value-of select="@xlink:href"/></a>
            </xsl:if>
        </div>
    </xsl:template>
    <xsl:template match="eac:outline">
        <h4>Outline</h4>
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="eac:level">
        <div class="level">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="eac:level/eac:item">
        <p class="noPadding"><xsl:apply-templates/></p>
    </xsl:template>
    <xsl:template match="eac:list">
        <ul><xsl:apply-templates/></ul>
    </xsl:template>
    <xsl:template match="eac:list/eac:item">
        <li><xsl:apply-templates/></li>
    </xsl:template>
    <xsl:template match="eac:p">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="eac:span">
        <xsl:copy-of select="self::*"/>
    </xsl:template>
</xsl:stylesheet>