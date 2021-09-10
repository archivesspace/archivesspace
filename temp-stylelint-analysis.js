const OUTPUT = require('./stylelint-output.json').filter((item) => item.errored)

console.log('Errors count by type:\n', errorsCountByType(OUTPUT), '\n')
console.log('Errors by file by type:\n', errorsByTypeByFile(OUTPUT), '\n')

function errorsCountByType(data) {
  const unsorted = data.reduce((acc, item) => {
    item.warnings.forEach((warning) => {
      if (!acc.hasOwnProperty(warning.rule)) acc[warning.rule] = 1
      else acc[warning.rule]++
    })

    return acc
  }, {})

  return Object.entries(unsorted)
    .sort((a, b) => b[1] - a[1])
    .reduce((acc, item) => {
      acc[item[0]] = item[1]
      return acc
    }, {})
}

function errorsByTypeByFile(data) {
  return data.reduce((acc, item) => {
    const root = 'archivesspace/'
    const indexRootStart = item.source.indexOf(root)
    const rootLength = root.length
    const file = item.source.substring(indexRootStart + rootLength)

    item.warnings.forEach((warning) => {
      if (!acc.hasOwnProperty(warning.rule)) {
        acc[warning.rule] = {}
        acc[warning.rule][file] = [warning.text]
      } else if (!acc[warning.rule].hasOwnProperty(file))
        acc[warning.rule][file] = [warning.text]
      else acc[warning.rule][file].push(warning.text)
    })

    return acc
  }, {})
}
