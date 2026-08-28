import { fileURLToPath } from 'node:url'
import SwaggerParser from '@apidevtools/swagger-parser'

/**
 * Validates `src/openapi/openapi.json` is both well-formed JSON and a
 * structurally valid OpenAPI document (`technology-stack.md` — REST,
 * documented with OpenAPI/Swagger). Run via `npm run validate:openapi`.
 */
const specPath = fileURLToPath(new URL('../src/openapi/openapi.json', import.meta.url))

try {
  await SwaggerParser.validate(specPath)
  console.log('openapi.json is valid.')
} catch (err) {
  console.error('openapi.json is INVALID:', err.message)
  process.exitCode = 1
}
