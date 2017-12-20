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
            element { 'child' } { 
                element { 'name' } {
                    $child
                },
                fn:serialize(
                    xsd2json:run(fn:doc(fn:concat('xsd/', $child))//xs:schema, map { }),
                    <output:serialization-parameters>
                        <output:method value="json"/>
                        <output:indent value="yes"/>
                    </output:serialization-parameters>
                )
                
            } 
        else
            ()
}
