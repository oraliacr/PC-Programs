# coding=utf-8

from datetime import datetime

from __init__ import _
import validation_status
import utils
import xml_utils
import article_utils
import article_validations
import html_reports

from article import PersonAuthor, CorpAuthor, format_author


log_items = []


def register_log(text):
    log_items.append(datetime.now().isoformat() + ' ' + text)


class ArticleDisplayReport(object):

    def __init__(self, article, sheet_data, xml_path, xml_name):
        self.article = article
        self.xml_name = xml_name
        self.xml_path = xml_path
        self.sheet_data = sheet_data

    @property
    def article_front(self):
        r = self.xml_name + ' is invalid.'
        if self.article.tree is not None:
            r = ''
            r += self.sps
            r += self.language
            r += self.toc_section
            r += self.article_type
            r += self.display_titles()
            r += self.doi
            r += self.article_id_other
            r += self.previous_article_pid
            r += self.order
            r += self.fpage
            r += self.fpage_seq
            r += self.elocation_id
            r += self.article_dates
            r += self.contrib_names
            r += self.contrib_collabs
            r += self.affiliations
            r += self.abstracts
            r += self.keywords

        return html_reports.tag('h2', 'article/front') + html_reports.tag('div', r, 'article-data')

    @property
    def article_body(self):
        r = ''
        r += self.sections
        r += self.formulas
        r += self.tables
        return html_reports.tag('h2', 'article/body') + html_reports.tag('div', r, 'article-data')

    @property
    def article_back(self):
        r = ''
        r += self.funding
        r += self.footnotes
        return html_reports.tag('h2', 'article/back') + html_reports.tag('div', r, 'article-data')

    @property
    def authors_sheet(self):
        labels, width, data = self.sheet_data.authors_sheet_data()
        return html_reports.tag('h2', _('Authors')) + html_reports.sheet(labels, data)

    @property
    def sources_sheet(self):
        labels, width, data = self.sheet_data.sources_sheet_data()
        return html_reports.tag('h2', _('Sources')) + html_reports.sheet(labels, data)

    def display_labeled_value(self, label, value, style=''):
        return html_reports.display_labeled_value(label, value, style)

    def display_titles(self):
        r = ''
        for title in self.article.titles:
            r += html_reports.display_labeled_value(title.language, title.title)
        return r

    def display_text(self, label, items):
        r = html_reports.tag('p', label, 'label')
        for item in items:
            r += self.display_labeled_value(item.language, item.text)
        return html_reports.tag('div', r)

    @property
    def language(self):
        return self.display_labeled_value('@xml:lang', self.article.language)

    @property
    def sps(self):
        return self.display_labeled_value('@specific-use', self.article.sps)

    @property
    def toc_section(self):
        return self.display_labeled_value('subject', self.article.toc_section, 'toc-section')

    @property
    def article_type(self):
        return self.display_labeled_value('@article-type', self.article.article_type, 'article-type')

    @property
    def article_dates(self):
        return self.display_labeled_value('date(epub-ppub)', article_utils.format_date(self.article.epub_ppub_date)) + self.display_labeled_value('date(epub)', article_utils.format_date(self.article.epub_date)) + self.display_labeled_value('date(collection)', article_utils.format_date(self.article.collection_date))

    @property
    def contrib_names(self):
        return html_reports.format_list('authors:', 'ol', [format_author(a) for a in self.article.contrib_names])

    @property
    def contrib_collabs(self):
        r = [a.collab for a in self.article.contrib_collabs]
        if len(r) > 0:
            r = html_reports.format_list('collabs', 'ul', r)
        else:
            r = self.display_labeled_value('collabs', 'None')
        return r

    @property
    def abstracts(self):
        return self.display_text('abstracts', self.article.abstracts)

    @property
    def keywords(self):
        return html_reports.format_list('keywords:', 'ol', ['(' + k['l'] + ') ' + k['k'] for k in self.article.keywords])

    @property
    def order(self):
        return self.display_labeled_value('order', self.article.order, 'order')

    @property
    def doi(self):
        return self.display_labeled_value('doi', self.article.doi, 'doi')

    @property
    def fpage(self):
        r = self.display_labeled_value('fpage', self.article.fpage, 'fpage')
        r += self.display_labeled_value('lpage', self.article.lpage, 'lpage')
        return r

    @property
    def fpage_seq(self):
        return self.display_labeled_value('fpage/@seq', self.article.fpage_seq, 'fpage')

    @property
    def elocation_id(self):
        return self.display_labeled_value('elocation-id', self.article.elocation_id, 'fpage')

    @property
    def funding(self):
        r = self.display_labeled_value('ack', self.article.ack_xml)
        r += self.display_labeled_value('fn[@fn-type="financial-disclosure"]', self.article.financial_disclosure, 'fpage')
        return r

    @property
    def article_id_other(self):
        return self.display_labeled_value('article-id[@pub-id-type="other"]', self.article.article_id_other)

    @property
    def previous_article_pid(self):
        return self.display_labeled_value('previous article id', self.article.previous_article_pid)

    @property
    def sections(self):
        _sections = []
        for item in self.article.article_sections:
            for label, sections in item.items():
                type_and_title_items = [sectitle + ' (' + sectype + ')' for sectype, sectitle in sections]
            _sections.append([label, type_and_title_items])
        return html_reports.format_list('sections:', 'ul', _sections)

    @property
    def formulas(self):
        r = html_reports.tag('p', 'disp-formulas:', 'label')
        for item in self.article.formulas:
            r += html_reports.tag('p', item)
        return r

    @property
    def footnotes(self):
        r = ''
        for item in self.article.article_fn_list:
            scope, fn_xml = item
            r += html_reports.tag('p', scope, 'label')
            r += html_reports.tag('p', fn_xml)
        if len(r) > 0:
            r = html_reports.tag('p', 'foot notes:', 'label') + r
        return r

    @property
    def issue_header(self):
        if self.article.tree is not None:
            r = [self.article.journal_title, self.article.journal_id_nlm_ta, self.article.issue_label, article_utils.format_date(self.article.issue_pub_date)]
            return html_reports.tag('div', '\n'.join([html_reports.tag('h5', item) for item in r if item is not None]), 'issue-data')
        else:
            return ''

    @property
    def tables(self):
        r = '<!-- no tables -->'
        if len(self.article.tables) > 0:
            r = html_reports.tag('p', 'Tables:', 'label')

            for t in self.article.tables:
                print(t)
                header = html_reports.tag('h3', t.id)
                table_data = ''
                table_data += html_reports.display_labeled_value('label', t.label, 'label')
                table_data += html_reports.display_labeled_value('caption',  t.caption, 'label')
                table_data += html_reports.tag('p', 'table-wrap/table (xml)', 'label')
                table_data += html_reports.tag('div', html_reports.format_html_data(t.table), 'xml')
                if t.table:
                    table_data += html_reports.tag('p', 'table-wrap/table', 'label')
                    table_data += html_reports.tag('div', t.table, 'element-table')
                if t.graphic:
                    #table_data += html_reports.display_labeled_value('table-wrap/graphic', t.graphic.display('file:///' + self.xml_path), 'value')
                    table_data += html_reports.display_labeled_value('table-wrap/graphic', html_reports.image('file:///' + self.xml_path), 'value')
                r += header + html_reports.tag('div', table_data, 'block')
        return r

    @property
    def table_tables(self):
        r = '<!-- no tables -->'
        if len(self.article.tables) > 0:
            r = html_reports.tag('p', 'Tables:', 'label')
            for t in self.article.tables:
                if t.table:
                    table_data = ''
                    table_data += html_reports.display_labeled_value('label', t.label, 'label')
                    table_data += html_reports.tag('div', t.table, 'element-table')
                    r += html_reports.tag('div', table_data, 'block')
        return r

    @property
    def affiliations(self):
        r = html_reports.tag('p', 'Affiliations:', 'label')
        for item in self.article.affiliations:
            r += html_reports.tag('p', html_reports.format_html_data(item.xml))
        th, w, data = self.sheet_data.affiliations_sheet_data()
        r += html_reports.sheet(th, data)
        return r

    @property
    def id_and_xml_list(self):
        sheet_data = []
        t_header = ['@id', 'xml']
        for item in self.article.elements_which_has_id_attribute:
            row = {}
            row['@id'] = item.attrib.get('id')
            row['xml'] = xml_utils.node_xml(item)
            if '>' in row['xml']:
                row['xml'] = row['xml'][0:row['xml'].find('>')+1]
            sheet_data.append(row)
        r = html_reports.tag('h2', 'elements and @id:')
        r += html_reports.sheet(t_header, sheet_data)
        return r

    @property
    def id_and_tag_list(self):
        sheet_data = []
        t_header = ['@id', 'tag']
        for item in self.article.elements_which_has_id_attribute:
            row = {}
            row['@id'] = item.attrib.get('id')
            row['tag'] = item.tag
            sheet_data.append(row)
        r = html_reports.tag('h2', 'elements and @id:')
        r += html_reports.sheet(t_header, sheet_data)
        return r

    @property
    def references_stats(self):
        r = html_reports.tag('h2', 'references')
        sheet_data = []
        for ref_type, q in self.article.refstats.items():
            row = {}
            row['element-citation/@publication-type'] = ref_type
            row['quantity'] = q
            sheet_data.append(row)
        r += html_reports.sheet(['element-citation/@publication-type', 'quantity'], sheet_data)
        return r


