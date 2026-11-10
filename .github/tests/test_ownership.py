"""Compile actual helpers and the unchanged SDK; never invoke release build phases."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(os.environ.get("MDI_OWNERSHIP_SOURCE", Path(__file__).resolve().parents[2]))
HERE = Path(__file__).resolve().parent


@unittest.skipUnless(sys.platform == "darwin", "requires Apple's Cocoa/CoreFoundation")
class OwnershipTests(unittest.TestCase):
    def test_actual_sources(self):
        with tempfile.TemporaryDirectory(prefix="mdi-ownership-") as directory:
            output = Path(directory)
            flags = ["-g", "-O1", "-fsanitize=address,undefined",
                     "-fno-omit-frame-pointer", "-Wno-deprecated-declarations",
                     "-Wno-multichar", "-I", str(ROOT / "4D Plugin API"),
                     "-I", str(ROOT / "4D Plugin API/Classes"),
                     "-I", str(ROOT / "support")]
            # The unchanged legacy SDK initializes an integer with NULL at line 7150.
            subprocess.run(["clang", *flags, "-Wno-error=int-conversion", "-c",
                            str(ROOT / "4D Plugin API/4DPluginAPI.c"),
                            "-o", str(output / "sdk.o")], check=True)
            subprocess.run([
                "clang++", *flags, "-std=c++11", "-x", "objective-c++", "-fsyntax-only",
                str(ROOT / "4DPlugin-MDI.cpp"),
                str(ROOT / "4D Plugin API/Classes/C_LONGINT.cpp"),
                str(ROOT / "4D Plugin API/Classes/C_BLOB.cpp"),
            ], check=True)
            executable = output / "ownership"
            subprocess.run([
                "clang++", *flags, "-std=c++11", "-x", "objective-c++",
                str(HERE / "ownership.mm"), str(ROOT / "support/4DPlugin-JSON.cpp"),
                str(ROOT / "4D Plugin API/Classes/C_TEXT.cpp"),
                str(ROOT / "4D Plugin API/Classes/ARRAY_TEXT.cpp"),
                "-x", "none", str(output / "sdk.o"),
                "-framework", "Cocoa", "-o", str(executable),
            ], check=True)
            for mode in ("setters", "getters", "handoffs", "arrays", "scalar"):
                for empty in ("allocated", "null"):
                    with self.subTest(mode=mode, empty=empty):
                        subprocess.run([str(executable), mode, empty], check=True,
                                       env={**os.environ, "ASAN_OPTIONS": "detect_leaks=0",
                                            "UBSAN_OPTIONS": "halt_on_error=1"})


if __name__ == "__main__":
    unittest.main()
