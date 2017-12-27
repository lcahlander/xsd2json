# xsd2json
XML Schema to JSON Schema Transform - Development and Test Environment


The options that are supported are:
  
* 'keepNamespaces' - set to true if keeping prefices in the property names  is required otherwise prefixes are eliminated. - default is false
* 'schemaId'       - the name of the schema - default is 'output.json'
* 'restrictive'    - Maps the XSD data types to the more restrictive properties. - default is true

#Running from Command Line
##Requirements

* Saxon 9 EE (licensed copy is needed to use XQuery 3.1 features)

```
java -cp /usr/share/java/saxon.jar net.sf.saxon.Query -q:generate.xqy -s:schema.xsd -o:schema.json keepNamespace=true schemaId=schema.json restrictive=false
```


#XSD Type to JSON Properties
##xs:anySimpleType
###Restrictive
```
{
    'xsdType': 'anySimpleType',
    'oneOf': [
        { 'type': 'integer' },
        { 'type': 'string' },
        { 'type': 'number' },
        { 'type': 'boolean' },
        { 'type': 'null' }
    ]
}
```

##xs:anyURI
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'anyURI',
    'pattern': '^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'anyURI'
}
```

##xs:base64Binary
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'base64Binary',
    'pattern': '^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'base64Binary'
}
```

##xs:boolean
###Restrictive
```
{
    'type': 'boolean',
    'xsdType': 'boolean'
}
```

###Non-Restrictive
```
{
    'type': 'boolean',
    'xsdType': 'boolean'
}
```

##xs:Boolean
###Restrictive
```
{
    'type': 'boolean',
    'xsdType': 'Boolean'
}
```

###Non-Restrictive
```
{
    'type': 'boolean',
    'xsdType': 'Boolean'
}
```

##xs:byte
###Restrictive
```
{
    'type': 'integer',
    'xsdType': 'byte',
    'minimum': -128,
    'maximum': 127,
    'exclusiveMinimum': false,
    'exclusiveMaximum': false
}
```

###Non-Restrictive
```
{
    'type': 'integer',
    'xsdType': 'byte'
}
```

##xs:date
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'date',
    'pattern': '^\d{4}-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'date',
    'pattern': '^\d{4}-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])$'
}
```

##xs:dateTime
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'dateTime',
    'pattern': '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))(T((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'dateTime',
    'pattern': '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))(T((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$'
}
```

##xs:decimal
###Restrictive
```
{
    'type': 'number',
    'xsdType': 'decimal'
}
```

###Non-Restrictive
```
{
    'type': 'number',
    'xsdType': 'decimal'
}
```

##xs:decimal
###Restrictive
```
{
    'type': 'number',
    'xsdType': 'decimal'
}
```

###Non-Restrictive
```
{
    'type': 'number',
    'xsdType': 'decimal'
}
```

##xs:double
###Restrictive
```
{
    'type': 'number',
    'xsdType': 'double'
}
```

###Non-Restrictive
```
{
    'type': 'number',
    'xsdType': 'double'
}
```

##xs:duration
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'duration',
    'pattern': '^P(?!$)(\d+Y)?(\d+M)?(\d+W)?(\d+D)?(T(?=\d+[HMS])(\d+H)?(\d+M)?(\d+S)?)?$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'duration',
    'pattern': '^P(?!$)(\d+Y)?(\d+M)?(\d+W)?(\d+D)?(T(?=\d+[HMS])(\d+H)?(\d+M)?(\d+S)?)?$'
}
```

##xs:ENTITIES
###Restrictive
```
{
    'type': 'array',
    'xsdType': 'ENTITIES',
    'items': {
        'type': 'string',
        'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
    }
}
```

###Non-Restrictive
```
{
    'type': 'array',
    'xsdType': 'ENTITIES',
    'items': {
        'type': 'string'
    }
}
```

##xs:ENTITY
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'ENTITY',
    'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'ENTITY'
}
```

##xs:float
###Restrictive
```
{
    'type': 'number',
    'xsdType': 'float'
}
```

###Non-Restrictive
```
{
    'type': 'number',
    'xsdType': 'float'
}
```

##xs:gDay
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'gDay',
    'pattern': '^(0[1-9]|[12][0-9]|3[01])$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'gDay',
    'pattern': '^(0[1-9]|[12][0-9]|3[01])$'
}
```

##xs:gMonthDay
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'gMonthDay',
    'pattern': '^(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'gMonthDay',
    'pattern': '^(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])$'
}
```

##xs:gMonth
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'gMonth',
    'pattern': '^(0[1-9]|1[012])$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'gMonth',
    'pattern': '^(0[1-9]|1[012])$'
}
```

##xs:gYearMonth
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'gYearMonth',
    'pattern': '^(19|20)\d\d-(0[1-9]|1[012])$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'gYearMonth',
    'pattern': '^(19|20)\d\d-(0[1-9]|1[012])$'
}
```

##xs:gYear
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'gYear',
    'pattern': '^(19|20)\d\d$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'gYear',
    'pattern': '^(19|20)\d\d$'
}
```

##xs:hexBinary
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'hexBinary',
    'pattern': '^([0-9a-fA-F]{2})*$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'hexBinary'
}
```

##xs:IDREF
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'IDREF',
    'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'IDREF'
}
```

##xs:IDREFS
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'IDREFS',
    'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'IDREFS'
}
```

##xs:ID
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'ID',
    'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'ID'
}
```

##xs:integer
###Restrictive
```
{
    'type': 'integer',
    'xsdType': 'integer'
}
```

###Non-Restrictive
```
{
    'type': 'integer',
    'xsdType': 'integer'
}
```

##xs:int
###Restrictive
```
{
    'type': 'integer',
    'xsdType': 'int',
    'minimum': -2147483648,
    'maximum': 2147483647,
    'exclusiveMinimum': false,
    'exclusiveMaximum': false
}
```

###Non-Restrictive
```
{
    'type': 'integer',
    'xsdType': 'int'
}
```

##xs:language
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'language',
    'pattern': '^[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'language'
}
```