class ArticleValidationReport(object):

    def __init__(self, article_validation):
        self.article_validation = article_validation

    def display_items(self, items):
        r = ''
        for item in items:
            r += self.display_item(item)
        return r

    def display_item(self, item):
        return html_reports.p_message(item, False)

    def validations(self, display_all_message_types):
        items, performance = self.article_validation.validations
        items = [item for item in items if item is not None]
        new_items = []
        for item in [item for item in items if len(item) == 3]:
            label, status, msg = item
            if display_all_message_types:
                new_items.append((label, status, msg))
            else:
                if status != validation_status.STATUS_OK:
                    new_items.append((label, status, msg))
        items = new_items

        r = html_reports.validations_table(items)

        r += self.references(display_all_message_types)

        if len(r) > 0:
            r = html_reports.tag('div', r, 'article-messages')

        return r

    def references(self, display_all):
        rows = ''
        found_errors = []
        for ref, ref_result in self.article_validation.references:
            if not display_all:
                found_errors = [status for label, status, msg in ref_result if status in [validation_status.STATUS_WARNING, validation_status.STATUS_ERROR, validation_status.STATUS_FATAL_ERROR]]
                ref_result = [(label, status, msg) for label, status, msg in ref_result if status != validation_status.STATUS_OK]

            if len(found_errors) > 0:
                rows += html_reports.tag('h3', 'Reference ' + ref.id)
                rows += html_reports.validations_table(ref_result)
        return rows


