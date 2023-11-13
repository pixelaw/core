const fs = require("fs");
const path = require("path");

// Path to the generated graphql file
const filePath = path.resolve(__dirname, "./generated/graphql.ts");
let content = fs.readFileSync(filePath, 'utf-8');
let lines = content.split('\n');

const issues = [
  `import { GraphQLClientRequestHeaders } from 'graphql-request/build/cjs/types';`,
  `Dom.Headers`,
  `GraphQLError`
]

const fix = '// eslint-disable-next-line @typescript-eslint/ban-ts-comment\n' +
  '// @ts-ignore\n'

lines = lines.map(line => {
  if (issues.some(issue => line.includes(issue))) {
    return fix + line;
  }
  return line;
});

content = lines.join('\n');
fs.writeFileSync(filePath, content);
