const fs = require("fs");
const { ESLint } = require("eslint");

(async function main() {
  const eslint = new ESLint();
  const files = ["frontend/", "public/"];
  const results = await eslint.lintFiles(files);
  const formatter = await eslint.loadFormatter("json");
  const resultText = formatter.format(results);

  console.log(resultText);
  fs.writeFileSync("eslint-output.json", resultText);
})().catch((error) => {
  process.exitCode = 1;
  console.error(error);
});
