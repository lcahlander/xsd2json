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
    order by $child
    return 
        if (fn:contains($child, "recursive"))
        then ()
        else
        if (fn:ends-with($child, '.xsd'))
        then
            let $name := fn:substring-before($child, '.xsd')
            let $outfile := fn:concat($name, '.json')
            let $generated := xsd2json:run(fn:doc(fn:concat('xsd/', $child))//xs:schema, map { 
            $xsd2json:KEEP_NAMESPACES: fn:true(), 
            $xsd2json:SCHEMAID: $outfile,
            $xsd2json:RESTRICTIVE: fn:true()
        })
            let $toTest := fn:json-doc(fn:concat('json-draft-4/', $name, '.json'))
            let $option := map {'method': 'json', 'use-character-maps' : map { '/' : '/' }, 'indent': fn:true()}
            return
            element { 'child' } { 
                element { 'name' } { $name },
                element { 'outfile' } { $outfile },
                element { 'compared' } {  fn:deep-equal($generated, $toTest) },
                element { 'generated' } { fn:serialize($generated, $option) },
                element { 'test' } { fn:serialize($toTest, $option) }
            } 
        else
            ()
}
