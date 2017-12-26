xquery version "3.1";

import module namespace xsd2json="http://easymetahub.com/ns/xsd2json" at "../xsd2json.xqy";

declare namespace file="http://expath.org/ns/file";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization"; 
declare namespace xs="http://www.w3.org/2001/XMLSchema";

declare option output:method "xml";
declare option output:indent "yes";

element { 'xsd' } { 
    for $child in file:list(fn:concat(file:base-dir(), 'xsd')) 
    return 
        if (fn:ends-with($child, '.xsd'))
        then
            let $generated := xsd2json:run(fn:doc(fn:concat('xsd/', $child))//xs:schema, map { })
            let $toTest := fn:json-doc(fn:concat('json-draft-4/', fn:substring-before($child, '.xsd'), '.json'))
            let $option := map {'method': 'json', 'use-character-maps' : map { '/' : '/' }, 'indent': fn:true()}
            return
            element { 'child' } { 
                element { 'name' } { $child },
                element { 'compared' } {  fn:deep-equal($generated, $toTest) },
                element { 'generated' } { fn:serialize($generated, $option) },
                element { 'test' } { fn:serialize($toTest, $option) }
            } 
        else
            ()
}
