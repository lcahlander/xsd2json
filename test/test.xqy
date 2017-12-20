xquery version "3.1";

import module namespace xsd2json="http://easymetahub.com/ns/xsd2json" at "../xsd2json.xqy";

declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization"; 
declare namespace xs="http://www.w3.org/2001/XMLSchema";

declare option output:method "json";
declare option output:indent "yes";

xsd2json:run(.//xs:schema, map { } )
