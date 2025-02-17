<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xlink="http://www.w3.org/1999/xlink">
	<!-- http://www.ncbi.nlm.nih.gov/books/NBK3828/ -->

	<!-- 
	<!DOCTYPE ArticleSet PUBLIC "-//NLM//DTD PubMed 2.4//EN" "http://www.ncbi.nlm.nih.gov/entrez/query/static/PubMed.dtd">

	-->
	<xsl:output 
		doctype-public="-//NLM//DTD PubMed 2.6//EN" 
		doctype-system="http://www.ncbi.nlm.nih.gov/entrez/query/static/PubMed.dtd" 
		encoding="UTF-8" method="xml" omit-xml-declaration="no" version="1.0"
		indent="yes" xml:space="default" 
	/>
	<xsl:variable name="pid_list" select="//pid-set//pid"/>
	
	<xsl:template match="/">
		<ArticleSet>
			<xsl:apply-templates select=".//article-set//article-item">
				<xsl:sort select="article//article-meta/pub-date[@pub-type='epub']/month" order="ascending" data-type="number"/>
				<xsl:sort select="article//article-meta/pub-date[@pub-type='epub']/day" order="ascending" data-type="number"/>
				<xsl:sort select="article//article-meta/fpage" order="ascending" data-type="number"/>
			</xsl:apply-templates>	
		</ArticleSet>
	</xsl:template>
	
	<xsl:template match="article-item">
		<xsl:variable name="f" select="@filename"/>
		<xsl:apply-templates select="article">
			<xsl:with-param name="pid" select="$pid_list[@filename=$f]"></xsl:with-param>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="article">
		<xsl:param name="pid"/>
		<Article>
			<Journal>
				<xsl:apply-templates select="." mode="scielo-xml-publisher_name"/>
				<xsl:apply-templates select="." mode="scielo-xml-journal_title"/>
				<xsl:apply-templates select="." mode="scielo-xml-issn"/>
				<xsl:apply-templates select="." mode="scielo-xml-volume_id"/>
				<xsl:apply-templates select="." mode="scielo-xml-issue_no"/>
				<xsl:apply-templates select="." mode="scielo-xml-publishing_dateiso"/>
			</Journal>
			<xsl:if test=".//article-meta/article-id[@specific-use='previous-pid']">
				<Replaces IdType="pii">
					<xsl:apply-templates select=".//article-meta/article-id[@specific-use='previous-pid']" mode="scielo-xml-pii"/>
				</Replaces>
			</xsl:if>
			<xsl:apply-templates select="." mode="scielo-xml-title"/>

			<xsl:apply-templates select=".//article-meta/fpage|.//article-meta/lpage"/>
			<ELocationID EIdType="pii">
				<xsl:value-of select="$pid"/>
			</ELocationID>
			<xsl:apply-templates
				select="@xml:lang|.//sub-article[@article-type='translation']/@xml:lang"
				mode="scielo-xml-languages"/>
			<!-- FIXED 20040504 
			Roberta Mayumi Takenaka
			Solicitado por Solange email: 20040429
			Para artigos que não tenham autores, não gerar a tag </AuthorList>.			
			-->
			<xsl:if test="count(.//front//contrib) + count(.//front//collab) &gt; 0">
				<AuthorList>
					<xsl:apply-templates select=".//front//contrib" mode="scielo-xml-author"/>
					<xsl:apply-templates select=".//front//collab" mode="scielo-xml-author"/>
				</AuthorList>
			</xsl:if>
			<PublicationType><xsl:apply-templates select="." mode="scielo-xml-publication-type"/></PublicationType>
			<ArticleIdList>
				<ArticleId IdType="pii">
					<xsl:choose>
						<xsl:when test=".//article-meta/article-id[@specific-use='previous-pid']">
							<xsl:apply-templates select=".//article-meta/article-id[@specific-use='previous-pid']" mode="scielo-xml-pii"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$pid"/>
						</xsl:otherwise>
					</xsl:choose>
				</ArticleId>
				<ArticleId IdType="doi">
					<xsl:value-of select=".//front//article-id[@pub-id-type='doi']"/>
				</ArticleId>
			</ArticleIdList>
			<xsl:if test=".//front//history">
				<History>
					<xsl:apply-templates select=".//front//history/*"/>
					<xsl:apply-templates select=".//front//pub-date[@pub-type='epub']"/>
				</History>
			</xsl:if>
			<xsl:apply-templates select="." mode="scielo-xml-abstract"/>
			<xsl:apply-templates select="." mode="scielo-xml-objects"/>
		</Article>
	</xsl:template>
	<xsl:template match="related-article[@related-article-type='corrected-article' or @related-article-type='retracted-article']" mode="scielo-xml-object">
		<xsl:param name="article_type"/>
		<Object>
			<xsl:attribute name="Type"><xsl:choose>
				<xsl:when test="$article_type='correction'">Erratum</xsl:when>
				<xsl:when test="$article_type='retraction'">Retraction</xsl:when>
			</xsl:choose></xsl:attribute>
			<Param Name="type"><xsl:choose>
				<xsl:when test="@ext-link-type='doi'"><xsl:value-of select="@ext-link-type"/></xsl:when>
				<xsl:otherwise>pii</xsl:otherwise>
			</xsl:choose></Param>
			<Param Name="id"><xsl:value-of select="@xlink:href"/></Param>
		</Object>
	</xsl:template>
	<xsl:template match="article" mode="scielo-xml-objects">
	</xsl:template>
	<xsl:template match="article[@article-type='correction' or @article-type='retraction']" mode="scielo-xml-objects">
		<ObjectList>
			<xsl:apply-templates select=".//related-article[@related-article-type='corrected-article' or @related-article-type='retracted-article']" mode="scielo-xml-object">
				<xsl:with-param name="article_type"><xsl:value-of select="@article-type"/></xsl:with-param>
			</xsl:apply-templates>
		</ObjectList>
	</xsl:template>
	<xsl:template match="article[@article-type='case-report']" mode="scielo-xml-publication-type">Case Reports</xsl:template>
	<xsl:template match="article[@article-type='research-article']" mode="scielo-xml-publication-type">Journal Article</xsl:template>
	<xsl:template match="article[@article-type='corrected-article']" mode="scielo-xml-publication-type">Corrected and Republished Article</xsl:template>
	<xsl:template match="article[@article-type='correction']" mode="scielo-xml-publication-type">Published Erratum</xsl:template>
	<xsl:template match="article[@article-type='editorial']" mode="scielo-xml-publication-type">Editorial</xsl:template>
	<xsl:template match="article[@article-type='letter']" mode="scielo-xml-publication-type">Letter</xsl:template>
	<xsl:template match="article[@article-type='retraction']" mode="scielo-xml-publication-type">Retraction of Publication</xsl:template>
	<xsl:template match="article[@article-type='article-review']" mode="scielo-xml-publication-type">Review</xsl:template>
	
	<xsl:template match="article" mode="scielo-xml-publication-type">
		<xsl:choose>
			<xsl:when test="./article-meta//ext-link[@ext-link-type='ClinicalTrial']">Clinical Trial</xsl:when>
		</xsl:choose>
	</xsl:template>
	<!-- 
		case-report 	relato, descrição ou estudo de caso - pesquisas especiais que despertam interesse informativo.
		correction 	errata - corrige erros apresentados em artigos após sua publicação online/impressa.
		editorial 	editorial - uma declaração de opiniões, crenças e políticas do editor do periódico, geralmente sobre assuntos de significado científico de interesse da comunidade científica ou da sociedade.
		letter 	cartas - comunicação entre pessoas ou instituições através de cartas. Geralmente comentando um trabalho publicado
		research-article 	artigo original - abrange pesquisas, experiências clínicas ou cirúrgicas ou outras contribuições originais.
		retraction 	retratação - a retratação de um artigo científico é um instrumento para corrigir o registro acadêmico publicado equivocadamente, por plágio, por exemplo.
		review-article 	são avaliações críticas sistematizadas da literatura sobre determinado assunto.
		
		article-commentary 	comentários - uma nota crítica ou esclarecedora, escrita para discutir, apoiar ou debater um artigo ou outra apresentação anteriormente publicada. Pode ser um artigo, carta, editorial, etc. Estas publicações podem aparecer como comentário, comentário editorial, ponto de vista, etc.
		book-review 	resenha - análise críticas de livros e outras monografias.
		brief-report 	comunicação breve sobre resultados de uma pesquisa.
		in-brief 	press release - comunicação breve de linguagem jornalística sobre um artigo ou tema.
		other 	Outro tipo de documento. Pode ser considerado adendo, anexo, discussão, artigo de preocupação, introdução entre outros.
		rapid-communication 	comunicação breve sobre atualização de investigação ou outra notícia.
		reply 	resposta a carta ou ao comentário, geralmente é usado pelo autor original fazendo outros comentários a respeito dos comentários anteriores
		translation 	tradução. Utilizado para artigos que apresentam tradução de um artigo produzid
		-->
	<!-- 
	Addresses
	Bibliography
	Clinical Conference
	Congresses
	Consensus Development Conference
	Consensus Development Conference, NIH
	Festschrift
	Guideline
	Interview	
	Journal Article
	Lectures
	Meta-Analysis
	News
	Newspaper Article
	Observational Study
	Patient Education Handout
	Practice Guideline	
	
	Review
	Video-Audio Media
	Webcasts
	-->
	<xsl:template match="*" mode="scielo-xml-title">
		<!-- http://www.ncbi.nlm.nih.gov/books/NBK3828/#publisherhelp.ArticleTitle_O -->
		<xsl:element name="ArticleTitle">
			<xsl:if test="@xml:lang='en'">
				<xsl:apply-templates select=".//article-meta//title-group/article-title"/>
			</xsl:if>
			<xsl:apply-templates select=".//article-meta//title-group/article-title[@xml:lang='en']"/>
			<xsl:apply-templates select=".//article-meta//title-group/trans-title-group[@xml:lang='en']/trans-title"/>
			<xsl:apply-templates select=".//sub-article//article-title[@xml:lang='en']"/></xsl:element>
			<xsl:if test="@xml:lang != 'en'">
				<!-- http://www.ncbi.nlm.nih.gov/books/NBK3828/#publisherhelp.VernacularTitle_O -->
				<xsl:element name="VernacularTitle">
					<xsl:apply-templates select=".//article-meta//title-group//article-title"/>
				</xsl:element>
		</xsl:if>
	</xsl:template>

	<xsl:template match="@xml:lang" mode="scielo-xml-languages">
		<Language>
			<xsl:value-of select="translate(.,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
		</Language>
	</xsl:template>
	
	
	<xsl:template match="*" mode="scielo-xml-abstract">
		<Abstract>
			<xsl:if test="@xml:lang='en'">
				<xsl:apply-templates select=".//abstract"
					mode="scielo-xml-content-abstract"/>
			</xsl:if>
			
			<xsl:apply-templates select=".//*[contains(name(),'abstract') and @xml:lang='en']"
				mode="scielo-xml-content-abstract"/>
			<xsl:apply-templates select=".//sub-article[@xml:lang='en' and @article-type='translation']//*[contains(name(),'abstract') and @xml:lang='en']"
				mode="scielo-xml-content-abstract"/>
		</Abstract>
	</xsl:template>
	<xsl:template match="related-article[@related-article-type='corrected-article']" mode="label">corrects</xsl:template>
	<xsl:template match="related-article[@related-article-type='retracted-article']" mode="label">retracts</xsl:template>
	<xsl:template match="*[@article-type='correction' or @article-type='retraction']" mode="scielo-xml-abstract">
		<Abstract><xsl:apply-templates select=".//related-article[@related-article-type='corrected-article' or @related-article-type='retracted-article']" mode="related-article-abstract"></xsl:apply-templates></Abstract>
	</xsl:template>
	<xsl:template match="related-article[@related-article-type='corrected-article' or @related-article-type='retracted-article']" mode="related-article-abstract">
		[This <xsl:apply-templates select="." mode="label"/> the article <xsl:value-of select="@ext-link-type"/>: <xsl:value-of select="@xlink:href"/>]
	</xsl:template>
	<xsl:template match="*" mode="scielo-xml-content-abstract">
		<xsl:apply-templates select="sec|text()"  mode="scielo-xml-content-abstract"/>
	</xsl:template>
	<xsl:template match="*/sec" mode="scielo-xml-content-abstract">
		<AbstractText>
			<xsl:attribute name="Label"><xsl:apply-templates select="title"/></xsl:attribute>
			<xsl:apply-templates select="p"/>
		</AbstractText>
	</xsl:template>
	<!-- 
		<Abstract>
