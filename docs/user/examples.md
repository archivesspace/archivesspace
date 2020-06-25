---
title: EXAMPLES
layout: en
permalink: /user/examples/
---./build/run frontend:selenium -Dexample='Repository model'
FIREFOX_OPTS= ./build/run frontend:selenium -Dexample='Repository model'# Firefox, heady

./build/run public:test -Dspec='features/accessibility_spec.rb'
SELENIUM_CHROME=true CHROME_OPTS= ./build/run public:test -Dspec='features/accessibility_spec.rb' # Chrome, heady
```

Note, however, that some tests are dependent on a sequence of ordered steps and may not always run cleanly in isolation.  In this case, more than the example provided may be run, and/or unexpected fails may result.
