# Test suite for xsd2json

Tools to test the `xsd2json` XQuery library.

## Provided tests

### Run interpreted tests

Each file in the `xsd` directory will be converted to a JSON Schema instance. Its output gets compared with the related JSON file in the `json` directory. You can run the interpreted test for all files via


### Validate tested JSON output

As the expected JSON output files in the `json` subfolder are created manually it might be useful to check if they really satisfy the [JSON Schema Core Meta-Schema](http://json-schema.org/schema), i.e. are valid JSON Schema instances.

