---
title: Public tests
layout: en
permalink: /user/public-tests/
---./build/run public:test # Firefox, headless
FIREFOX_OPTS= ./build/run public:test # Firefox, no-opts = heady

SELENIUM_CHROME=true ./build/run public:test # Chrome, headless
SELENIUM_CHROME=true CHROME_OPTS= ./build/run public:test # Chrome, no-opts = heady
```

Tests can be scoped to specific files or groups:

```bash
./build/run .. -Dspec='path/to/spec/from/spec/directory' # single file
./build/run .. -Dexample='[description from it block]' # specific block

