<?xml version="1.0" encoding="utf-8"?>

<!--  h2d.xsl 
 | Migrate XHTML content into DITA topics
 |
 | (C) Copyright IBM Corporation 2001, 2002, 2003, 2004, 2005. All Rights Reserved.
 | This file is related to the DITA package on IBM's developerWorks site.
 | See license.txt for disclaimers.
 +
 | Updates:
 | 2005/06/16 AN Nest indexterms nicely
 | 2005/06/16 AN Remove related group tables
 | 2005/06/20 AN Prevent blank indexterms
 | 2005/06/21 AN Prevent blank keywords
 | 2005/07/11 AN Ensure sections created after tables in Ref topics
 | 2005/07/11 AN Reverse nesting of xref and uicontrol
 | 2006/03/21 AN Fix Ref topics with tables
 | 2006/03/21 AN Merge Incipient styles
 | 2006/03/28 AN Fix glossaryterm to work with xref
 | 2008/09/04 AN Change table expanse attribute to pgwide (conform with OASIS DITA)
 |
 +-->

<xsl:stylesheet version="1.1" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
                
<!-- Retain white space within all <code> elements -->
<xsl:preserve-space elements="pre blockquote"/>
 
<xsl:param name="infotype">
    <xsl:call-template name="lowerCase">
        <xsl:with-param name="inputString" select="/html/head/meta[@name='dita-topic-type']/@content"/>
    </xsl:call-template>
</xsl:param>

<xsl:output method="xml" indent="yes" encoding="utf-8" /> 

    
<!-- ========== PARAMETERS ============== -->

<!-- What extension should be used for links that go to other DITA topics?
     Assumption is that local HTML targets will be converted to DITA. -->
<xsl:param name="dita-extension">.dita</xsl:param>

<!-- Create a parameter for the defualt language.
    Look for an attribute on html element -->
<xsl:param name="default-lang">
    <xsl:choose>
        <xsl:when test="/html/@lang"><xsl:value-of select="/html/@lang"/></xsl:when>    
        <xsl:otherwise>en-us</xsl:otherwise>
    </xsl:choose>
</xsl:param>

<!-- Take the filename as an input parameter to determine the main topic's ID -->
<xsl:param name="FILENAME" />

<!-- Use the FILENAME to determine the ID for the output topic. Invalid ID characters
     must be removed (replaced with generic D character). If a filename starts with
     a number, which cannot start an ID, all numbers will be replaced with letters. -->
<xsl:variable name="filename-id">
  <xsl:choose>
    <xsl:when test="starts-with($FILENAME,'0') or starts-with($FILENAME,'1') or
                    starts-with($FILENAME,'2') or starts-with($FILENAME,'3') or
                    starts-with($FILENAME,'4') or starts-with($FILENAME,'5') or
                    starts-with($FILENAME,'6') or starts-with($FILENAME,'7') or
                    starts-with($FILENAME,'8') or starts-with($FILENAME,'9') or
                    starts-with($FILENAME,'.') or starts-with($FILENAME,'-')">
        <xsl:value-of select="translate(substring-before($FILENAME,'.htm'),
                                      '0123456789.-,!@#$%^()=+[]{}/\;&amp;',
                                      'ABCDEFGHIJDDDDDDDDDDDDDDDDDDDDDD')"/>
    </xsl:when>
    <xsl:otherwise>
        <xsl:value-of select="translate(substring-before($FILENAME,'.htm'),
                                      ',!@#$%^()=+[]{}/\;&amp;',
                                      'DDDDDDDDDDDDDDDDDDDDDD')"/>
    </xsl:otherwise>         
  </xsl:choose>
</xsl:variable>

<xsl:variable name="main-head-level">
  <xsl:choose>
    <xsl:when test="/html/body/descendant::h1[1][not(preceding::h2|preceding::h3|preceding::h4|preceding::h5|preceding::h6)]">h1</xsl:when>
    <xsl:when test="/html/body/descendant::h2[1][not(preceding::h3|preceding::h4|preceding::h5|preceding::h6)]">h2</xsl:when>
    <xsl:when test="/html/body/descendant::h3[1][not(preceding::h4|preceding::h5|preceding::h6)]">h3</xsl:when>
    <xsl:when test="/html/body/descendant::h4[1][not(preceding::h5|preceding::h6)]">h4</xsl:when>
    <xsl:when test="/html/body/descendant::h5[1][not(preceding::h6)]">h5</xsl:when>
    <xsl:when test="/html/body/descendant::h6[1]">h6</xsl:when>
    <xsl:otherwise>h1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template name="output-message">
    <xsl:param name="msg" select="***"/>
    <xsl:message><xsl:value-of select="$msg"/></xsl:message>
</xsl:template>

<!-- if needed, add the dita wrapper here -->


<!-- Process the HTML file that was placed in a variable using normal routines. -->
<xsl:template match="*" mode="redirect">
  <xsl:apply-templates select="."/>
</xsl:template>

<!-- general the overall topic container and pull content for it -->

<xsl:template match="html">
  <xsl:choose>
    <xsl:when test="$infotype='topic'"><xsl:call-template name="gen-topic"/></xsl:when>
    <xsl:when test="$infotype='concept'"><xsl:call-template name="gen-concept"/></xsl:when>
    <xsl:when test="$infotype='task'"><xsl:call-template name="gen-task"/></xsl:when>
    <xsl:when test="$infotype='reference'"><xsl:call-template name="gen-reference"/></xsl:when>
    <xsl:otherwise><xsl:call-template name="gen-topic"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- named templates for various infotyped topic shells -->

<!-- Generic topic template -->

<xsl:template name="gen-topic">
  <topic xml:lang="{$default-lang}">
    <xsl:call-template name="genidattribute"/>
    <xsl:call-template name="gentitle"/>
    <xsl:call-template name="gentitlealts"/>
    <xsl:call-template name="genprolog"/>
    <body>
      <xsl:apply-templates select="(body/*|body/text()|body/comment())[1]" mode="creating-content-before-section"/>
      <xsl:choose>
        <xsl:when test="$main-head-level='h1'">
          <xsl:apply-templates select="body/h1[preceding-sibling::h1]|body/h2|body/h3|body/h4|body/h5|body/h6|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>
        </xsl:when>
        <xsl:when test="$main-head-level='h2'">
          <xsl:apply-templates select="body/h1|body/h2[preceding-sibling::h2]|body/h3|body/h4|body/h5|body/h6|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>                              
        </xsl:when>
        <xsl:when test="$main-head-level='h3'">
          <xsl:apply-templates select="body/h1|body/h2|body/h3[preceding-sibling::h3]|body/h4|body/h5|body/h6|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>                              
        </xsl:when>
        <xsl:when test="$main-head-level='h4'">
          <xsl:apply-templates select="body/h1|body/h2|body/h3|body/h4[preceding-sibling::h4]|body/h5|body/h6|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>                              
        </xsl:when>
        <xsl:when test="$main-head-level='h5'">
          <xsl:apply-templates select="body/h1|body/h2|body/h3|body/h4|body/h5[preceding-sibling::h5]|body/h6|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>                              
        </xsl:when>
        <xsl:otherwise> <!-- Otherwise, level is h6 -->
          <xsl:apply-templates select="body/h1|body/h2|body/h3|body/h4|body/h5|body/h6[preceding-sibling::h6]|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>                              
        </xsl:otherwise>
      </xsl:choose>
    </body>
<!--
    <xsl:call-template name="genrellinks"/> 
-->
  </topic>
</xsl:template>


<!-- Implementation note: except for topic, DITA infotypes have content models with strong
     containment rules.  These implementations try to separate allowed body content from
     contexts required by the target formats. This may need additional work.  With XHTML 2.0,
     the tests for contextually introduced containment are eased and these templates can be
     generalized and possibly made more robust. -->

<!-- Concept topic template -->

<!-- See task for ideas implemented here for separating regular body content from a first heading, which
     ordinarily denotes one or more sections with NO following text.  We put EVERYTHING after the
     first h2 into a section as a strong-arm way to enforce the concept model, but users will have
     to check for intended scoping afterwards. -->

<xsl:template name="gen-concept">
  <concept xml:lang="{$default-lang}">
    <xsl:call-template name="genidattribute"/>
    <xsl:if test="@id"><xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute></xsl:if>
    <xsl:call-template name="gentitle"/>
    <xsl:call-template name="gentitlealts"/>
    <xsl:call-template name="genprolog"/>

    <conbody>
      <!-- Anything up to the first heading (except for whatever heading was pulled into <title>) will
           be processed as it would for a topic. After a heading is encountered, a section will be created
           for that and all following headings. Content up to the next heading will go into the section. -->
      <xsl:apply-templates select="(body/*|body/text()|body/comment())[1]" mode="creating-content-before-section"/>
      <xsl:choose>
        <xsl:when test="$main-head-level='h1'">
          <xsl:apply-templates select="body/h1[preceding-sibling::h1]|body/h2|body/h3|body/h4|body/h5|body/h6|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>
        </xsl:when>
        <xsl:when test="$main-head-level='h2'">
          <xsl:apply-templates select="body/h1|body/h2[preceding-sibling::h2]|body/h3|body/h4|body/h5|body/h6|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>                              
        </xsl:when>
        <xsl:when test="$main-head-level='h3'">
          <xsl:apply-templates select="body/h1|body/h2|body/h3[preceding-sibling::h3]|body/h4|body/h5|body/h6|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>                              
        </xsl:when>
        <xsl:when test="$main-head-level='h4'">
          <xsl:apply-templates select="body/h1|body/h2|body/h3|body/h4[preceding-sibling::h4]|body/h5|body/h6|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>                              
        </xsl:when>
        <xsl:when test="$main-head-level='h5'">
          <xsl:apply-templates select="body/h1|body/h2|body/h3|body/h4|body/h5[preceding-sibling::h5]|body/h6|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>                              
        </xsl:when>
        <xsl:otherwise> <!-- Otherwise, level is h6 -->
          <xsl:apply-templates select="body/h1|body/h2|body/h3|body/h4|body/h5|body/h6[preceding-sibling::h6]|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>                              
        </xsl:otherwise>
      </xsl:choose>
      
    </conbody>
<!-- AN Removed
    <xsl:call-template name="genrellinks"/>
-->
  </concept>
</xsl:template>

<xsl:template match="*|text()|comment()" mode="creating-content-before-section">
  <xsl:apply-templates select="."/>
  <xsl:apply-templates select="(following-sibling::*|following-sibling::text()|following-sibling::comment())[1]" mode="creating-content-before-section"/>
