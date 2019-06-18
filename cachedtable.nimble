# Package

version       = "0.1.0"
author        = "xmonader"
description   = "In memory key value store/cache"
license       = "BSD-3-Clause"
srcDir        = "src"
bin           = @["cachedtable"]



# Dependencies

requires "nim >= 0.20.0"

task genDocs, "Create code documentation for nim-cached":
    exec "nim doc --threads:on --project src/cachedtable.nim && rm -rf docs/api; mkdir -p docs && mv src/htmldocs docs/api "

