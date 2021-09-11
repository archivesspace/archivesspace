const OUTPUT = require('./eslint-output.json').filter(
  file => file.errorCount > 0
)

const ERRORS = OUTPUT

console.log('Errors count by type:\n', errorsCountByType(OUTPUT), '\n')
console.log('Errors by file by type:\n', errorsByTypeByFile(OUTPUT), '\n')

function errorsCountByType(data) {
  return data.reduce((acc, file) => {
    const errors = file.messages
      .filter(msg => msg.severity === 2)
      .forEach(msg => {
        if (!acc.hasOwnProperty(msg.ruleId)) acc[msg.ruleId] = 1
        else acc[msg.ruleId]++
      })

    return acc
  }, {})
}

function errorsByTypeByFile(data) {
  return data.reduce((acc, file) => {
    const root = 'archivesspace/'
    const indexRootStart = file.filePath.indexOf(root)
    const rootLength = root.length
    const fName = file.filePath.substring(indexRootStart + rootLength)

    file.messages
      .filter(msg => msg.severity === 2)
      .forEach(msg => {
        if (!acc.hasOwnProperty(msg.ruleId)) {
          acc[msg.ruleId] = {}
          acc[msg.ruleId][fName] = [msg.message]
        } else if (!acc[msg.ruleId].hasOwnProperty(fName))
          acc[msg.ruleId][fName] = [msg.message]
        else acc[msg.ruleId][fName].push(msg.message)
      })

    return acc
  }, {})
}
