xquery version "3.1";

import module namespace xsd2json="http://easymetahub.com/ns/xsd2json" at "xsd2json.xqy";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization"; 
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace xs="http://www.w3.org/2001/XMLSchema";

declare option output:method "text";

declare variable $keepNamespaces external := fn:false();
declare variable $schemaId external := 'output.json#';
declare variable $option := map {'method': 'json', 'use-character-maps' : map { '/' : '/' }, 'indent': fn:true()};

fn:serialize(xsd2json:run(./xs:schema, map { } ), $option)
