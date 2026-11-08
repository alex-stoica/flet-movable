import unittest

from tools.check_style import violations


class StyleTests(unittest.TestCase):
    def test_python_comment_blocks(self):
        self.assertTrue(violations("# " + "word " * 13 + "\n# " + "word " * 13, ".py"))
        self.assertFalse(violations("# " + "word " * 25, ".py"))

    def test_docstring_limit(self):
        self.assertTrue(violations('"""' + "word " * 46 + '"""', ".py"))
        self.assertFalse(violations('"""' + "word " * 45 + '"""', ".py"))

    def test_dart_strings_are_not_comments(self):
        self.assertFalse(
            violations(
                'final url = "https://example.test/' + "word " * 30 + '";', ".dart"
            )
        )

    def test_dart_comment_limits(self):
        self.assertTrue(violations("/* " + "word " * 26 + " */", ".dart"))
        self.assertTrue(
            violations("// " + "word " * 13 + "\n// " + "word " * 13, ".dart")
        )
