const fs = require('fs')
const stylelint = require('stylelint')

const files = '{frontend,public}/**/*.{less,css,scss}'

stylelint.lint({ files }).then(function (resultObject) {
  fs.writeFileSync('stylelint-output.json', resultObject.output)
})