</xsl:template>
<xsl:template match="h1|h2|h3|h4|h5|h6|p[@class='subheading']" mode="creating-content-before-section">
  <xsl:choose>
    <!--  <xsl:when test="$main-head-level='h1' and ((self::h1 and not(preceding::h1)) or self::p[@class='subheading'])"> -->
    <xsl:when test="$main-head-level='h1' and self::h1 and not(preceding::h1)"> 
      <xsl:apply-templates select="(following-sibling::*|following-sibling::text()|following-sibling::comment())[1]" mode="creating-content-before-section"/>
    </xsl:when>
    <xsl:when test="$main-head-level='h2' and self::h2 and not(preceding::h2)">
      <xsl:apply-templates select="(following-sibling::*|following-sibling::text()|following-sibling::comment())[1]" mode="creating-content-before-section"/>
    </xsl:when>
    <xsl:when test="$main-head-level='h3' and self::h3 and not(preceding::h3)">
      <xsl:apply-templates select="(following-sibling::*|following-sibling::text()|following-sibling::comment())[1]" mode="creating-content-before-section"/>
    </xsl:when>
    <xsl:when test="$main-head-level='h4' and self::h4 and not(preceding::h4)">
      <xsl:apply-templates select="(following-sibling::*|following-sibling::text()|following-sibling::comment())[1]" mode="creating-content-before-section"/>
    </xsl:when>
    <xsl:when test="$main-head-level='h5' and self::h5 and not(preceding::h5)">
      <xsl:apply-templates select="(following-sibling::*|following-sibling::text()|following-sibling::comment())[1]" mode="creating-content-before-section"/>
    </xsl:when>
    <xsl:when test="$main-head-level='h6' and self::h6 and not(preceding::h6)">
      <xsl:apply-templates select="(following-sibling::*|following-sibling::text()|following-sibling::comment())[1]" mode="creating-content-before-section"/>
    </xsl:when>
  </xsl:choose>
</xsl:template>

<!-- Reference topic template -->

