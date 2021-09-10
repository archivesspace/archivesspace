const OUTPUT = require('./eslint-output.json').filter(
  (item) => item.messages.length > 0
)

console.log('Errors count by type:\n', errorsCountByType(OUTPUT), '\n')
console.log('Errors by file by type:\n', errorsByTypeByFile(OUTPUT), '\n')

function errorsCountByType(data) {
  return data.reduce((acc, item) => {
    item.messages.forEach((msg) => {
      if (!acc.hasOwnProperty(msg.ruleId)) acc[msg.ruleId] = 1
      else acc[msg.ruleId]++
    })

    return acc
  }, {})
}

function errorsByTypeByFile(data) {
  return data.reduce((acc, item) => {
    const root = 'archivesspace/'
    const indexRootStart = item.filePath.indexOf(root)
    const rootLength = root.length
    const file = item.filePath.substring(indexRootStart + rootLength)

    item.messages.forEach((msg) => {
      if (!acc.hasOwnProperty(msg.ruleId)) {
        acc[msg.ruleId] = {}
        acc[msg.ruleId][file] = [msg.message]
      } else if (!acc[msg.ruleId].hasOwnProperty(file))
        acc[msg.ruleId][file] = [msg.message]
      else acc[msg.ruleId][file].push(msg.message)
    })

    return acc
  }, {})
}
