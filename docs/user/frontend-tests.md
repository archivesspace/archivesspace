---
title: Frontend tests
layout: en
permalink: /user/frontend-tests/
---./build/run frontend:selenium # Firefox, headless
FIREFOX_OPTS= ./build/run frontend:selenium # Firefox, no-opts = heady

SELENIUM_CHROME=true ./build/run frontend:selenium # Chrome, headless
SELENIUM_CHROME=true CHROME_OPTS= ./build/run frontend:selenium # Chrome, no-opts = heady

