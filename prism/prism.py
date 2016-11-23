from __future__ import absolute_import
from __future__ import unicode_literals
import re

from markdown import Extension
from markdown.preprocessors import Preprocessor

class PrismExtension(Extension):
    def extendMarkdown(self, md, md_globals):
        md.registerExtension(self)
        md.preprocessors.add('prism_code_block',
                             PrismPreprocessor(md),
                             ">normalize_whitespace")

class PrismPreprocessor(Preprocessor):
    PRISM_BLOCK_RE = re.compile( \
        r'(?P<fence>^(?:~{3,}|`{3,}))[ ]*(\{?\.?(?P<lang>[a-zA-Z0-9_+-]*)\}?)?[ ]*\n(?P<code>.*?)(?<=\n)(?P=fence)[ ]*$',
        re.MULTILINE | re.DOTALL
    )
    CODE_WRAP = '<pre><code%s>%s</code></pre>'
    LANG_TAG = ' class="language-%s"'

    def __init__(self, md):
        super(PrismPreprocessor, self).__init__(md)

    def run(self, lines):
        text = "\n".join(lines)
        while 1:
            m = self.PRISM_BLOCK_RE.search(text)
            if m:
                lang = ''
                if m.group('lang'):
                    lang = self.LANG_TAG % m.group('lang')
                code = self.CODE_WRAP % (lang, self._escape(m.group('code')))
                placeholder = self.markdown.htmlStash.store(code, safe=True)
                text = '%s\n%s\n%s' % (text[:m.start()], placeholder, text[m.end():])
            else:
                break
        return text.split("\n")

    def _escape(self, txt):
        """ basic html escaping """
        txt = txt.replace('&', '&amp;')
        txt = txt.replace('<', '&lt;')
        txt = txt.replace('>', '&gt;')
        txt = txt.replace('"', '&quot;')
        return txt

def makeExtension(*args, **kwargs):
    return PrismExtension(*args, **kwargs)