<xsl:template name="gen-reference">
  <reference xml:lang="{$default-lang}">
    <xsl:call-template name="genidattribute"/>
    <xsl:call-template name="gentitle"/>
    <xsl:call-template name="gentitlealts"/>
    <xsl:call-template name="genprolog"/>
    <refbody>
      <!-- Processing is similar to concept, except that everything before the second heading must also be
           placed into a section. Also, any tables can be outside of the section. -->
      <xsl:choose>

          <xsl:when test="$main-head-level='h1'">
              <!-- First process anything that comes before any subheadings, or a second hN -->
              <xsl:if test="body/text()[not(preceding::table or preceding::h1[2] or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6)]|
                        body/comment()[not(preceding::table or preceding::h1[2] or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6)]|
                        body/*[not(self::table or self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6 or self::p[@class='subheading'] or
                                   preceding::table or preceding::h1[2] or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6 or preceding::p[@class='subheading'])]">
                  <section>
                      <xsl:apply-templates select="body/text()[not(preceding::table or preceding::h1[2] or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6)]|
                                           body/comment()[not(preceding::table or preceding::h1[2] or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6)]|
                                           body/*[not(self::table or self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6 or self::p[@class='subheading'] or
                                                      preceding::table or preceding::h1[2] or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6 or preceding::p[@class='subheading'])]"/>
                  </section>
              </xsl:if>
              <!-- Now turn any other headings into sections, with following stuff -->
            <xsl:apply-templates select="body/table|body/h1[preceding-sibling::h1]|body/h2|body/h3|body/h4|body/h5|body/h6|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>
          </xsl:when>

          <xsl:when test="$main-head-level='h2'">
          <!-- First process anything that comes before any subheadings, or a second hN -->
          <xsl:if test="body/text()[not(preceding::table or preceding::h1 or preceding::h2[2] or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6)]|
                        body/comment()[not(preceding::table or preceding::h1 or preceding::h2[2] or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6)]|
                        body/*[not(self::table or self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6 or self::p[@class='subheading'] or
                                   preceding::table or preceding::h1 or preceding::h2[2] or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6 or preceding::p[@class='subheading'])]">
            <section>
              <xsl:apply-templates select="body/text()[not(preceding::table or preceding::h1 or preceding::h2[2] or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6)]|
                                           body/comment()[not(preceding::table or preceding::h1 or preceding::h2[2] or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6)]|
                                           body/*[not(self::table or self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6 or self::p[@class='subheading'] or
                                                      preceding::table or preceding::h1 or preceding::h2[2] or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6 or preceding::p[@class='subheading'])]"/>
            </section>
          </xsl:if>
          <!-- Now turn any other headings into sections, with following stuff -->
            <xsl:apply-templates select="body/table|body/h1|body/h2[preceding-sibling::h2]|body/h3|body/h4|body/h5|body/h6|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>
        </xsl:when>
        <xsl:when test="$main-head-level='h3'">
          <!-- First process anything that comes before any subheadings, or a second hN -->
          <xsl:if test="body/text()[not(preceding::table or preceding::h1 or preceding::h2 or preceding::h3[2] or preceding::h4 or preceding::h5 or preceding::h6)]|
                        body/comment()[not(preceding::table or preceding::h1 or preceding::h2 or preceding::h3[2] or preceding::h4 or preceding::h5 or preceding::h6)]|
                        body/*[not(self::table or self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6 or self::p[@class='subheading'] or
                                   preceding::table or preceding::h1 or preceding::h2 or preceding::h3[2] or preceding::h4 or preceding::h5 or preceding::h6 or preceding::p[@class='subheading'])]">
            <section>
              <xsl:apply-templates select="body/text()[not(preceding::table or preceding::h1 or preceding::h2 or preceding::h3[2] or preceding::h4 or preceding::h5 or preceding::h6)]|
                                           body/comment()[not(preceding::table or preceding::h1 or preceding::h2 or preceding::h3[2] or preceding::h4 or preceding::h5 or preceding::h6)]|
                                           body/*[not(self::table or self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6 or self::p[@class='subheading'] or
                                                      preceding::table or preceding::h1 or preceding::h2 or preceding::h3[2] or preceding::h4 or preceding::h5 or preceding::h6 or preceding::p[@class='subheading'])]"/>
            </section>
          </xsl:if>
          <!-- Now turn any other headings into sections, with following stuff -->
          <xsl:apply-templates select="body/table|body/h1|body/h2|body/h3[preceding-sibling::h3]|body/h4|body/h5|body/h6|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>
        </xsl:when>
        <xsl:when test="$main-head-level='h4'">
          <!-- First process anything that comes before any subheadings, or a second hN -->
          <xsl:if test="body/text()[not(preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4[2] or preceding::h5 or preceding::h6)]|
                        body/text()[not(preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4[2] or preceding::h5 or preceding::h6)]|
                        body/*[not(self::table or self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6 or self::p[@class='subheading'] or
                                   preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4[2] or preceding::h5 or preceding::h6 or preceding::p[@class='subheading'])]">
            <section>
              <xsl:apply-templates select="body/text()[not(preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4[2] or preceding::h5 or preceding::h6)]|
                                           body/comment()[not(preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4[2] or preceding::h5 or preceding::h6)]|
                                           body/*[not(self::table or self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6 or self::p[@class='subheading'] or
                                                      preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4[2] or preceding::h5 or preceding::h6 or preceding::p[@class='subheading'])]"/>
            </section>
          </xsl:if>
          <!-- Now turn any other headings into sections, with following stuff -->
          <xsl:apply-templates select="body/table|body/h1|body/h2|body/h3|body/h4[preceding-sibling::h4]|body/h5|body/h6|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>
        </xsl:when>
        <xsl:when test="$main-head-level='h5'">
          <!-- First process anything that comes before any subheadings, or a second hN -->
          <xsl:if test="body/text()[not(preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5[2] or preceding::h6)]|
                        body/comment()[not(preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5[2] or preceding::h6)]|
                        body/*[not(self::table or self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6 or self::p[@class='subheading'] or
                                   preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5[2] or preceding::h6 or preceding::p[@class='subheading'])]">
            <section>
              <xsl:apply-templates select="body/text()[not(preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5[2] or preceding::h6)]|
                                           body/comment()[not(preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5[2] or preceding::h6)]|
                                           body/*[not(self::table or self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6 or self::p[@class='subheading'] or
                                                      preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5[2] or preceding::h6 or preceding::p[@class='subheading'])]"/>
            </section>
          </xsl:if>
          <!-- Now turn any other headings into sections, with following stuff -->
          <xsl:apply-templates select="body/table|body/h1|body/h2|body/h3|body/h4|body/h5[preceding-sibling::h5]|body/h6|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>
        </xsl:when>
        <xsl:otherwise>
          <!-- First process anything that comes before any subheadings, or a second hN -->
          <xsl:if test="body/text()[not(preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6[2])]|
                        body/comment()[not(preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6[2])]|
                        body/*[not(self::table or self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6 or self::p[@class='subheading'] or
                                   preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6[2] or preceding::p[@class='subheading'])]">
            <section>
              <xsl:apply-templates select="body/text()[not(preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6[2])]|
                                           body/comment()[not(preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6[2])]|
                                           body/*[not(self::table or self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6 or self::p[@class='subheading'] or
                                                      preceding::table or preceding::h1 or preceding::h2 or preceding::h3 or preceding::h4 or preceding::h5 or preceding::h6[2] or preceding::p[@class='subheading'])]"/>
            </section>
          </xsl:if>
          <!-- Now turn any other headings into sections, with following stuff -->
          <xsl:apply-templates select="body/table|body/h1|body/h2|body/h3|body/h4|body/h5|body/h6[preceding-sibling::h6]|body/h7|body/p[@class='subheading']" mode="create-section-with-following-content"/>
        </xsl:otherwise>
      </xsl:choose>
    </refbody>
<!-- AN removed    
    <xsl:call-template name="genrellinks"/>
-->
  </reference>
</xsl:template>


<!-- Task topic template -->

<xsl:template name="gen-task">
  <task xml:lang="{$default-lang}">
    <xsl:call-template name="genidattribute"/>
    <xsl:call-template name="gentitle"/>
    <xsl:call-template name="gentitlealts"/>
    <xsl:call-template name="genprolog"/>
    <taskbody>
      <!--Optional prereq section goes here-->

      <!--context [any child elements with no preceding ol]-->
      <xsl:if test="body/text()[not(preceding-sibling::ol)]|body/comment()[not(preceding-sibling::ol)]|body/*[not(preceding-sibling::ol)][not(self::ol)]">
        <context>
          <xsl:apply-templates select="body/text()[not(preceding-sibling::ol)]|body/comment()[not(preceding-sibling::ol)]|body/*[not(preceding-sibling::ol)][not(self::ol)]"/>
        </context>
      </xsl:if>

      <!--steps [first ol within a body = steps!] -->
      <xsl:if test="body/ol">
        <steps>
          <xsl:apply-templates select="body/ol[1]/li|body/ol[1]/comment()" mode="steps"/>
        </steps>
      </xsl:if>

      <!--result [any children with a preceding ol]-->
      <xsl:if test="body/text()[preceding-sibling::ol]|body/comment()[preceding-sibling::ol]|body/*[preceding-sibling::ol]">
        <result>
          <xsl:apply-templates select="body/text()[preceding-sibling::ol]|body/comment()[preceding-sibling::ol]|body/*[preceding-sibling::ol]"/>
        </result>
      </xsl:if>

      <!--Optional example section-->
      <!--Optional postreq section-->

    </taskbody>
<!-- AN removed    
    <xsl:call-template name="genrellinks"/>
-->    
  </task>
</xsl:template>

<!-- this template handle ol/li processing within a task -->
<!-- The default behavior is to put each <li> into a <step>. If this is being
     used to create substeps, the $steptype parameter is passed in as "substep".
     If the <li> does not contain blocklike info, put everything in <cmd>. Otherwise,
     put everything up to the first block into <cmd>. Everything from the first block
     on will be placed in substeps (if it is an OL) or in <info> (everything else).  -->
<xsl:template match="li" mode="steps">
  <xsl:param name="steptype">step</xsl:param>
  <xsl:element name="{$steptype}">
    <xsl:choose>
      <xsl:when test="not(p|div|ol|ul|table|dl|pre)">
        <cmd><xsl:apply-templates select="*|comment()|text()"/></cmd>
      </xsl:when>
      <xsl:otherwise>
        <cmd><xsl:apply-templates select="(./*|./text())[1]" mode="step-cmd"/></cmd>
        <xsl:apply-templates select="(p|div|ol|ul|table|dl|pre|comment())[1]" mode="step-child"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:element>
</xsl:template>
<xsl:template match="comment()" mode="steps">
  <xsl:apply-templates select="."/>
</xsl:template>

<!-- Add content to a <cmd>. If this is block like, stop iterating and return to the li.
     Otherwise, output the current node using normal processing, and move to the next
     text or element node. -->
<xsl:template match="p|div|ol|ul|table|dl|pre" mode="step-cmd"/>
<xsl:template match="text()|*" mode="step-cmd">
  <xsl:apply-templates select="."/>
  <xsl:apply-templates select="(following-sibling::*|following-sibling::text())[1]" mode="step-cmd"/>
</xsl:template>

<!-- If an ol is inside a step, convert it to substeps. If it is inside substeps, put it in info.
     For any other elements, create an info, and output the current node. Also output the
     following text or element node, which will work up to any <ol>. -->
<xsl:template match="ol" mode="step-child">
  <xsl:choose>
    <!-- If already in substeps -->
    <xsl:when test="parent::li/parent::ol/parent::li/parent::ol">
      <info><xsl:apply-templates select="."/></info>
    </xsl:when>
    <xsl:otherwise>
      <substeps>
        <xsl:apply-templates select="li" mode="steps">
          <xsl:with-param name="steptype">substep</xsl:with-param>
        </xsl:apply-templates>
      </substeps>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:apply-templates select="(following-sibling::*|following-sibling::text())[1]" mode="step-child"/>
</xsl:template>

<xsl:template match="text()|*|comment()" mode="step-child">
  <xsl:choose>
    <xsl:when test="self::* or string-length(normalize-space(.))>0">
      <info>
        <xsl:apply-templates select="."/>
        <xsl:apply-templates select="(following-sibling::*|following-sibling::text()|following-sibling::comment())[1]" mode="add-to-info"/>
      </info>
    </xsl:when>
    <xsl:otherwise>
      <!-- Ignore empty text nodes and empty comments, move on to the next node -->
      <xsl:apply-templates select="(following-sibling::*|following-sibling::text()|following-sibling::comment())[1]" mode="step-child"/>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:apply-templates select="following-sibling::ol[1]" mode="step-child"/>
</xsl:template>

<!-- When adding to <info>, if an ol is found, stop: it will become substeps, or its own info.
     Anything else: output the element, and then output the following text or element node,
     remaining inside <info>. -->
<xsl:template match="ol" mode="add-to-info"/>
<xsl:template match="*|text()|comment()" mode="add-to-info">
    <xsl:apply-templates select="."/>
    <xsl:apply-templates select="(following-sibling::*|following-sibling::text()|following-sibling::comment())[1]" mode="add-to-info"/>
</xsl:template>

<!-- Support for generating contextually dependent ID for topics. -->
<!-- This will need to be improved; no HTML will have an id, so only the
     otherwise will trigger. Better test: use the filename or first a/@name
 +-->
<!-- NOTE: this is only to be used for the topic element -->
<xsl:template name="genidattribute">
 <xsl:attribute name="id">
  <xsl:choose>
    <xsl:when test="/html/@id"><xsl:value-of select="/html/@id"/></xsl:when>  
    <xsl:when test="string-length($filename-id)>0"><xsl:value-of select="$filename-id"/></xsl:when>
    <xsl:otherwise><xsl:value-of select="generate-id(/html)"/></xsl:otherwise>
  </xsl:choose>
</xsl:attribute>
</xsl:template>



<!-- named templates for out of line pulls -->

<!-- 02/12/03 drd: mp says to leave this as linklist, not linkpool, for now -->
<xsl:template name="genrellinks">
<xsl:if test=".//a[@href][not(starts-with(@href,'#'))]">
<related-links>
<linklist><title>Collected links</title>
  <xsl:for-each select=".//a[@href][not(starts-with(@href,'#'))]">
    <link>
      <xsl:call-template name="genlinkattrs"/>
      <linktext><xsl:value-of select="."/></linktext>
      <xsl:if test="@title">
        <desc><xsl:value-of select="normalize-space(@title)"/></desc>
      </xsl:if>
    </link>
  </xsl:for-each>
</linklist>
</related-links>
</xsl:if>
</xsl:template>

<xsl:template name="genlinkattrs">
  <xsl:variable name="newfn">
    <xsl:value-of select="substring-before(@href,'.htm')"/>
  </xsl:variable>
  <xsl:choose>
    <!-- If the target is a web site, do not change extension to .dita -->
    <xsl:when test="starts-with(@href,'http:') or starts-with(@href,'https:') or
                    starts-with(@href,'ftp:')">
      <xsl:attribute name="href"><xsl:value-of select="@href" /></xsl:attribute>
      <xsl:attribute name="scope">external</xsl:attribute>
      <xsl:attribute name="format">
        <xsl:choose>
          <xsl:when test="contains(@href,'.pdf') or contains(@href,'.PDF')">pdf</xsl:when>
          <xsl:otherwise>html</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </xsl:when>
    <xsl:when test="string-length($newfn)>0">
      <!-- AN Need to prefix dita topics with "D" -->
      <xsl:attribute name="href">D<xsl:value-of select="$newfn"/><xsl:value-of select="$dita-extension"/></xsl:attribute>
    </xsl:when>
    <xsl:when test="starts-with(@href,'#')">
      <xsl:variable name="infile-reference">
        <xsl:text>#</xsl:text>
        <!-- Need to udpate this if genidattribute changes -->
        <xsl:choose>
          <xsl:when test="string-length($filename-id)>0"><xsl:value-of select="$filename-id"/></xsl:when>
          <xsl:when test="/html/@id"><xsl:value-of select="/html/@id"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="generate-id(/html)"/></xsl:otherwise>
        </xsl:choose>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="substring-after(@href,'#')"/>
      </xsl:variable>
      <!-- output-message? -->
      <xsl:attribute name="href"><xsl:value-of select="$infile-reference"/></xsl:attribute>
    </xsl:when>
    <xsl:otherwise>
      <xsl:attribute name="href"><xsl:value-of select="@href" /></xsl:attribute>
      <xsl:attribute name="format">
        <xsl:choose>
          <xsl:when test="contains(@href,'.pdf') or contains(@href,'.PDF')">pdf</xsl:when>
          <xsl:otherwise>html</xsl:otherwise>  <!-- Default to html -->
        </xsl:choose>
      </xsl:attribute>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:if test="@target='_blank'">
    <xsl:attribute name="scope">external</xsl:attribute>
  </xsl:if>
</xsl:template>

<!-- gentitle was here -->

<xsl:template name="genprolog">
  <!-- produce only if qualifiend meta is extant -->
  <xsl:if test=".//meta[@name][not(@name='Generator' or @name='dita-topic-type')]|head/comment()">
    <!--xsl:comment>
     <prolog>
        author, copyright, critdates, permissions, publisher, source
     <metadata>
      <xsl:apply-templates select="head/comment()"/>
      <xsl:apply-templates select=".//meta[@name='keywords' or @name='Keywords']"/>
      <xsl:apply-templates select=".//meta[not(@name='Generator' or @name='dita-topic-type' or @name='keywords' or @name='Keywords')]" mode="outofline"/>
    </metadata>
  </prolog></xsl:comment-->
</xsl:if>
</xsl:template>



<!-- TBD: do anything rational with scripts or styles in the head? elsewhere? -->
<!-- 05232002 drd: null out scripts, flat out (script in head was nulled out before, 
                   but scripts in body were coming through)
-->
<xsl:template match="script"/>
<xsl:template match="style"/>


<!-- take out some other interactive, non-content gadgets that are not part of the DITA source model -->
<!-- TBD: consider adding messages within these -->
<xsl:template match="textarea"/>
<xsl:template match="input"/>
<xsl:template match="isindex"/>
<xsl:template match="select"/>
<xsl:template match="optgroup"/>
<xsl:template match="option"/>
<xsl:template match="label"/>
<xsl:template match="fieldset"/>
<xsl:template match="basefont"/>
<xsl:template match="col"/>
<xsl:template match="colgroup"/>



<!-- ========== Start of heading-aware code =============== -->


<!-- Generic treatment for all headings (1-9!).  The main title and section level code -->
<!-- have higher priorities that override getting triggered by this generic rule. -->

<xsl:template name="cleanup-heading">
  <xsl:call-template name="output-message">
      <xsl:with-param name="msg">A <xsl:value-of select="name()"/> heading could not be converted into DITA.
The heading has been placed in a required-cleanup element.</xsl:with-param>
  </xsl:call-template>
  <required-cleanup>
    <p>
      <b>[deprecated heading <xsl:value-of select="name()"/> ]: </b>
      <xsl:apply-templates select="*|comment()|text()"/>
    </p>
  </required-cleanup>
</xsl:template>

<xsl:template match="h1" priority="5">
  <xsl:choose>
    <xsl:when test="not(preceding::h1)"/>
    <xsl:when test="$infotype='task'"><xsl:call-template name="cleanup-heading"/></xsl:when>
    <xsl:when test="$main-head-level='h1'"><xsl:call-template name="gensection"/></xsl:when>
    <xsl:otherwise><xsl:call-template name="cleanup-heading"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>
<xsl:template match="h2" priority="5">
  <xsl:choose>
    <xsl:when test="$main-head-level='h2' and not(preceding::h2)"/>
    <xsl:when test="$infotype='task'"><xsl:call-template name="cleanup-heading"/></xsl:when>
    <xsl:when test="$main-head-level='h1' or $main-head-level='h2'"><xsl:call-template name="gensection"/></xsl:when>
    <xsl:otherwise><xsl:call-template name="cleanup-heading"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>
<xsl:template match="h3" priority="5">
  <xsl:choose>
    <xsl:when test="$main-head-level='h3' and not(preceding::h3)"/>
    <xsl:when test="$infotype='task'"><xsl:call-template name="cleanup-heading"/></xsl:when>
    <xsl:when test="$main-head-level='h2' or $main-head-level='h3'"><xsl:call-template name="gensection"/></xsl:when>
    <xsl:otherwise><xsl:call-template name="cleanup-heading"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>
<xsl:template match="h4" priority="5">
  <xsl:choose>
    <xsl:when test="$main-head-level='h4' and not(preceding::h4)"/>
    <xsl:when test="$infotype='task'"><xsl:call-template name="cleanup-heading"/></xsl:when>
    <xsl:when test="$main-head-level='h3' or $main-head-level='h4'"><xsl:call-template name="gensection"/></xsl:when>
    <xsl:otherwise><xsl:call-template name="cleanup-heading"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>
<xsl:template match="h5" priority="5">
  <xsl:choose>
    <xsl:when test="$main-head-level='h5' and not(preceding::h5)"/>
    <xsl:when test="$infotype='task'"><xsl:call-template name="cleanup-heading"/></xsl:when>
    <xsl:when test="$main-head-level='h4' or $main-head-level='h5'"><xsl:call-template name="gensection"/></xsl:when>
    <xsl:otherwise><xsl:call-template name="cleanup-heading"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>
<xsl:template match="h6" priority="5">
  <xsl:choose>
    <xsl:when test="$main-head-level='h6' and not(preceding::h6)"/>
    <xsl:when test="$infotype='task'"><xsl:call-template name="cleanup-heading"/></xsl:when>
    <xsl:when test="$main-head-level='h5' or $main-head-level='h6'"><xsl:call-template name="gensection"/></xsl:when>
    <xsl:otherwise><xsl:call-template name="cleanup-heading"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>
<xsl:template match="h7" priority="5">
  <xsl:choose>
    <xsl:when test="$main-head-level='h6'"><xsl:call-template name="gensection"/></xsl:when>
    <xsl:otherwise><xsl:call-template name="cleanup-heading"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>
<xsl:template match="h8|h9">
  <xsl:call-template name="cleanup-heading"/>
</xsl:template>

<!-- Templates used to pull content following headings into the generated section -->
<xsl:template match="h1|h2|h3|h4|h5|h6|h7|p[@class='subheading']" mode="add-content-to-section"/> 
<xsl:template match="*|text()|comment()" mode="add-content-to-section">
  <xsl:choose>
    <!-- For reference, tables also create a section, so leave them out. Otherwise, they go inside sections. -->
    <xsl:when test="self::table and $infotype='reference'"/>
    <xsl:otherwise>
      <xsl:apply-templates select="."/>
      <xsl:apply-templates select="(following-sibling::*|following-sibling::text()|following-sibling::comment())[1]" mode="add-content-to-section"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="convert-heading-to-section">
  <section>
    <title><xsl:apply-templates select="*|comment()|text()"/></title>
    <xsl:apply-templates select="(following-sibling::*|following-sibling::text()|following-sibling::comment())[1]" mode="add-content-to-section"/>
  </section>
</xsl:template>
<!-- AN 2005/07/11 Simplified
<xsl:template match="h1|h2|h3|h4|h5|h6|h7|p[@class='subheading']|p[@class='instruction']" mode="create-section-with-following-content">
-->
<xsl:template match="*" mode="create-section-with-following-content">
  <xsl:choose>
    <xsl:when test="$main-head-level='h1' and (self::h1 or self::h2 or self::p[@class='subheading'])">
      <xsl:call-template name="convert-heading-to-section"/>
    </xsl:when>
    <xsl:when test="$main-head-level='h2' and (self::h2 or self::h3 or self::p[@class='subheading'])">
      <xsl:call-template name="convert-heading-to-section"/>
    </xsl:when>
    <xsl:when test="$main-head-level='h3' and (self::h3 or self::h4 or self::p[@class='subheading'])">
      <xsl:call-template name="convert-heading-to-section"/>
    </xsl:when>
    <xsl:when test="$main-head-level='h4' and (self::h4 or self::h5 or self::p[@class='subheading'])">
      <xsl:call-template name="convert-heading-to-section"/>
    </xsl:when>
    <xsl:when test="$main-head-level='h5' and (self::h5 or self::h6 or self::p[@class='subheading'])">
      <xsl:call-template name="convert-heading-to-section"/>
    </xsl:when>
    <xsl:when test="$main-head-level='h6' and (self::h6 or self::h7 or self::p[@class='subheading'])">
      <xsl:call-template name="convert-heading-to-section"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="output-message">
        <xsl:with-param name="msg">A <xsl:value-of select="name()"/> heading could not be converted into DITA.
The heading has been placed in a required-cleanup element.</xsl:with-param>
      </xsl:call-template>
      <section>
        <!-- 2005/07/11 AN Ensure sections created after tables in Ref topics
        AN: don't add title if emptpy
        <xsl:if test="normalize-space(*|text()|comment())!=''">
          <title><xsl:apply-templates select="*|text()|comment()"/></title>
        </xsl:if>
        -->
        <xsl:apply-templates select="*|text()|comment()"/>
        <xsl:apply-templates select="(following-sibling::*|following-sibling::text()|following-sibling::comment())[1]" mode="add-content-to-section"/>
      </section>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>
<!-- The next template can only be called when processing items in the reference body -->
<xsl:template match="table" mode="create-section-with-following-content">
  <xsl:apply-templates select="."/>  
  <xsl:if test="(following-sibling::*|following-sibling::text()|following-sibling::comment())[1][not(self::table or self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6 or self::h7 or self::p[@class='subheading'] or self::p[@class='instruction'])]"> 
    <xsl:apply-templates select="(following-sibling::*|following-sibling::text()|following-sibling::comment())[1]" mode="create-section-with-following-content"/>
  </xsl:if>

</xsl:template>

<!-- Special treatment for headings that occur at a section level -->
<xsl:template name="gensection">
<!-- AN removed 
  <section>
    <xsl:variable name="hcnt"><xsl:number/></xsl:variable>
    <! - -<xsl:value-of select="$hcnt"/>- - >
    <title><xsl:apply-templates select="*|text()|comment()"/></title>
    <! - - call recursively for subsequent chunks - - >
    <xsl:call-template name="output-message">
      <xsl:with-param name="msg">A <xsl:value-of select="name()"/> heading was mapped to an empty section.
Move any content that belongs with that heading into the section.</xsl:with-param>
    </xsl:call-template>
  </section>
-->
</xsl:template>


<!-- ========== Start of overrideable heading level code =============== -->

<!-- Default: h1=topic title; h2=section title; all others=bold text -->
<!-- For plain text pull (no problems with content in headings!), use xsl:value-of -->
<!-- (ie, if you use xsl:apply-templates select, you might get unwanted elements in title) -->
<!-- These templates will be overridden by heading-level aware front ends -->
<!-- Note: The generic heading processor treats all headings as priority=1;
           priority=2 in this master transform will override the generic heading processor
           priority=3 in the overrides will override this h1/h2 default setup
 +--> 


<!-- === initially define the defaults for h1/h2 topic/section mappings === -->

<xsl:template name="gentitle">
  <title>
    <xsl:choose>
      <xsl:when test="$main-head-level='h1'"><xsl:value-of select=".//h1[1]"/></xsl:when>
      <xsl:when test="$main-head-level='h2'"><xsl:value-of select=".//h2[1]"/></xsl:when>
      <xsl:when test="$main-head-level='h3'"><xsl:value-of select=".//h3[1]"/></xsl:when>
      <xsl:when test="$main-head-level='h4'"><xsl:value-of select=".//h4[1]"/></xsl:when>
      <xsl:when test="$main-head-level='h5'"><xsl:value-of select=".//h5[1]"/></xsl:when>
      <xsl:when test="$main-head-level='h6'"><xsl:value-of select=".//h6[1]"/></xsl:when>
    </xsl:choose>
  </title>
</xsl:template>

<xsl:template name="gentitlealts">
  <xsl:variable name="create-searchtitle">
    <xsl:choose>
      <xsl:when test="not(/html/head/title)">NO</xsl:when>
      <xsl:when test="$main-head-level='h1' and normalize-space(string(//h1[1]))=normalize-space(string(/html/head/title))">NO</xsl:when>
      <xsl:when test="$main-head-level='h2' and normalize-space(string(//h2[1]))=normalize-space(string(/html/head/title))">NO</xsl:when>
      <xsl:when test="$main-head-level='h3' and normalize-space(string(//h3[1]))=normalize-space(string(/html/head/title))">NO</xsl:when>
      <xsl:when test="$main-head-level='h4' and normalize-space(string(//h4[1]))=normalize-space(string(/html/head/title))">NO</xsl:when>
      <xsl:when test="$main-head-level='h5' and normalize-space(string(//h5[1]))=normalize-space(string(/html/head/title))">NO</xsl:when>
      <xsl:when test="$main-head-level='h6' and normalize-space(string(//h6[1]))=normalize-space(string(/html/head/title))">NO</xsl:when>
      <xsl:otherwise>YES</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:if test="$create-searchtitle='YES'">
    <titlealts>
      <searchtitle>
        <xsl:value-of select="/html/head/title"/>
      </searchtitle>
    </titlealts>
  </xsl:if>
</xsl:template>


<!-- ========== End of overrideable heading level code =============== -->



<!-- null out some things pulled later -->
<xsl:template match="head"/>
<xsl:template match="title"/>

<!-- body: fall through, since its contexts (refbody, conbody, etc.) will be
     generated by templates above -->

<xsl:template match="body">
  <xsl:apply-templates/>
</xsl:template>


<!-- map these common elements straight through -->
<xsl:template match="p[@class='note']|p[@class='tip']|p[@class='caution']|p[@class='warning']|p[@class='listnote']">
  <xsl:element name="note">
    <xsl:choose>
      <xsl:when test="@class='warning'">
        <xsl:attribute name="type">danger</xsl:attribute>
      </xsl:when>
      <xsl:when test="@class='listnote'">
        <xsl:attribute name="type">note</xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="type"><xsl:value-of select="@class"/></xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="*|text()|comment()"/>
  </xsl:element>
</xsl:template>

<xsl:template match="cite|p|dl|ol|ul|li|pre|sub|sup">
  <xsl:variable name="giname"><xsl:value-of select="name()"/></xsl:variable>
  <xsl:variable name="outgi"><xsl:value-of select="translate($giname,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')"/></xsl:variable>

<xsl:element name="{$outgi}">
  <xsl:if test="@compact and (self::ol|self::ul|self::dl)">
      <xsl:attribute name="compact">yes</xsl:attribute>
  </xsl:if>
  <xsl:apply-templates select="@class"/>
  <xsl:apply-templates select="*|text()|comment()"/>
</xsl:element>

</xsl:template>
<!-- @outputclass is not allowed on these in DITA, so do not process @class -->
<xsl:template match="b|u|i">
<xsl:variable name="giname"><xsl:value-of select="name()"/></xsl:variable>
<xsl:variable name="outgi"><xsl:value-of select="translate($giname,'BITU','bitu')"/></xsl:variable>
<xsl:element name="{$outgi}">
  <xsl:apply-templates select="*|text()|comment()"/>
</xsl:element>
</xsl:template>

<xsl:template match="@class">
  <xsl:attribute name="outputclass"><xsl:value-of select="."/></xsl:attribute>
</xsl:template>

<!-- empty elements  -->

<!-- This template will return true() if there is nothing left in this topic except
     a series of related links. Those links will be gathered in the <related-links> section.
     If this is in the related links, return true(). Otherwise, return false(). 
     The tests are:
     If not a child of body, return false (keep this in output)
     If there are text nodes following, return false
     If there are no nodes following, return true (part of the links, so drop it)
     If there are following elements OTHER than br or a, return false
     Otherwise, this is a br or a at the end -->
<!-- AN: removed     
<xsl:template name="only-related-links-remain">
  <xsl:choose>
    <xsl:when test="not(parent::body)">false</xsl:when>
    <xsl:when test="following-sibling::text()">false</xsl:when>
    <xsl:when test="not(following-sibling::*)">true</xsl:when>
    <xsl:when test="following-sibling::*[not(self::br or self::a)]">false</xsl:when>
    <xsl:otherwise>true</xsl:otherwise>
  </xsl:choose>
</xsl:template>
-->

<xsl:template match="br">
  <xsl:variable name="skip-related-links">
    <!-- AN: removed
    <xsl:call-template name="only-related-links-remain"/>
    -->
    false
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="$skip-related-links='true'"/>
    <xsl:when test="following-sibling::*[1][self::img]/following-sibling::*[1][self::br]"/>
    <xsl:when test="preceding-sibling::*[1][self::img]/preceding-sibling::*[1][self::br]"/>
    <xsl:when test="following-sibling::text()|following-sibling::*[not(self::a)]">
      <xsl:call-template name="output-message">
        <xsl:with-param name="msg">CLEANUP ACTION: Determine the original intent for a BR tag.</xsl:with-param>
      </xsl:call-template>
      <!-- <xsl:comment>A BR tag was used here in the original source.</xsl:comment> -->      
      <xsl:text> 
      </xsl:text>
    </xsl:when>
    <xsl:otherwise/> <!-- Skip br if it ends a section, or only has links following -->
  </xsl:choose>
</xsl:template>

<!-- 
<xsl:template match="meta[@name='keywords']">
  <keywords>
    <indexterm><xsl:value-of select='@content'/></indexterm>
  </keywords>
</xsl:template>
-->

  <xsl:template match="meta[@name='keywords' or @name='Keywords']">
    <xsl:if test="normalize-space(@content)!=''">
      <keywords>
        <xsl:call-template name="mainterm">
          <xsl:with-param name="terms" select="@content" />
        </xsl:call-template>
      </keywords>
    </xsl:if>
  </xsl:template>

  <xsl:template name="mainterm">
    <xsl:param name="terms"/>
    <xsl:choose>
      <xsl:when test="contains($terms,', ')">
        <!-- process first indexterm -->
        <xsl:call-template name="subterm">
          <xsl:with-param name="terms" select="substring-before($terms,', ')" />
        </xsl:call-template>
        <!-- call myself with rest of indexterms -->
        <xsl:call-template name="mainterm">
          <xsl:with-param name="terms" select="substring-after($terms,', ')" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <!-- process last indexterm -->
        <xsl:call-template name="subterm">
          <xsl:with-param name="terms" select="$terms" />
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="subterm">
    <xsl:param name="terms"/>
    <xsl:choose>
      <xsl:when test="contains($terms,'&#09;')">
        <!-- process first subterm -->
        <indexterm>
          <xsl:value-of select="substring-before($terms,'&#09;')" />
          <!-- call myself with rest of subterms -->
          <xsl:call-template name="mainterm">
            <xsl:with-param name="terms" select="substring-after($terms,'&#09;')" />
          </xsl:call-template>
        </indexterm>
      </xsl:when>
      <xsl:otherwise>
        <!-- process last subterm -->
        <indexterm>
          <xsl:value-of select="$terms"/>
        </indexterm>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template >
 
<xsl:template match="meta[@name]" mode="outofline">
  <othermeta name="{@name}" content="{@content}"/>
</xsl:template>

<xsl:template match="img[@usemap][@src]">
  <xsl:variable name="mapid"><xsl:value-of select="substring-after(@usemap,'#')"/></xsl:variable>
  <imagemap>
    <image href="{@src}">
      <xsl:apply-templates select="@alt"/>
      </image>
    <xsl:apply-templates select="//map[@id=$mapid or @name=$mapid]" mode="usemap"/>
  </imagemap>
</xsl:template>

<xsl:template match="map"/>
<xsl:template match="map" mode="usemap">
  <xsl:apply-templates/>
</xsl:template>
<xsl:template match="area">
  <area>
      <shape><xsl:value-of select="@shape"/></shape>
      <coords><xsl:value-of select="@coords"/></coords>
      <xref>
          <xsl:call-template name="genlinkattrs"/>
          <xsl:value-of select="@alt"/>
      </xref>
  </area>
</xsl:template>

<xsl:template match="img">
      <image href="{@src}">
        <xsl:choose>
          <xsl:when test="../@class='image' or ../@class='listimage'"><xsl:attribute name="placement">break</xsl:attribute></xsl:when>
          <xsl:when test="preceding-sibling::*[1][self::br]|following-sibling::*[1][self::br]">
            <xsl:attribute name="placement">break</xsl:attribute>
          </xsl:when>
        </xsl:choose>
        <xsl:apply-templates select="@alt"/>
      </image>
</xsl:template>

<xsl:template match="img/@alt">
  <alt><xsl:value-of select="."/></alt>
</xsl:template>

<!-- AN: combine image and caption paras into fig  -->
<xsl:template match="p[@class='image']">
  <xsl:choose>
    <xsl:when test="following-sibling::p[1][@class='caption']">
      <fig>
        <title><xsl:value-of select="following-sibling::p[1][@class='caption']"/></title>
        <xsl:apply-templates select="./img"/>
      </fig>
    </xsl:when>
    <!-- skip if already handled below -->
    <xsl:when test="preceding-sibling::p[1][@class='caption']"/>
    <xsl:otherwise>
      <xsl:apply-templates select="./*"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="p[@class='caption']">
  <xsl:choose>
    <xsl:when test="following-sibling::p[1][@class='image']">
      <fig>
        <title><xsl:value-of select="."/></title>
        <xsl:apply-templates select="following-sibling::p[1][@class='image']/img"/>
      </fig>
    </xsl:when>
    <!-- skip if already handled above -->
    <xsl:when test="preceding-sibling::p[1][@class='image']"/>
    <xsl:otherwise>
      <p outputclass='caption'><xsl:value-of select="."/></p>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template match="hr">
<xsl:comment> ===================== horizontal rule ===================== </xsl:comment>
</xsl:template>


<!-- renames -->

<xsl:template match="code">
  <codeph><xsl:apply-templates select="*|text()|comment()"/></codeph>
</xsl:template>

<xsl:template match="var">
  <varname><xsl:apply-templates select="*|text()|comment()"/></varname>
</xsl:template>

<xsl:template match="samp">
  <systemoutput><xsl:apply-templates select="*|text()|comment()"/></systemoutput>
</xsl:template>

<xsl:template match="kbd">
  <userinput><xsl:apply-templates select="*|text()|comment()"/></userinput>
</xsl:template>


<xsl:template match="em">
  <i><xsl:apply-templates select="*|text()|comment()"/></i>
</xsl:template>

<xsl:template match="strong[@class='buttons']">
  <!-- 2005/07/11 AN Reverse nesting of xref and uicontrol -->
  <xsl:call-template name="uicontrol"/>
</xsl:template>

<xsl:template match="strong[@class='menuoptions']">
  <!-- 2005/07/11 AN Reverse nesting of xref and uicontrol -->
  <xsl:call-template name="uicontrol"/>
</xsl:template>

<xsl:template match="strong">
  <b><xsl:apply-templates select="*|text()|comment()"/></b>
</xsl:template>

<xsl:template match="blockquote">
  <lq><xsl:apply-templates select="*|text()|comment()"/></lq>
</xsl:template>

<!-- <lq> in <lq> is invalid in DITA, so make it valid (though it is a bit strange) -->
<xsl:template match="blockquote/blockquote">
  <p><lq><xsl:apply-templates select="*|text()|comment()"/></lq></p>
</xsl:template>

<xsl:template match="pre" priority="3">
  <codeblock><xsl:apply-templates select="*|text()|comment()"/></codeblock>
</xsl:template>

<!-- assume that these elements are used in tech docs with a semantic intent... -->
<xsl:template match="tt">
  <codeph><xsl:apply-templates select="*|text()|comment()"/></codeph>
</xsl:template>

<xsl:template match="i" priority="3">
  <varname><xsl:apply-templates select="*|text()|comment()"/></varname>
</xsl:template>

<xsl:template match="p[@class='instruction']">
    <p><b><xsl:apply-templates select="*|text()|comment()"/></b></p>
</xsl:template>


<!-- Linking -->

<!-- May try to eliminate groups of related links at the end; if there is a <br>
     followed only by links, ignore them, and let the Collected Links get them.
     Doesn't work now: if a title is entirely a link, it's the last link, so it's ignored... -->
<xsl:template match="a">
  <xsl:choose>
    <xsl:when test="@href and parent::body">
      <p><xref>
        <xsl:call-template name="genlinkattrs"/>
        <xsl:apply-templates select="*|text()|comment()"/>
      </xref></p>
    </xsl:when>
    <!-- 
      <xsl:when test="@href">
        <xref>
          <xsl:call-template name="genlinkattrs"/>
          <xsl:apply-templates select="*|text()|comment()"/>
        </xref>
      </xsl:when>
    -->
    <!-- 2005/07/11 AN Reverse nesting of xref and uicontrol -->
    <xsl:when test="@href">
      <xref>
        <xsl:call-template name="genlinkattrs"/>
        <xsl:choose>
          <xsl:when test="parent::strong[@class='buttons'] or parent::strong[@class='menuoptions']"><uicontrol><xsl:apply-templates select="*|text()|comment()"/></uicontrol></xsl:when>
          <!-- 2006/03/28 AN Fix glossaryterm to work with xref -->
          <xsl:when test="parent::strong[@class='glossaryterm']"><term><xsl:apply-templates select="*|text()|comment()"/></term></xsl:when>
          <xsl:otherwise><xsl:apply-templates select="*|text()|comment()"/></xsl:otherwise>
        </xsl:choose>
      </xref>
    </xsl:when>
    <xsl:when test="parent::body and text()">
      <p><xsl:apply-templates select="*|text()|comment()"/></p>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates select="*|text()|comment()"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- HTML table to CALS table -->

<xsl:template match="td|th" mode="count-cols">
  <xsl:param name="current-count">1</xsl:param>
  <xsl:variable name="current-span">
    <xsl:choose>
      <xsl:when test="@colspan"><xsl:value-of select="@colspan"/></xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="following-sibling::th or following-sibling::td">
      <xsl:apply-templates select="(following-sibling::th|following-sibling::td)[1]" mode="count-cols">
        <xsl:with-param name="current-count"><xsl:value-of select="number($current-span) + number($current-count)"/></xsl:with-param>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:when test="@colspan">
      <xsl:value-of select="number($current-span) + number($current-count) - 1"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$current-count"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>
      

<xsl:template match="table">

<!--
<debug>Plain Table</debug>
<node><xsl:value-of select="name(.)"/></node>
<value><xsl:value-of select="*[1]"/></value>
-->

<xsl:choose>
  <!-- AN: remove AuthorIT related groups tables -->
  <xsl:when test=".//img/@alt='Next Topic'" >
  </xsl:when>
  <xsl:when test=".//img/@alt='Previous Topic'" >
  </xsl:when>
  <xsl:when test=".//img/@alt='Book Index'" >
  </xsl:when>
  <xsl:when test=".//img/@alt='Book Contents'" >
  </xsl:when>
  <xsl:when test=".//p/@class='relatedheading'" >
  </xsl:when>
  <xsl:when test=".//p/@class='relateditem'" >
  </xsl:when>
  
  <xsl:otherwise>

<xsl:variable name="cols-in-first-row">
  <xsl:choose>
    <xsl:when test="tbody/tr">
      <xsl:apply-templates select="(tbody[1]/tr[1]/td[1]|tbody[1]/tr[1]/th[1])[1]" mode="count-cols"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates select="(tr[1]/td[1]|tr[1]/th[1])[1]" mode="count-cols"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>
<xsl:variable name="width">
    <xsl:if test="@width"><xsl:value-of select="substring-before(@width,'%')"/></xsl:if>
</xsl:variable>
<xsl:if test="@summary">
    <xsl:comment><xsl:value-of select="@summary"/></xsl:comment>
    <xsl:call-template name="output-message">
        <xsl:with-param name="msg">The summary attribute on tables cannot be converted to DITA.
The attribute's contents were placed in a comment before the table.</xsl:with-param>
    </xsl:call-template>
</xsl:if>
<table>
    <xsl:if test="@align"><xsl:attribute name="align"><xsl:value-of select="@align"/></xsl:attribute></xsl:if>
  <!-- 2008/09/04 AN Change table expanse attribute to pgwide (conform with OASIS DITA) -->
  <!-- <xsl:choose>
        <xsl:when test="number($width) &lt; 100"><xsl:attribute name="expanse">column</xsl:attribute></xsl:when>
        <xsl:when test="$width"><xsl:attribute name="expanse">page</xsl:attribute></xsl:when>
    </xsl:choose>-->
  <xsl:choose>
    <xsl:when test="number($width) &lt; 100"><xsl:attribute name="pgwide">0</xsl:attribute></xsl:when>
    <xsl:when test="$width"><xsl:attribute name="pgwide">1</xsl:attribute></xsl:when>
  </xsl:choose>

  <xsl:choose>
        <xsl:when test="@rules='none' and @border='0'">
            <xsl:attribute name="frame">none</xsl:attribute>
            <xsl:attribute name="rowsep">0</xsl:attribute>
            <xsl:attribute name="colsep">0</xsl:attribute>
        </xsl:when>
        <xsl:when test="@border='0'">
            <xsl:attribute name="rowsep">0</xsl:attribute>
            <xsl:attribute name="colsep">0</xsl:attribute>
        </xsl:when>
        <xsl:when test="@rules='cols'">
            <xsl:attribute name="rowsep">0</xsl:attribute>
        </xsl:when>
        <xsl:when test="@rules='rows'">
            <xsl:attribute name="colsep">0</xsl:attribute>
        </xsl:when>
    </xsl:choose>

  <xsl:apply-templates select="caption"/>
<tgroup>
<!-- add colspan data here -->
<xsl:attribute name="cols"><xsl:value-of select="$cols-in-first-row"/></xsl:attribute>
<xsl:call-template name="create-colspec">
  <xsl:with-param name="total-cols"><xsl:value-of select="$cols-in-first-row"/></xsl:with-param>
</xsl:call-template>
<xsl:choose>
  <xsl:when test="thead">
    <thead><xsl:apply-templates select="thead/tr"/></thead>
  </xsl:when>
  <xsl:when test="tr[th and not(td)]">
    <thead><xsl:apply-templates select="tr[th and not(td)]">
    <!--ideally, do for-each only for rows that contain TH, and place within THEAD;
        then open up the TBODY for the rest of the rows -->
    <!-- unforch, all the data will go into one place for now -->
    </xsl:apply-templates></thead>
  </xsl:when>
</xsl:choose>
<tbody>
  <xsl:apply-templates select="tbody/tr[td]|tr[td]"/>
</tbody></tgroup></table>


    </xsl:otherwise>
</xsl:choose>

</xsl:template>

<xsl:template name="create-colspec">
  <xsl:param name="total-cols">0</xsl:param>
  <xsl:param name="on-column">1</xsl:param>
  <xsl:if test="$on-column &lt;= $total-cols">
    <colspec>
      <xsl:attribute name="colname">col<xsl:value-of select="$on-column"/></xsl:attribute>
      <xsl:if test="@align"><xsl:attribute name="align"><xsl:value-of select="@align"/></xsl:attribute></xsl:if>
    </colspec>
    <xsl:call-template name="create-colspec">
      <xsl:with-param name="total-cols"><xsl:value-of select="$total-cols"/></xsl:with-param>
      <xsl:with-param name="on-column"><xsl:value-of select="$on-column + 1"/></xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<xsl:template match="table/caption">
  <title><xsl:apply-templates select="*|text()|comment()"/></title>
</xsl:template>

<xsl:template match="tr">
  <xsl:choose>
    <xsl:when test="td/@height='0' and normalize-space(td/text())=''">
      <!-- ignore empty rows -->
    </xsl:when>
    <xsl:otherwise>
      <row>
        <xsl:if test="@valign"><xsl:attribute name="valign"><xsl:value-of select="@valign"/></xsl:attribute></xsl:if>
        <xsl:apply-templates/>
      </row>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>
  
<xsl:template match="td|th">
<entry>
  <xsl:if test="@rowspan">
    <xsl:attribute name="morerows"><xsl:value-of select="number(@rowspan)-1"/></xsl:attribute>
  </xsl:if>
  <xsl:if test="@colspan">  <!-- Allow entries to span columns -->
    <xsl:variable name="current-cell"><xsl:call-template name="current-cell-position"/></xsl:variable>
    <xsl:attribute name="namest">col<xsl:value-of select="$current-cell"/></xsl:attribute>
    <xsl:attribute name="nameend">col<xsl:value-of select="$current-cell + number(@colspan) - 1"/></xsl:attribute>
  </xsl:if>
  <xsl:choose>
      <xsl:when test="@align"><xsl:attribute name="align"><xsl:value-of select="@align"/></xsl:attribute></xsl:when>
      <xsl:when test="../@align"><xsl:attribute name="align"><xsl:value-of select="../@align"/></xsl:attribute></xsl:when>
  </xsl:choose>
  <xsl:apply-templates select="*|text()|comment()"/>
</entry>
</xsl:template>

<!-- Determine which column the current entry sits in. Count the current entry,
     plus every entry before it; take spanned rows and columns into account.
     If any entries in this table span rows, we must examine the entire table to
     be sure of the current column. Use mode="find-matrix-column".
     Otherwise, we just need to examine the current row. Use mode="count-cells". -->
<xsl:template name="current-cell-position">
  <xsl:choose>
    <xsl:when test="ancestor::table[1]//*[@rowspan][1]">
      <xsl:apply-templates select="(ancestor::table[1]/tbody/tr/*[1]|ancestor::table[1]/tr/*[1])[1]"
                           mode="find-matrix-column">
        <xsl:with-param name="stop-id"><xsl:value-of select="generate-id(.)"/></xsl:with-param>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:when test="not(preceding-sibling::td|preceding-sibling::th)">1</xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates select="(preceding-sibling::th|preceding-sibling::td)[1]" mode="count-cells"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Count the number of cells in the current row. Move backwards from the test cell. Add one
     for each entry, plus the number of spanned columns. -->
<xsl:template match="*" mode="count-cells">
  <xsl:param name="current-count">1</xsl:param>
  <xsl:variable name="new-count">
    <xsl:choose>
      <xsl:when test="@colspan"><xsl:value-of select="$current-count + number(@colspan)"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$current-count + 1"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="not(preceding-sibling::td|preceding-sibling::th)"><xsl:value-of select="$new-count"/></xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates select="(preceding-sibling::th|preceding-sibling::td)[1]" mode="count-cells">
        <xsl:with-param name="current-count"><xsl:value-of select="$new-count"/></xsl:with-param>
      </xsl:apply-templates>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Set up a pseudo-matrix to find the column of the current entry. Start with the first entry
     in the first row. Progress to the end of the row, then start the next row; go until we find
     the test cell (with id=$stop-id).
     If an entry spans rows, add the cells that will be covered to $matrix.
     If we get to an entry and its position is already filled in $matrix, then the entry is pushed
     to the side. Add one to the column count and re-try the entry. -->
<xsl:template match="*" mode="find-matrix-column">
  <xsl:param name="stop-id"/>
  <xsl:param name="matrix"/>
  <xsl:param name="row-count">1</xsl:param>
  <xsl:param name="col-count">1</xsl:param>
  <!-- $current-position has the format [1:3] for row 1, col 3. Use to test if this cell is covered. -->
  <xsl:variable name="current-position">[<xsl:value-of select="$row-count"/>:<xsl:value-of select="$col-count"/>]</xsl:variable>
  
  <xsl:choose>
    <!-- If the current value is already covered, increment the column number and try again. -->
    <xsl:when test="contains($matrix,$current-position)">
      <xsl:apply-templates select="." mode="find-matrix-column">
        <xsl:with-param name="stop-id"><xsl:value-of select="$stop-id"/></xsl:with-param>
        <xsl:with-param name="matrix"><xsl:value-of select="$matrix"/></xsl:with-param>
        <xsl:with-param name="row-count"><xsl:value-of select="$row-count"/></xsl:with-param>
        <xsl:with-param name="col-count"><xsl:value-of select="$col-count + 1"/></xsl:with-param>
      </xsl:apply-templates>
    </xsl:when>
    <!-- If this is the cell we are testing, return the current column number. -->
    <xsl:when test="generate-id(.)=$stop-id">
      <xsl:value-of select="$col-count"/>
    </xsl:when>
    <xsl:otherwise>
      <!-- Figure out what the next column value will be. -->
      <xsl:variable name="next-col-count">
        <xsl:choose>
          <xsl:when test="not(following-sibling::*)">1</xsl:when>
          <xsl:when test="@colspan"><xsl:value-of select="$col-count + number(@colspan) - 1"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="$col-count + 1"/></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <!-- Determine any values that need to be added to the matrix, if this entry spans rows. -->
      <xsl:variable name="new-matrix-values">
        <xsl:if test="@rowspan">
          <xsl:call-template name="add-to-matrix">
            <xsl:with-param name="start-row"><xsl:value-of select="number($row-count)"/></xsl:with-param>
            <xsl:with-param name="end-row"><xsl:value-of select="number($row-count) + number(@rowspan) - 1"/></xsl:with-param>
            <xsl:with-param name="start-col"><xsl:value-of select="number($col-count)"/></xsl:with-param>
            <xsl:with-param name="end-col">
              <xsl:choose>
                <xsl:when test="@colspan"><xsl:value-of select="number($col-count) + number(@colspan) - 1"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="number($col-count)"/></xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:variable>
      <xsl:choose>
        <!-- If there are more entries in this row, move to the next one. -->
        <xsl:when test="following-sibling::*">
          <xsl:apply-templates select="following-sibling::*[1]" mode="find-matrix-column">
            <xsl:with-param name="stop-id"><xsl:value-of select="$stop-id"/></xsl:with-param>
            <xsl:with-param name="matrix"><xsl:value-of select="$matrix"/><xsl:value-of select="$new-matrix-values"/></xsl:with-param>
            <xsl:with-param name="row-count"><xsl:value-of select="$row-count"/></xsl:with-param>
            <xsl:with-param name="col-count"><xsl:value-of select="$next-col-count"/></xsl:with-param>
          </xsl:apply-templates>
        </xsl:when>
        <!-- Otherwise, move to the first entry in the next row. -->
        <xsl:otherwise>
          <xsl:apply-templates select="../following-sibling::tr[1]/*[1]" mode="find-matrix-column">
            <xsl:with-param name="stop-id"><xsl:value-of select="$stop-id"/></xsl:with-param>
            <xsl:with-param name="matrix"><xsl:value-of select="$matrix"/><xsl:value-of select="$new-matrix-values"/></xsl:with-param>
            <xsl:with-param name="row-count"><xsl:value-of select="$row-count + 1"/></xsl:with-param>
            <xsl:with-param name="col-count"><xsl:value-of select="1"/></xsl:with-param>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- This template returns values that must be added to the table matrix. Every cell in the box determined
     by start-row, end-row, start-col, and end-col will be added. First add every value from the first
     column. When past $end-row, move to the next column. When past $end-col, every value is added. -->
<xsl:template name="add-to-matrix">
  <xsl:param name="start-row"/>       
  <xsl:param name="end-row"/>
  <xsl:param name="current-row"><xsl:value-of select="$start-row"/></xsl:param>
  <xsl:param name="start-col"/>
  <xsl:param name="end-col"/>
  <xsl:param name="current-col"><xsl:value-of select="$start-col"/></xsl:param>
  <xsl:choose>
    <xsl:when test="$current-col > $end-col"/>   <!-- Out of the box; every value has been added -->
    <xsl:when test="$current-row > $end-row">    <!-- Finished with this column; move to next -->
      <xsl:call-template name="add-to-matrix">
        <xsl:with-param name="start-row"><xsl:value-of select="$start-row"/></xsl:with-param>
        <xsl:with-param name="end-row"><xsl:value-of select="$end-row"/></xsl:with-param>
        <xsl:with-param name="current-row"><xsl:value-of select="$start-row"/></xsl:with-param>
        <xsl:with-param name="start-col"><xsl:value-of select="$start-col"/></xsl:with-param>
        <xsl:with-param name="end-col"><xsl:value-of select="$end-col"/></xsl:with-param>
        <xsl:with-param name="current-col"><xsl:value-of select="$current-col + 1"/></xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <!-- Output the value for the current entry -->
      <xsl:text>[</xsl:text>
      <xsl:value-of select="$current-row"/>:<xsl:value-of select="$current-col"/>
      <xsl:text>]</xsl:text>
      <!-- Move to the next row, in the same column. -->
      <xsl:call-template name="add-to-matrix">
        <xsl:with-param name="start-row"><xsl:value-of select="$start-row"/></xsl:with-param>
        <xsl:with-param name="end-row"><xsl:value-of select="$end-row"/></xsl:with-param>
        <xsl:with-param name="current-row"><xsl:value-of select="$current-row + 1"/></xsl:with-param>
        <xsl:with-param name="start-col"><xsl:value-of select="$start-col"/></xsl:with-param>
        <xsl:with-param name="end-col"><xsl:value-of select="$end-col"/></xsl:with-param>
        <xsl:with-param name="current-col"><xsl:value-of select="$current-col"/></xsl:with-param>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="tbody|tfoot|thead">
  <xsl:apply-templates/>
</xsl:template>

<!-- If a table entry contains a paragraph, and nothing but a paragraph, do not
     create the <p> tag in the <entry>. Let everything fall through into <entry>. -->
<xsl:template match="td/p|th/p">
  <xsl:choose>
    <xsl:when test="following-sibling::*|preceding-sibling::*">
      <p><xsl:apply-templates select="*|text()|comment()"/></p>
    </xsl:when>
    <xsl:when test="normalize-space(following-sibling::text()|preceding-sibling::text())=''">
      <xsl:apply-templates select="*|text()|comment()"/>
    </xsl:when>
    <xsl:otherwise>
      <p><xsl:apply-templates select="*|text()|comment()"/></p>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="span[@class='bold']">
  <b>
    <xsl:apply-templates select="*|text()|comment()"/>
  </b>
</xsl:template>

<xsl:template match="span[@class='italic']">
  <i>
    <xsl:apply-templates select="*|text()|comment()"/>
  </i>
</xsl:template>

<xsl:template match="span[@class='bold-italic']">
  <b><i>
    <xsl:apply-templates select="*|text()|comment()"/>
  </i></b>
</xsl:template>

<xsl:template match="strong[@class='glossaryterm']">
  <!-- 
  <term>
    <xsl:apply-templates select="*|text()|comment()"/>
  </term>
  -->
  <!-- 2006/03/28 AN Fix glossaryterm to work with xref -->
  <xsl:choose>
    <xsl:when test="./a">
      <xsl:apply-templates select="*|text()|comment()"/>
    </xsl:when>
    <xsl:otherwise>
      <term>
        <xsl:apply-templates select="*|text()|comment()"/>
      </term>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="span[@class='uicontrol']">
  <!-- 2005/07/11 AN Reverse nesting of xref and uicontrol -->
  <!-- 
  <uicontrol>
    <xsl:apply-templates select="*|text()|comment()"/>
  </uicontrol>
  -->
  <xsl:call-template name="uicontrol"/>  
</xsl:template>

<xsl:template name="uicontrol">
  <xsl:choose>
    <xsl:when test="./a">
      <xsl:apply-templates select="*|text()|comment()"/>
    </xsl:when>
    <xsl:otherwise>
      <uicontrol>
        <xsl:apply-templates select="*|text()|comment()"/>
      </uicontrol>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- 
AN 01/May-06 code to remove stylename, but output content

Remove any styles starting with 'remove'
<xsl:template match="span[starts-with(@class, 'remove')]">
  <xsl:apply-templates select="*|text()|comment()"/>
</xsl:template>

Remove any styles ending with 'remove'
<xsl:template match="span[string-length(substring-before(@class,'remove')) > 0]">
  <xsl:apply-templates select="*|text()|comment()"/>
</xsl:template>
-->

  <xsl:template match="span[string-length(substring-before(@class,'remove')) > 0]">
    <xsl:apply-templates select="*|text()|comment()"/>
  </xsl:template>
  
<!-- strip notelabel spans -->
<xsl:template match="span[@class='notelabel']">
  <xsl:choose>
    <xsl:when test="position() != 1 or normalize-space(preceding-sibling::text())!=''">
      <xsl:apply-templates select="*|text()|comment()"/>
    </xsl:when>
    <xsl:otherwise>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- case of span with no attributes at all -->

<xsl:template match="span[not(string(@*))]">
  <ph>
    <xsl:apply-templates select="*|text()|comment()"/>
  </ph>
</xsl:template>

<!-- Search for span styles that Tidy moved into /html/head/style
     Each known value adds something to the return value, such as [b] for bold.
     The returned value is parsed to determine which wrappers to create.
     New values can be added here; processing for the new value will need
     to be merged into the sequential b/i/u/tt processing below. -->
<xsl:template name="get-span-style">
  <xsl:variable name="classval"><xsl:value-of select="@class"/></xsl:variable>
  <xsl:variable name="searchval">span.<xsl:value-of select="$classval"/></xsl:variable>
  <xsl:variable name="span-style">
    <xsl:value-of select="substring-before(substring-after(/html/head/style/text(),$searchval),'}')"/>}<xsl:text/>
  </xsl:variable>
  <xsl:if test="contains($span-style,'font-weight:bold') or contains($span-style,'font-weight :bold') or
                contains($span-style,'font-weight: bold') or 
                contains($span-style,'font-weight : bold')">[b]</xsl:if>
  <xsl:if test="contains($span-style,'font-style:italic') or contains($span-style,'font-style :italic') or
                contains($span-style,'font-style: italic') or 
                contains($span-style,'font-style : italic')">[i]</xsl:if>
  <xsl:if test="contains($span-style,'text-decoration: underline') or contains($span-style,'text-decoration :underline') or
                contains($span-style,'text-decoration: underline') or 
                contains($span-style,'text-decoration : underline')">[u]</xsl:if>
  <xsl:if test="contains($span-style,'font-family:Courier') or contains($span-style,'font-family :Courier') or
                contains($span-style,'font-family: Courier') or 
                contains($span-style,'font-family : Courier')">[tt]</xsl:if>
  <xsl:if test="contains($span-style,'font-weight:normal') or contains($span-style,'font-weight :normal') or
                contains($span-style,'font-weight: normal') or 
                contains($span-style,'font-weight : normal')">[normal]</xsl:if>
</xsl:template>

<!-- Process a span with a tidy-created class. It is known to have one or more
     values from b, i, u, or tt. For each value, create the element if needed,
     and move on to the next one, passing the style value from /html/head/style -->
<xsl:template name="bold-span">
  <xsl:param name="span-style"/>
  <xsl:choose>
    <xsl:when test="contains($span-style,'[b]')">
      <b><xsl:call-template name="italic-span"><xsl:with-param name="span-style" select="$span-style"/></xsl:call-template></b>
    </xsl:when>
    <xsl:otherwise><xsl:call-template name="italic-span"><xsl:with-param name="span-style" select="$span-style"/></xsl:call-template></xsl:otherwise>
  </xsl:choose>
</xsl:template>
<xsl:template name="italic-span">
  <xsl:param name="span-style"/>
  <xsl:choose>
    <xsl:when test="contains($span-style,'[i]')">
      <i><xsl:call-template name="underline-span"><xsl:with-param name="span-style" select="$span-style"/></xsl:call-template></i>
    </xsl:when>
    <xsl:otherwise><xsl:call-template name="underline-span"><xsl:with-param name="span-style" select="$span-style"/></xsl:call-template></xsl:otherwise>
  </xsl:choose>
</xsl:template>
<xsl:template name="underline-span">
  <xsl:param name="span-style"/>
  <xsl:choose>
    <xsl:when test="contains($span-style,'[u]')">
      <u><xsl:call-template name="courier-span"><xsl:with-param name="span-style" select="$span-style"/></xsl:call-template></u>
    </xsl:when>
    <xsl:otherwise><xsl:call-template name="courier-span"><xsl:with-param name="span-style" select="$span-style"/></xsl:call-template></xsl:otherwise>
  </xsl:choose>
</xsl:template>
<xsl:template name="courier-span">
  <xsl:param name="span-style"/>
  <xsl:choose>
    <xsl:when test="contains($span-style,'[tt]')">
      <tt><xsl:call-template name="normal-span"><xsl:with-param name="span-style" select="$span-style"/></xsl:call-template></tt>
    </xsl:when>
    <xsl:otherwise><xsl:call-template name="normal-span"><xsl:with-param name="span-style" select="$span-style"/></xsl:call-template></xsl:otherwise>
  </xsl:choose>
</xsl:template>
<xsl:template name="normal-span">
  <xsl:param name="span-style"/>
  <xsl:choose>
    <!-- If a span has "normal" style and nothing else, create <ph> -->
    <xsl:when test="contains($span-style,'[normal]') and 
                    substring-before($span-style,'[normal]')='' and
                    substring-after($span-style,'[normal]')=''">
      <ph><xsl:apply-templates select="*|text()|comment()"/></ph>
    </xsl:when>
    <xsl:otherwise><xsl:apply-templates select="*|text()|comment()"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="span">
  <xsl:choose>
    <xsl:when test="@class='bold-italic'">
      <b><i><xsl:apply-templates select="*|text()|comment()"/></i></b>
    </xsl:when>
    <!-- If the span has a value created by tidy, parse /html/head/style -->
    <xsl:when test="@class='c1' or @class='c2' or @class='c3' or
                    @class='c4' or @class='c5' or @class='c6' or
                    @class='c7' or @class='c8' or @class='c9'">
      <xsl:variable name="span-style"><xsl:call-template name="get-span-style"/></xsl:variable>
      <xsl:choose>
        <xsl:when test="string-length($span-style)>0">
          <xsl:call-template name="bold-span"><xsl:with-param name="span-style" select="$span-style"/></xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="searchval">span.<xsl:value-of select="@class"/></xsl:variable>
          <xsl:variable name="orig-span-style">
            <xsl:value-of select="substring-before(substring-after(/html/head/style/text(),$searchval),'}')"/>}<xsl:text/>
          </xsl:variable>
          <xsl:call-template name="output-message">
            <xsl:with-param name="msg">CLEANUP ACTION: provide a better phrase markup for a SPAN tag.
The element's contents have been placed in a phrase element.
There is a comment next to the phrase with the span's class value.</xsl:with-param>
          </xsl:call-template>
          <xsl:comment>Original: &lt;span @class=<xsl:value-of select="@class"/>&gt;, <xsl:value-of select="@class"/>=<xsl:value-of select="$orig-span-style"/></xsl:comment>
          <ph><xsl:apply-templates select="*|text()|comment()"/></ph>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="output-message">
        <xsl:with-param name="msg">CLEANUP ACTION: provide a better phrase markup for a SPAN tag.
The element's contents have been placed in a phrase element.
There is a comment next to the phrase with the span's class value.</xsl:with-param>
      </xsl:call-template>
      <xsl:comment>Original: &lt;span @class=<xsl:value-of select="@class"/>&gt;</xsl:comment>
      <ph><xsl:apply-templates select="*|text()|comment()"/></ph>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- generate dlentry wrapper for DL/DD/DT -->

<xsl:template match="dt">
<dlentry>
 <dt><xsl:apply-templates select="*|text()|comment()"/></dt>
 <xsl:apply-templates select="following-sibling::*[1]" mode="indirect"/>
</dlentry>
</xsl:template>

<xsl:template match="dd"/>

<xsl:template match="dt" mode="indirect"/>
<xsl:template match="dd" mode="indirect">
  <dd>
    <xsl:apply-templates select="*|text()|comment()"/>
  </dd>
  <xsl:apply-templates select="following-sibling::*[1]" mode="indirect"/>
</xsl:template>


<!-- named templates -->


<!-- things noted for disambiguation -->

<!-- encapsulate text within body -->
<xsl:template match="body/text()|body/div/text()">
  <xsl:variable name="bodytxt"><xsl:value-of select="normalize-space(.)"/></xsl:variable>
  <xsl:if test="string-length($bodytxt)>0">
    <!-- issue a message here? Not EVERY time, puleeeze. test for first node if we must... -->
    <p>
      <xsl:value-of select="."/>
    </p>
  </xsl:if>
  <!-- text nodes get wrapped; blanks fall through -->
</xsl:template>

<!-- encapsulate phrases within body -->
<xsl:template match="body/i|body/div/i" priority="4">
  <p><i><xsl:apply-templates select="*|text()|comment()"/></i></p>
</xsl:template>
<xsl:template match="body/b|body/div/b" priority="4">
  <p><b><xsl:apply-templates select="*|text()|comment()"/></b></p>
</xsl:template>
<xsl:template match="body/u|body/div/u" priority="4">
  <p><u><xsl:apply-templates select="*|text()|comment()"/></u></p>
</xsl:template>

<!-- =========== Change strong elements that are children to a elements to bold =========== -->

<xsl:template match="body/p/a/strong">
  <b>
    <xsl:attribute name="remapped"><xsl:value-of select="name()"/></xsl:attribute>
    <xsl:apply-templates select="*|text()|comment()"/>
  </b>
</xsl:template>

<!-- lowerCase function -->
<xsl:param name="upperCase">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:param>
<xsl:param name="lowerCase">abcdefghijklmnopqrstuvwxyz</xsl:param>
<xsl:template name="lowerCase">
  <xsl:param name="inputString"/>
  <xsl:value-of select="translate($inputString, $upperCase, $lowerCase)"/>
</xsl:template>

<!-- =========== Removing em italic elements =========== -->

<xsl:template match="node()/em[@class='italics']">
    <cite><xsl:apply-templates select="*|text()|comment()"/></cite>
</xsl:template>

<!-- =========== Mark alerts for updating =========== -->
<!-- Remove the alert spacers -->
<xsl:template match="node()/p[@class='alertspacerafter']">
</xsl:template>

<xsl:template match="node()/p[@class='alertspacerbefore']">
<xsl:comment>REQUIRED-CLEANUP-ALERT: Recreate the alert, conref it in, and then delete this alert.</xsl:comment>
</xsl:template>


<!-- case of deprecated elements with no clear migrational intent -->

<xsl:template match="small|big">
  <xsl:call-template name="output-message">
      <xsl:with-param name="msg">CLEANUP ACTION: provide a better phrase markup for a BIG or SMALL tag.
The element's contents have been placed in a required-cleanup element.</xsl:with-param>
  </xsl:call-template>
  <required-cleanup>
    <xsl:attribute name="remap"><xsl:value-of select="name()"/></xsl:attribute>
    <ph>
      <xsl:apply-templates select="*|text()|comment()"/>
    </ph>
  </required-cleanup>
</xsl:template>


<xsl:template match="s|strike">
  <xsl:call-template name="output-message">
      <xsl:with-param name="msg">CLEANUP ACTION: provide a better phrase markup for a strikethrough tag.
The element's contents have been placed in a required-cleanup element.</xsl:with-param>
  </xsl:call-template>
  <required-cleanup>
    <xsl:attribute name="remap"><xsl:value-of select="name()"/></xsl:attribute>
    <ph>
      <xsl:apply-templates select="*|text()|comment()"/>
    </ph>
  </required-cleanup>
</xsl:template>

<!-- set of rules for faux-pre sections (paragraphs with br, using samp for font effect)-->

<xsl:template match="p[samp][not(text())]">
  <pre>
   <xsl:apply-templates mode="re-pre"/>
  </pre>
</xsl:template>

<xsl:template match="samp" mode="re-pre">
  <xsl:apply-templates mode="re-pre"/>
</xsl:template>

<xsl:template match="samp/br" mode="re-pre"/><!-- won't need introduced space if original source has it -->

<xsl:template match="comment()">
  <xsl:comment><xsl:value-of select="."/></xsl:comment>
</xsl:template>

<!-- =========== CATCH UNDEFINED ELEMENTS (for stylesheet maintainers) =========== -->

<!-- (this rule should NOT produce output in production setting) -->
<xsl:template match="*">
  <xsl:call-template name="output-message">
    <xsl:with-param name="msg">CLEANUP ACTION: no DITA equivalent for HTML element '<xsl:value-of select="name()"/>'.
The element has been placed in a required-cleanup element.</xsl:with-param>
  </xsl:call-template>
  <required-cleanup>
    <xsl:attribute name="remap"><xsl:value-of select="name()"/></xsl:attribute>
    <ph>
      <xsl:apply-templates select="*|text()|comment()"/>
    </ph>
  </required-cleanup>
</xsl:template>

</xsl:stylesheet>