##xs:long
###Restrictive
```
{
    'type': 'integer',
    'xsdType': 'long',
    'minimum': -9223372036854775808,
    'maximum': 9223372036854775807,
    'exclusiveMinimum': false,
    'exclusiveMaximum': false
}
```

###Non-Restrictive
```
{
    'type': 'integer',
    'xsdType': 'long'
}
```

##xs:Name
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'Name',
    'pattern': '^[:A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9:A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'Name'
}
```

##xs:NCName
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'NCName',
    'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'NCName'
}
```

##xs:negativeInteger
###Restrictive
```
{
    'type': 'integer',
    'xsdType': 'negativeInteger',
    'maximum': 0,
    'exclusiveMinimum': true
}
```

###Non-Restrictive
```
{
    'type': 'integer',
    'xsdType': 'negativeInteger',
    'maximum': 0,
    'exclusiveMinimum': true
}
```

##xs:NMTOKEN
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'NMTOKEN',
    'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'NMTOKEN'
}
```

##xs:NMTOKENS
###Restrictive
```
{
    'type': 'array',
    'xsdType': 'NMTOKENS',
    'items': {
        'type': 'string',
        'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
    }
}
```

###Non-Restrictive
```
{
    'type': 'array',
    'xsdType': 'NMTOKENS',
    'items': {
        'type': 'string'
    }
}
```

##xs:nonNegativeInteger
###Restrictive
```
{
    'type': 'integer',
    'xsdType': 'nonNegativeInteger',
    'minimum': 0,
    'exclusiveMinimum': false
}
```

###Non-Restrictive
```
{
    'type': 'integer',
    'xsdType': 'nonNegativeInteger',
    'minimum': 0,
    'exclusiveMinimum': false
}
```

##xs:nonPositiveInteger
###Restrictive
```
{
    'type': 'integer',
    'xsdType': 'nonPositiveInteger',
    'maximum': 0,
    'exclusiveMaximum': false
}
```

###Non-Restrictive
```
{
    'type': 'integer',
    'xsdType': 'nonPositiveInteger',
    'maximum': 0,
    'exclusiveMaximum': false
}
```

##xs:normalizedString
###Restrictive
```
{
    'type': 'string'
    'xsdType': 'normalizedString',
}
```

###Non-Restrictive
```
{
    'type': 'string'
    'xsdType': 'normalizedString',
}
```

##xs:positiveInteger
###Restrictive
```
{
    'type': 'integer',
    'xsdType': 'positiveInteger',
    'minimum': 0,
    'exclusiveMinimum': true
}
```

###Non-Restrictive
```
{
    'type': 'integer',
    'xsdType': 'positiveInteger',
    'minimum': 0,
    'exclusiveMinimum': true
}
```

##xs:QName
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'QName',
    'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*: [A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'QName'
}
```

##xs:short
###Restrictive
```
{
    'type': 'integer',
    'xsdType': 'short',
    'minimum': -32768,
    'maximum': 32767,
    'exclusiveMinimum': false,
    'exclusiveMaximum': false
}
```

###Non-Restrictive
```
{
    'type': 'integer',
    'xsdType': 'short'
}
```

##xs:string
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'string'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'string'
}
```

##xs:time
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'time',
    'pattern': '^([01]\d|2[0-3]):([0-5]\d)(?::([0-5]\d)(.(\d{3}))?)?$'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'time',
    'pattern': '^([01]\d|2[0-3]):([0-5]\d)(?::([0-5]\d)(.(\d{3}))?)?$'
}
```

##xs:token
###Restrictive
```
{
    'type': 'string',
    'xsdType': 'token'
}
```

###Non-Restrictive
```
{
    'type': 'string',
    'xsdType': 'token'
}
```

##xs:unsignedByte
###Restrictive
```
{
    'type': 'integer',
    'xsdType': 'unsignedByte',
    'minimum': 0,
    'maximum': 255,
    'exclusiveMinimum': false,
    'exclusiveMaximum': false
}
```

###Non-Restrictive
```
{
    'type': 'integer',
    'xsdType': 'unsignedByte',
    'minimum': 0,
    'exclusiveMinimum': false
}
```

##xs:unsignedInt
###Restrictive
```
{
    'type': 'integer',
    'xsdType': 'unsignedInt',
    'minimum': 0,
    'maximum': 4294967295,
    'exclusiveMinimum': false,
    'exclusiveMaximum': false
}
```

###Non-Restrictive
```
{
    'type': 'integer',
    'xsdType': 'unsignedInt',
    'minimum': 0,
    'exclusiveMinimum': false
}
```

##xs:unsignedLong
###Restrictive
```
{
    'type': 'integer',
    'xsdType': 'unsignedLong',
    'minimum': 0,
    'maximum': 18446744073709551615,
    'exclusiveMinimum': false,
    'exclusiveMaximum': false
}
```

###Non-Restrictive
```
{
    'type': 'integer',
    'xsdType': 'unsignedLong',
    'minimum': 0,
    'exclusiveMinimum': false
}
```

##xs:unsignedShort
###Restrictive
```
{
    'type': 'integer',
    'xsdType': 'unsignedShort',
    'minimum': 0,
    'maximum': 65535,
    'exclusiveMinimum': false,
    'exclusiveMaximum': false
}
```

###Non-Restrictive
```
{
    'type': 'integer',
    'xsdType': 'unsignedShort',
    'minimum': 0,
    'exclusiveMinimum': false
}
```
