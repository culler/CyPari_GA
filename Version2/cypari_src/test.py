import doctest, re, getopt, sys
from . import tests
from . import gen
from .gen import Pari
import sys
if sys.version_info.major == 2:
    from . import py2tests
else:
    from . import py3tests

cpu_width = '64bit' if sys.maxsize > 2**32 else '32bit'

class DocTestParser(doctest.DocTestParser):

    def parse(self, string, name='<string>'):
        # Remove tests for the wrong architecture
        regex32 = re.compile(r'(\n.*?)\s+# 32-bit\s*$', re.MULTILINE)
        regex64 = re.compile(r'(\n.*?)\s+# 64-bit\s*$', re.MULTILINE)
        if cpu_width == '64bit':
            string = regex32.sub('', string)
            string = regex64.sub('\g<1>\n', string)
        else:
            string = regex64.sub('', string)
            string = regex32.sub('\g<1>\n', string)
        regex_random = re.compile(r'(\n.*?)\s+# random\s*\n.*$', re.MULTILINE)
        string = regex_random.sub('', string)
        # Adjust the name of the PariError exception
        # Remove deprecation warnings in the output
        string = re.sub('[ ]*doctest:...:[^\n]*\n', '', string)
        # Enable sage tests
        string = re.sub('sage:', '>>>', string)
        string = re.sub('\.\.\.\.:', '...', string)
        # Remove lines containing :: which confuse doctests
        string = re.sub(' ::', '                  ', string)
        # Get the examples
        result = doctest.DocTestParser.parse(self, string, name)
        # For Python3, patch up "wants" that refer to PariError
        #if sys.version_info.major > 2:
        #    for item in result:
        #        if isinstance(item, doctest.Example):
        #            item.want = re.sub('PariError:', 'cypari_src.gen.PariError:', item.want)
        return result

extra_globals = dict([('pari', gen.pari)])    
modules_to_test = [
    (gen, extra_globals),
    (tests, extra_globals),
]

# Cython adds a docstring to gen.__test__ *only* if it contains '>>>'.
# To enable running Sage doctests, with prompt 'sage:', we need to add
# docstrings containing no '>>>' prompt to gen.__test__ ourselves.
# Unfortunately, line numbers are not readily available to us.
for cls in (gen.Gen, gen.Pari):
    for key, value in cls.__dict__.items():
        docstring = getattr(cls.__dict__[key], '__doc__')
        if isinstance(docstring, str):
            if docstring.find('sage:') >= 0 and docstring.find('>>>') < 0:
                gen.__test__['%s.%s (line 0)'%(cls.__name__, key)] = docstring

print('Found %s docstrings with sage: tests only.'%len(gen.__test__))

def runtests(verbose=False):
    parser = DocTestParser()
    finder = doctest.DocTestFinder(parser=parser)
    failed, attempted = 0, 0
    for module, extra_globals in modules_to_test:
        runner = doctest.DocTestRunner(
            verbose=verbose,
            optionflags=doctest.ELLIPSIS|doctest.IGNORE_EXCEPTION_DETAIL)
        count = 0
        for test in finder.find(module, extraglobs=extra_globals):
            count += 1
            runner.run(test)
        print('Parsed %s docstrings in %s.'%(count, module))
        result = runner.summarize()
        failed += result.failed
        attempted += result.attempted
        print(result)
    print('\nAll doctests:\n   %s failures out of %s tests.' % (failed, attempted))
    return failed

if __name__ == '__main__':
    try:
        optlist, args = getopt.getopt(sys.argv[1:], 'v', ['verbose'])
        opts = [o[0] for o in optlist]
        verbose = '-v' in opts
    except getopt.GetoptError:
        verbose = False
    failed = runtests(verbose)
    print('Total tests: %s'%total_tests)
    sys.exit(failed)