class ArticleSheetData(object):

    def __init__(self, article, article_validation):
        self.article = article
        self.article_validation = article_validation

    def authors_sheet_data(self, filename=None):
        r = []
        t_header = ['xref', 'publication-type', 'role', 'given-names', 'surname', 'suffix', 'prefix', 'collab']
        if not filename is None:
            t_header = ['filename', 'scope'] + t_header
        for a in self.article.contrib_names:
            row = {}
            row['scope'] = 'article meta'
            row['filename'] = filename
            row['xref'] = ' '.join(a.xref)
            row['role'] = a.role
            row['publication-type'] = self.article.article_type
            row['given-names'] = a.fname
            row['surname'] = a.surname
            row['suffix'] = a.suffix
            row['prefix'] = a.prefix
            r.append(row)

        for a in self.article.contrib_collabs:
            row = {}
            row['scope'] = 'article meta'
            row['filename'] = filename
            row['publication-type'] = self.article.article_type
            row['collab'] = a.collab
            row['role'] = a.role
            r.append(row)

        for ref in self.article.references:
            for item in ref.authors_list:
                row = {}
                row['scope'] = ref.id
                row['filename'] = filename
                row['publication-type'] = ref.publication_type

                if isinstance(item, PersonAuthor):
                    row['given-names'] = item.fname
                    row['surname'] = item.surname
                    row['suffix'] = item.suffix
                    row['prefix'] = item.prefix
                    row['role'] = item.role
                elif isinstance(item, CorpAuthor):
                    row['collab'] = item.collab
                    row['role'] = item.role
                else:
                    row['given-names'] = '?'
                    row['surname'] = '?'
                    row['suffix'] = '?'
                    row['prefix'] = '?'
                    row['role'] = '?'
                r.append(row)
        return (t_header, [], r)

    def sources_sheet_data(self, filename=None):
        r = []
        t_header = ['ID', 'type', 'year', 'source', 'publisher name', 'location', ]
        if not filename is None:
            t_header = ['filename', 'scope'] + t_header

        for ref in self.article.references:
            row = {}
            row['scope'] = ref.id
            row['ID'] = ref.id
            row['filename'] = filename
            row['type'] = ref.publication_type
            row['year'] = ref.year
            row['source'] = ref.source
            row['publisher name'] = ref.publisher_name
            row['location'] = ref.publisher_loc
            r.append(row)
        return (t_header, [], r)

    def tables_sheet_data(self, path):
        t_header = ['ID', 'label/caption', 'table/graphic']
        r = []
        for t in self.article.tables:
            row = {}
            row['ID'] = t.graphic_parent.id
            row['label/caption'] = t.graphic_parent.label + '/' + t.graphic_parent.caption
            #row['table/graphic'] = t.table + t.graphic_parent.graphic.display('file:///' + path)
            row['table/graphic'] = t.table + html_reports.image('file:///' + path)
            r.append(row)
        return (t_header, ['label/caption', 'table/graphic'], r)

    def files_and_href(self, package_path):
        r = ''
        r += html_reports.tag('h4', _('Files in the package'))
        th, data = self.package_files(package_path)
        r += html_reports.sheet(th, data, table_style='validation')
        r += html_reports.tag('h4', '@href')
        th, data = self.hrefs_sheet_data(package_path)
        r += html_reports.sheet(th, data, table_style='validation')
        return r

    def hrefs_sheet_data(self, path):
        t_header = ['label', 'status', 'message', _('why it is not a valid message?'), 'display', 'xml']
        r = []
        href_items = self.article_validation.href_list(path)
        for src in sorted(href_items.keys()):
            hrefitem = href_items.get(src)
            for result in hrefitem['results']:
                row = {}
                row['label'] = src
                row['xml'] = hrefitem['elem'].xml
                row['display'] = hrefitem['display']
                row['status'] = result[0]
                row['message'] = result[1]
                row[_('why it is not a valid message?')] = ''
                r.append(row)
        return (t_header, r)

    def package_files(self, package_path):
        r = []
        t_header = ['label', 'status', 'message', _('why it is not a valid message?')]
        if len(self.article_validation.package_files(package_path)) > 0:
            for filename, status, message in self.article_validation.package_files(package_path):
                row = {}
                row['label'] = filename
                row['status'] = status
                row['message'] = message
                row[_('why it is not a valid message?')] = ''
                r.append(row)
        return (t_header, r)

    def affiliations_sheet_data(self):
        t_header = ['aff id', 'aff orgname', 'aff norgname', 'aff orgdiv1', 'aff orgdiv2', 'aff country', 'aff city', 'aff state', ]
        r = []
        for a in self.article.affiliations:
            row = {}
            row['aff id'] = a.id
            row['aff norgname'] = a.norgname
            row['aff orgname'] = a.orgname
            row['aff orgdiv1'] = a.orgdiv1
            row['aff orgdiv2'] = a.orgdiv2
            row['aff city'] = a.city
            row['aff state'] = a.state
            row['aff country'] = a.country
            r.append(row)
        return (t_header, ['aff xml'], r)


def article_data_and_validations_report(journal, article, new_name, package_path, is_db_generation, is_sgml_generation):
    if article.tree is None:
        sheet_data = None
        article_display_report = None
        article_validation_report = None
        content = validation_status.STATUS_FATAL_ERROR + ': ' + _('Unable to get data of ') + new_name + '.'
    else:
        article_validation = article_validations.ArticleContentValidation(journal, article, is_db_generation, False)
        sheet_data = ArticleSheetData(article, article_validation)
        article_display_report = ArticleDisplayReport(article, sheet_data, package_path, new_name)
        article_validation_report = ArticleValidationReport(article_validation)

        content = []
        #FIXME

        if is_sgml_generation:
            content.append(article_display_report.issue_header)
            content.append(article_display_report.article_front)

        content.append(article_validation_report.validations(display_all_message_types=False))
        content.append(article_display_report.table_tables)
        content.append(sheet_data.files_and_href(package_path))

        if is_sgml_generation:
            content.append(article_display_report.article_body)
            content.append(article_display_report.article_back)

        content = html_reports.join_texts(content)

    return content
