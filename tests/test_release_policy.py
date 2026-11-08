import unittest

from tools.check_release import release_notes, validate_release


class ReleasePolicyTests(unittest.TestCase):
    def test_minor_requires_notes(self):
        with self.assertRaises(ValueError):
            validate_release("0.2.0", "0.1.0", "")

    def test_major_requires_notes(self):
        with self.assertRaises(ValueError):
            validate_release("1.0.0", "0.9.9", "")

    def test_patch_can_skip_notes(self):
        validate_release("0.1.1", "0.1.0", "")

    def test_minor_requires_updated_content(self):
        notes = "## 0.2.0\nAdded drag cancellation and configurable outlines."
        with self.assertRaises(ValueError):
            validate_release("0.2.0", "0.1.0", notes, notes)
        validate_release("0.2.0", "0.1.0", notes)

    def test_empty_section_does_not_count_next_release(self):
        notes = (
            "## 0.2.0\n\n## 0.1.0\nAdded drag cancellation and configurable outlines."
        )
        self.assertEqual(release_notes(notes, "0.2.0"), "")
        with self.assertRaises(ValueError):
            validate_release("0.2.0", "0.1.0", notes)

    def test_downgrade_rejected(self):
        with self.assertRaises(ValueError):
            validate_release("0.1.0", "0.2.0", "")

    def test_initial_release_requires_notes(self):
        with self.assertRaises(ValueError):
            validate_release("0.1.0", None, "")

    def test_unchanged_version_allowed(self):
        validate_release("0.1.0", "0.1.0", "")