<AbstractText Label="OBJECTIVE">To assess the effects...</AbstractText>
<AbstractText Label="METHODS">Patients attending lung...</AbstractText>
<AbstractText Label="RESULTS">Twenty-five patients...</AbstractText>
<AbstractText Label="CONCLUSIONS">The findings suggest...</AbstractText>
</Abstract>
		-->
	<xsl:template match="text()" mode="scielo-xml-content-abstract">
		<xsl:value-of select="."/>
	</xsl:template>
	<xsl:template match="*" mode="scielo-xml-content-abstract">
		<xsl:apply-templates select="*|text()" mode="scielo-xml-content-abstract"/>
	</xsl:template>
	<xsl:template match="*" mode="scielo-xml-publisher_name">
		<PublisherName>
			<xsl:value-of select=".//journal-meta//publisher-name"/>
		</PublisherName>
	</xsl:template>
	<xsl:template match="*" mode="scielo-xml-journal_title">
		<JournalTitle>
			<xsl:apply-templates select=".//journal-meta/journal-id[@journal-id-type='nlm-ta']"/>
		</JournalTitle>
	</xsl:template>
	<xsl:template match="*" mode="scielo-xml-issn">
		<Issn>
			<xsl:choose>
				<xsl:when test=".//journal-meta/issn[@pub-type='epub']">
					<xsl:value-of select=".//journal-meta/issn[@pub-type='epub']"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select=".//journal-meta/issn[@pub-type='ppub']"/>
				</xsl:otherwise>
			</xsl:choose>
		</Issn>
	</xsl:template>
	<xsl:template match="*" mode="scielo-xml-volume_id">
		<xsl:variable name="volume"><xsl:apply-templates select=".//front//volume"/>
		<xsl:if test="substring(.//front//issue,1,5)='Suppl'">
			<xsl:value-of select=".//front//issue"/>
		</xsl:if></xsl:variable>
		<xsl:if test="$volume!=''">
			<Volume><xsl:value-of select="$volume"/></Volume>
		</xsl:if>
	</xsl:template>
	<xsl:template match="*" mode="scielo-xml-issue_no">
			<xsl:if test=".//front//issue!='00' and .//front//issue!=''">
				<Issue><xsl:value-of select=".//front//issue"/></Issue>
			</xsl:if>
	</xsl:template>
	<xsl:template match="*" mode="scielo-xml-publishing_dateiso">
		<xsl:choose>
			<xsl:when test=".//front//pub-date[@date-type='collection']">
				<xsl:apply-templates select=".//front//pub-date[@date-type='collection']"/>
			</xsl:when>
			<xsl:when test=".//front//pub-date[@date-type='ppub']">
				<xsl:apply-templates select=".//front//pub-date[@date-type='ppub']"/>
			</xsl:when>
			<xsl:when test=".//front//pub-date[@date-type='epub-ppub']">
				<xsl:apply-templates select=".//front//pub-date[@date-type='epub-ppub']"/>
			</xsl:when>
			<xsl:when test=".//front//pub-date[@date-type='epub']">
				<xsl:apply-templates select=".//front//pub-date[@date-type='epub']"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select=".//front//pub-date[1]"/>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>
	<xsl:template match="pub-date/@pub-type | @date-type">
		<xsl:choose>
			<xsl:when test=".='epub'">aheadofprint</xsl:when>
			<xsl:when test=".='ppub'">ppublish</xsl:when>
			<xsl:when test=".='epub-ppub'">ppublish</xsl:when>
			<xsl:when test=".='collection'">ppublish</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="pub-date|date[@date-type='rev-recd']"> </xsl:template>
	<xsl:template match="pub-date|date[@date-type!='rev-recd']">
		<PubDate>
			<xsl:attribute name="PubStatus">
				<xsl:apply-templates select="@*"/>
			</xsl:attribute>
			<xsl:apply-templates select="year"/>
			<xsl:apply-templates select="month|season"/>
			<xsl:apply-templates select="day"/>
		</PubDate>
	</xsl:template>
	<xsl:template match="month|season">
		<Month>
			<xsl:value-of select="."/>
		</Month>
	</xsl:template>
	<xsl:template match="year">
		<Year>
			<xsl:value-of select="."/>
		</Year>
	</xsl:template>
	<xsl:template match="day">
		<Day>
			<xsl:value-of select="."/>
		</Day>
	</xsl:template>

	<xsl:template match="fpage">
		<xsl:element name="FirstPage">
			<xsl:value-of select="."/>
		</xsl:element>
	</xsl:template>

	<xsl:template match="lpage">
		<xsl:element name="LastPage">
			<xsl:value-of select="."/>
		</xsl:element>
	</xsl:template>

	<xsl:template match="contrib" mode="scielo-xml-author">

		<Author>
			<xsl:apply-templates select="name"/>
			<xsl:choose>
				<xsl:when test="count(xref[@ref-type='aff'])=1">
					<xsl:apply-templates select="xref[@ref-type='aff']"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="xref[@ref-type='aff']" mode="multiple-aff"/>
				</xsl:otherwise>
			</xsl:choose>
			
			<!--xsl:if test="not(@affiliation_code)">
						<xsl:apply-templates select="ancestor::record/affiliation/occ"/>
					</xsl:if-->
			<xsl:apply-templates select="contrib-id"></xsl:apply-templates>
		</Author>

	</xsl:template>
	<xsl:template match="contrib-id">
		<Identifier Source="{@contrib-id-type}"><xsl:value-of select="."/></Identifier>
	</xsl:template>
	<xsl:template match="contrib-id[@contrib-id-type='orcid' and not(contains(.,'orcid.org'))]">
		<Identifier Source="{@contrib-id-type}">http://orcid.org/<xsl:value-of select="."/></Identifier>
	</xsl:template>
	<xsl:template match="article-title/text()">
		<xsl:value-of select="."/>
	</xsl:template>
	<xsl:template match="article-title/*">
		<xsl:value-of select="."/>
	</xsl:template>
	<xsl:template match="article-title/xref"/>
	<xsl:template match="collab" mode="scielo-xml-author">
		<Author>
			<CollectiveName>
				<xsl:value-of select="."/>
			</CollectiveName>
		</Author>
	</xsl:template>
	<xsl:template match="name">
		<xsl:apply-templates select="given-names"/>
		<xsl:apply-templates select="surname"/>
		<xsl:apply-templates select="suffix"/>
	</xsl:template>
	<xsl:template match="given-names | FirstName ">
		<FirstName>
			<xsl:value-of select="." disable-output-escaping="yes"/>
		</FirstName>
	</xsl:template>
	<xsl:template match="surname | LastName">
		<LastName>
			<xsl:value-of select="." disable-output-escaping="yes"/>
		</LastName>
	</xsl:template>
	<xsl:template match="suffix | Suffix">
		<Suffix>
			<xsl:value-of select="." disable-output-escaping="yes"/>
		</Suffix>
	</xsl:template>
	<xsl:template match="prefix ">
		<Prefix>
			<xsl:value-of select="." disable-output-escaping="yes"/>
		</Prefix>
	</xsl:template>
	<xsl:template match="xref[@ref-type='aff']  | aff-id ">
		<xsl:variable name="code" select="@rid"/>
		<Affiliation>
			<xsl:apply-templates select="../../..//aff[@id = $code]" mode="scielo-xml-text"/>
		</Affiliation>
	</xsl:template>
	<xsl:template match="xref[@ref-type='aff']  | aff-id " mode="multiple-aff">
		<xsl:variable name="code" select="@rid"/>
		<AffiliationInfor>
			<Affiliation>
				<xsl:apply-templates select="../../..//aff[@id = $code]" mode="scielo-xml-text"/>
			</Affiliation>
		</AffiliationInfor>
	</xsl:template>
	
	<xsl:template match="institution[@content-type='original']" mode="scielo-xml-text"></xsl:template>
	<xsl:template match="aff" mode="scielo-xml-text">
		<xsl:apply-templates select="*[name()!='label']" mode="scielo-xml-text"/>
	</xsl:template>
	<xsl:template match="aff//*" mode="scielo-xml-text">
		<xsl:if test="position()!=1">, </xsl:if>
		<xsl:apply-templates select="*|text()"/>
	</xsl:template>
	<xsl:template match="aff//label" mode="scielo-xml-text"/>
	<xsl:template match="aff//text()" mode="scielo-xml-text">
		<xsl:if test="normalize-space(.)=','"/>
	</xsl:template>
	<xsl:template match="@*" mode="scielo-xml-x">
		<xsl:value-of select="." disable-output-escaping="yes"/>
		<xsl:value-of select="." disable-output-escaping="no"/>
		<xsl:value-of select="concat('&lt;![CDATA[',.,']]&gt;')" disable-output-escaping="yes"/>
	</xsl:template>

	<xsl:template match="article-id" mode="scielo-xml-pii">
		<xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="italic | bold | sup | sub">
		<xsl:apply-templates></xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="article[@article-type='other' or @article-type='book-review']">
	</xsl:template>
	
	
</xsl:stylesheet>
