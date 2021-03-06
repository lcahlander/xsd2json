xquery version "3.1";
(:~
This XQuery library module transforms an XML Schema to a JSON Schema equivalent.

NOTE: This is a work in progress.  I would appreciate any comments to make it more robust.

To execute the transformation, place the followin in another XQuery module.

xquery version "3.1";
import module namespace xsd2json="http://easymetahub.com/ns/xsd2json" at "xsd2json.xqy";

declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization"; 
declare namespace xs="http://www.w3.org/2001/XMLSchema";

declare option output:method "json";
declare option output:indent "yes";

xsd2json:run(.//xs:schema, map { } )

 :)
module namespace xsd2json="http://easymetahub.com/ns/xsd2json";

declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace xs="http://www.w3.org/2001/XMLSchema";

declare variable $xsd2json:RESTRICTIVE := 'restrictive';
declare variable $xsd2json:SCHEMAID := 'schemaId';
declare variable $xsd2json:KEEP_NAMESPACES := 'keepNamespaces';
declare variable $xsd2json:DATATYPES := ( 'string', 'normalizedString', 'token', 'base64Binary', 'hexBinary', 'integer', 'positiveInteger', 'negativeInteger', 'nonNegativeInteger', 'nonPositiveInteger', 'long', 'unsignedLong', 'int', 'unsignedInt', 'short', 'unsignedShort', 'byte', 'unsignedByte', 'decimal', 'float', 'double', 'duration', 'dateTime', 'date', 'time', 'gYear', 'gYearMonth', 'gMonth', 'gMonthDay', 'gDay', 'Name', 'QName', 'NCName', 'anyURI', 'language', 'ID', 'IDREF', 'IDREFS', 'ENTITY', 'ENTITIES', 'NMTOKEN', 'NMTOKENS', 'anySimpleType', 'anyType', 'token', 'decimal', 'boolean' );

declare function xsd2json:prefix-type($bases as map(*), $attr) {
    let $value := xs:string($attr)
    let $prefixed := fn:contains($value, ':')
    return
        if ($prefixed)
        then
            if (map:get($bases, fn:substring-before($value, ':')) = "http://www.w3.org/2001/XMLSchema")
            then  attribute { $attr/name() } { 'xs:' || fn:substring-after($value, ':') }
            else $attr
        else 
            if (map:get($bases, '') = "http://www.w3.org/2001/XMLSchema")
            then 
                if ($xsd2json:DATATYPES = $value)
                then attribute { $attr/name() } { 'xs:' || $value }
                else $attr
            else $attr
};

declare function xsd2json:change-element-ns-deep
  ( $nodes as node()* ,
    $newns as xs:string ,
    $prefix as xs:string )  as node()* {

  for $node in $nodes
  let $bases := map:merge((
                    for $prefix in fn:in-scope-prefixes($node/ancestor-or-self::xs:schema)
                    return map:entry($prefix, xs:string(fn:namespace-uri-for-prefix($prefix, $node/ancestor-or-self::xs:schema)))
                ))
  return if ($node instance of element())
         then (element
               {QName ($newns,
                          concat($prefix,
                                    if ($prefix = '')
                                    then ''
                                    else ':',
                                    local-name($node)))}
               {
                for $attr in $node/@*
                return
                    switch ($attr/name())
                    case 'type' return xsd2json:prefix-type($bases, $attr)
                    case 'base' return xsd2json:prefix-type($bases, $attr)
                    default return $attr
                    ,
                xsd2json:change-element-ns-deep($node/node(),
                                           $newns, $prefix)})
         else if ($node instance of document-node())
         then xsd2json:change-element-ns-deep($node/node(),
                                           $newns, $prefix)
         else $node
 } ;
(:~
 :  This is called to transform an XML Schema (and imported + included) to a JSON Schema.
 :  
 :  The options that are supported are:
 :  
 :      'keepNamespaces' - set to true if keeping prefices in the property names 
 :                         is required otherwise prefixes are eliminated.
 :      'schemaId'       - the name of the schema
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param $base the base XML Schema to be transformed
 : @param $options Options to control the transformation
 :)
declare function xsd2json:run($base as node(), $options as map(*)) as map(*) {
let $m := map:merge((xsd2json:parse-level('target', $base, ()), $options))
let $base-w-includes := map:get($m, 'target')
let $referred-to-element-names := fn:distinct-values($base-w-includes//xs:element/@ref/string())
let $root-elements := $base-w-includes/xs:element[fn:not(./@name = $referred-to-element-names)]

return 
    map:merge((
    map:entry('id', if (map:contains($options, $xsd2json:SCHEMAID)) then map:get($options, $xsd2json:SCHEMAID) || '#' else 'output.json#'),
    map:entry('$schema', 'http://json-schema.org/draft-04/schema#'),
    map:entry('version', '0.0.1'),
    if (($base-w-includes/xs:complexType[@name], $base-w-includes/xs:simpleType[@name]))
    then
        (
            map:entry('type', 'object'),
            map:entry(
                'definitions', 
                map:merge((
                    for $element in $base-w-includes/xs:complexType[@name]
                    return xsd2json:complexType($element, map:merge((map:entry('definitions', fn:true()), $m))),
                    for $element in $base-w-includes/xs:simpleType[@name]
                    return xsd2json:simpleType($element, map:merge((map:entry('definitions', fn:true()), $m)))
                ))
            )
        )
    else 
        (),
    if ((fn:count($root-elements) eq 1) and fn:not(($base-w-includes/xs:complexType[@name], $base-w-includes/xs:simpleType[@name])))
    then
        let $element := $root-elements
        let $documentation := ($base-w-includes/xs:annotation/xs:documentation, $element/xs:annotation/xs:documentation, $element/xs:complexType/xs:annotation/xs:documentation)
        return
    (
        xsd2json:documentation($documentation, map { }),
        if ($element/@type)
            then xsd2json:element-type($element, map:merge(($m, map:entry('noDoc', fn:true()))))
        else (),
        xsd2json:passthru($element, map:merge(($m, map:entry('noDoc', fn:true())))),
        map:entry('additionalProperties', fn:ends-with($element/@type, 'anyType'))
    )
    else if (fn:count($root-elements) = 0)
    then
        map:merge((
            xsd2json:documentation($base-w-includes/xs:annotation/xs:documentation, map { }),
            map:entry('additionalProperties', fn:false()),
            map:entry('type', 'object')
        ))
    else if (fn:count($root-elements) gt 1)
    then
    (
        xsd2json:documentation($base-w-includes/xs:annotation/xs:documentation, map { }),
        map:entry(
            'oneOf', 
            array { 
                for $element in $root-elements
                return 
                    map:merge((
                        map:entry('properties', xsd2json:element($element, $m)),
                        map:entry('additionalProperties', fn:false()),
                        map:entry('type', 'object'),
                        map:entry(
                            'required', 
                            array { 
                                $element/@name/string() 
                            })
                    ))
            }
        )
    )
    else
    (
        xsd2json:documentation($base-w-includes/xs:annotation/xs:documentation, map { }),
        for $element in $root-elements
        return 
            map:merge((
                map:entry('properties', xsd2json:element($element, $m)),
                map:entry('additionalProperties', fn:false()),
                map:entry('type', 'object'),
                map:entry(
                    'required', 
                    array { 
                        $element/@name/string() 
                    })
            ))
    )
))};

(:~
 :
 : Find a loaded schema based on the prefix of the QName.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $qname the name of the item used to locate the schema
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:schema-from-qname($node as node(), $qname as xs:string, $model as map(*)) as node() {
    let $ancestor := $node/ancestor::xs:schema
    let $retval :=
        if (fn:contains($qname, ':'))
        then 
            let $prefix := fn:substring-before($qname, ':')
            let $postfix := fn:substring-after($qname, ':')
            let $ns := map:get($model, $prefix)
            let $s := if (fn:exists($ns)) 
                      then map:get($model, $ns) 
                      else () 
            return 
                if (fn:exists($s)) 
                then $s 
                else $ancestor 
        else $ancestor
    return ($retval, map:get($model, 'target'))[1]
};

declare function xsd2json:is-xsd-datatype($name as xs:string) as xs:boolean {
    try {
        let $qname as xs:QName := xs:QName($name)
        return (fn:namespace-uri-from-QName($qname) eq "http://www.w3.org/2001/XMLSchema")
    } catch * {
        let $prefix := fn:substring-before($name, ':')
        return (('xs', 'xsd') = $prefix)
    }
};

(:~
 :
 : Find prefix of the QName.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $qname the name of the item used to locate the schema
 :)
declare function xsd2json:prefix-from-qname($qname as xs:string) as xs:string? {
    try {
        fn:local-name-from-QName(xs:QName($qname))
    } catch * {
        fn:substring-before($qname, ':')
    }
};

(:~
 :
 : Find postfix of the QName.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $qname the name of the item used to locate the schema
 :)
declare function xsd2json:postfix-from-qname($qname as xs:string) as xs:string? {
    try {
        fn:local-name-from-QName(xs:QName($qname))
    } catch * {
        if (fn:contains($qname, ':')) 
        then fn:substring-after($qname, ':') 
        else $qname
    }
};

(:~
 :
 : Find a loaded schema based on the ref attribute of the node.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $qname the name of the item used to locate the schema
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:schema-from-ref($node as node(), $model as map(*)) as node() {
    xsd2json:schema-from-qname($node, $node/@ref, $model)
};

(:~
 :
 : Find postfix from the ref attribute of the node.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $qname the name of the item used to locate the schema
 :)
declare function xsd2json:postfix-from-ref($node as node()) as xs:string? {
    xsd2json:postfix-from-qname($node/@ref)
};

(:~
 :
 : Copy of the FunctX method of the same name.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $arg the string to trim
 :)
declare function xsd2json:trim( $arg as xs:string? )  as xs:string {

   replace(replace($arg,'\s+$',''),'^\s+','')
 } ;
 
(:~
 :
 : Copy of the FunctX method of the same name.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $arg the string to trim
 : @param   $regex the pattern to match
 :)
declare function xsd2json:substring-before-last-match($arg as xs:string?, $regex as xs:string) as xs:string? {
    
    replace($arg, concat('^(.*)', $regex, '.*'), '$1')
};

(:~
 :
 : Load an XML Schema from the listed path.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $path the path to the XML Schema
 :)
declare function xsd2json:loadSchema($path as xs:string) {
    try {
        xsd2json:change-element-ns-deep(fn:doc($path)/xs:schema, "http://www.w3.org/2001/XMLSchema", "xs")
    } catch * {
        'Falied to load ' || $path
    }
};

(:~
 :
 : Lists all of the prefixes for the namespaces in the set of XML Schemas.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $uri
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:prefixes-from-namespace($uri as xs:string?, $model as map(*)) as xs:string* {
     map:for-each(
        $model, 
        function($k, $v) { 
            try { 
                if (fn:starts-with($v, 'http:')) 
                then $k 
                else () 
            } catch * { 
                () 
            } 
        } 
    )
};

declare function xsd2json:parse-level($ns as xs:string, $base, $namespaces as xs:string*) as map(*) {
    let $baseuri := fn:base-uri($base)
    let $cleansed-base := xsd2json:change-element-ns-deep($base, "http://www.w3.org/2001/XMLSchema", "xs")
    let $included := 
                        try {
                            for $include in $cleansed-base/xs:include
                            let $loadPath := fn:concat(xsd2json:substring-before-last-match(xs:string($baseuri), '/'), '/', $include/@schemaLocation/string())
                            return
                                xsd2json:change-element-ns-deep(fn:doc($loadPath)//xs:schema/node(), "http://www.w3.org/2001/XMLSchema", "xs")
                        } catch * {
                            ()
                        }
    return
        map:merge((
        map:entry(xs:string($ns), element { $cleansed-base/name() } { $cleansed-base/@*, $cleansed-base/node(), $included }),
        try {
            for $prefix in fn:in-scope-prefixes($base)
            let $trace := fn:trace($prefix, 'Prefix loaded: ')
            return (
                map:entry($prefix, fn:namespace-uri-for-prefix($prefix, $base))
                )
        } catch * {
            ()
        },
        try {
            for $import in $base//xs:import
            let $loadPath := fn:concat(xsd2json:substring-before-last-match(xs:string($baseuri), '/'), '/', $import/@schemaLocation/string())
            return
                if ($namespaces = $import/@namespace/string())
                then map { }
                else 
                xsd2json:parse-level(
                $import/@namespace/string(),
                xsd2json:loadSchema($loadPath), ($namespaces, $import/@namespace/string()))
        } catch * {
            ()
        }
            
        ))
};

(:~
 : The most effective way to use the typeswitch expression to transform XML is to create a series of XQuery functions. 
 : In this way, we can cleanly separate the major actions of the transformation into modular functions. (In fact, 
 : the library of functions can be saved into an XQuery library module, which can then be reused by other XQueries.) 
 : The "magic" of this typeswitch-style transformation is that once you understand the basic pattern and structure of
 : the functions, you can adapt them to your own data. You'll find that the structure is so modular and straightforward
 : that it's even possible to teach others the basics of the pattern in a short period of time and empower them 
 : to maintain and update the transformation rules themselves.
 :
 : The first function in our module is where the typeswitch expression is located. This function is conventionally called 
 : the "dispatch" function
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)

declare function xsd2json:dispatch($node as node()?, $model as map(*)) as map(*) {
    if ($node) then 
    typeswitch($node) 
        case element(xs:all) return xsd2json:all($node, $model)
        case element(xs:annotation) return xsd2json:annotation($node, $model)
        case element(xs:any) return xsd2json:any($node, $model)
        case element(xs:anyAttribute) return xsd2json:anyAttribute($node, $model)
        case element(xs:appinfo) return xsd2json:appinfo($node, $model)
        case element(xs:attribute) return xsd2json:attribute($node, $model)
        case element(xs:attributeGroup) return xsd2json:attributeGroup($node, $model)
        case element(xs:choice) return xsd2json:choice($node, $model)
        case element(xs:complexContent) return xsd2json:complexContent($node, $model)
        case element(xs:complexType) return xsd2json:complexType($node, $model)
        case element(xs:documentation) return xsd2json:documentation($node, $model)
        case element(xs:element) return xsd2json:element($node, $model)
        case element(xs:enumeration) return map { }
        case element(xs:extension) return xsd2json:extension($node, $model)
        case element(xs:field) return xsd2json:field($node, $model)
        case element(xs:fractionDigits) return xsd2json:fractionDigits($node, $model)
        case element(xs:group) return xsd2json:group($node, $model)
        case element(xs:import) return xsd2json:import($node, $model)
        case element(xs:include) return xsd2json:include($node, $model)
        case element(xs:key) return xsd2json:key($node, $model)
        case element(xs:keyref) return xsd2json:keyref($node, $model)
        case element(xs:length) return xsd2json:length($node, $model)
        case element(xs:list) return xsd2json:list($node, $model)
        case element(xs:maxExclusive) return xsd2json:maxExclusive($node, $model)
        case element(xs:maxInclusive) return xsd2json:maxInclusive($node, $model)
        case element(xs:maxLength) return xsd2json:maxLength($node, $model)
        case element(xs:minExclusive) return xsd2json:minExclusive($node, $model)
        case element(xs:minInclusive) return xsd2json:minInclusive($node, $model)
        case element(xs:minLength) return xsd2json:minLength($node, $model)
        case element(xs:notation) return xsd2json:notation($node, $model)
        case element(xs:pattern) return xsd2json:pattern($node, $model)
        case element(xs:redefine) return xsd2json:redefine($node, $model)
        case element(xs:restriction) return xsd2json:restriction($node, $model)
        case element(xs:schema) return xsd2json:schema($node, $model)
        case element(xs:selector) return xsd2json:selector($node, $model)
        case element(xs:sequence) return xsd2json:sequence($node, $model)
        case element(xs:simpleContent) return xsd2json:simpleContent($node, $model)
        case element(xs:simpleType) return xsd2json:simpleType($node, $model)
        case element(xs:totalDigits) return xsd2json:totalDigits($node, $model)
        case element(xs:union) return xsd2json:union($node, $model)
        case element(xs:unique) return xsd2json:unique($node, $model)
        case element(xs:whiteSpace) return xsd2json:whiteSpace($node, $model)
        default return xsd2json:passthru($node, $model) 
    else map { }
};

(:~
 :
 : The passthru() function recurses through a given node's children, handing each of them back to the main typeswitch operation.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:passthru($node as node()?, $model as map(*)) as map(*) {
    map:merge(
        if ($node) 
        then 
            if ($node/xs:annotation/xs:documentation)
            then
                (
                    xsd2json:documentation($node/xs:annotation/xs:documentation, $model),
                    for $cnode in $node/* 
                    return xsd2json:dispatch($cnode, map:merge(($model, map { 'noDoc': fn:true() }))) 
                )
            else
                for $cnode in $node/* 
                return xsd2json:dispatch($cnode, $model) 
        else () 
    )
};

(:~
 :
 : Used for determining cardinality.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:require-dispatch($node as node()?, $model as map(*)) as xs:string* {
    if ($node) then 
    typeswitch($node) 
        case element(xs:attribute) return xsd2json:require-attribute($node, $model)
        case element(xs:attributeGroup) return xsd2json:require-attributeGroup($node, $model)
        case element(xs:element) return xsd2json:require-element($node, $model)
        case element(xs:complexType) return xsd2json:require-complexType($node, $model)
        default return xsd2json:require-passthru($node, $model) 
    else ()
};

(:~
 :
 : Used for determining cardinality.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:require-passthru($node as node()?, $model as map(*)) as xs:string* {
    if ($node) then for $cnode in $node/* return xsd2json:require-dispatch($cnode, $model) else ()
};

(:~
 :
 : Used for determining cardinality.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:require-attribute($node as node(), $model as map(*)) as xs:string? {
    (: Attributes:

 : Child Elements:

 :)
    if ($node/@name)
    then 
        if (($node/@minOccurs/fn:number(.) = 1) or ($node[@use = 'required']))
        then '@' || $node/@name/string(.)
        else ()
    else ()
};

(:~
 :
 : Used for determining cardinality.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:require-attributeGroup($node as node(), $model as map(*)) as xs:string* {
    (: Attributes:

 : Child Elements:

 :)
    if ($node/@name)
    then 
        xsd2json:require-passthru($node, $model)
    else 
        let $postfix := xsd2json:postfix-from-ref($node)
        let $schema := xsd2json:schema-from-ref($node, $model)
        return
            if ($schema//xs:attributeGroup[@name = $postfix])
            then 
                let $attribute := $schema//xs:attributeGroup[@name = $postfix]
                return
                    if ($attribute)
                    then xsd2json:require-attributeGroup($attribute, $model)
                    else fn:error(xs:QName('xsd2json:err057'), 'missing attributeGroup', $postfix)
            else ()
};

(:~
 :
 : Used for determining cardinality.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:require-complexType($node as node(), $model as map(*)) as xs:string? {
    (: Attributes:

 : Child Elements:

 :)
    ()
};

(:~
 :
 : Used for determining cardinality.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:require-element($node as node(), $model as map(*)) as xs:string? {
    (: Attributes:

 : Child Elements:

 :)
    if ($node/@name)
    then 
        if ($node/@minOccurs/fn:number(.) = 0)
        then ()
        else $node/@name/string(.)
    else if ($node/@ref)
    then 
        if ($node/@minOccurs/fn:number(.) = 0)
        then ()
        else fn:substring-after($node/@ref/string(.), ':')
    else ()
};

(:~
 :
 : Used for determining cardinality.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:maxOccurs-dispatch($node as node()?, $model as map(*)) as map(*) {
    if ($node) then 
    typeswitch($node) 
        case element(xs:element) return xsd2json:maxOccurs-element($node, $model)
        default return xsd2json:maxOccurs-passthru($node, $model) 
    else map { }
};

(:~
 :
 : Used for determining cardinality.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:maxOccurs-passthru($node as node()?, $model as map(*)) as map(*) {
    map:merge(if ($node) then for $cnode in $node/* return xsd2json:maxOccurs-dispatch($cnode, $model) else ())
};

(:~
 :
 : Used for determining cardinality.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:maxOccurs-element($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    if ($node/@name)
    then
        let $count := 
            if ($node/@maxOccurs)
            then
                if ($node/@maxOccurs/fn:string(.) = 'unbounded') 
                then 999999999999999
                else xs:integer($node/@maxOccurs)
            else 1
        let $preceding-count := 
            for $pnode in $node/following-sibling::xs:element[@name = $node/@name]
            return 
                if ($pnode/@maxOccurs)
                then
                    if ($pnode/@maxOccurs/fn:string(.) = 'unbounded') 
                    then 999999999999999
                    else xs:integer($pnode/@maxOccurs)
                else 1
        let $total-count := fn:sum(($count, $preceding-count), 0)
        return 
            map:entry($node/@name/string(.), if ($total-count ge 999999999999999) then 'unbounded' else xs:string($total-count))
    else
        let $count := 
            if ($node/@maxOccurs)
            then
                if ($node/@maxOccurs/fn:string(.) = 'unbounded') 
                then 999999999999999
                else xs:integer($node/@maxOccurs)
            else 1
        let $preceding-count := 
            for $pnode in $node/following-sibling::xs:element[@ref = $node/@ref]
            return 
                if ($pnode/@maxOccurs)
                then
                    if ($pnode/@maxOccurs/fn:string(.) = 'unbounded') 
                    then 999999999999999
                    else xs:integer($pnode/@maxOccurs)
                else 1
        let $total-count := fn:sum(($count, $preceding-count), 0)
        return 
            map:entry($node/@ref/string(.), if ($total-count ge 999999999999999) then 'unbounded' else xs:string($total-count))
};

(:~
 :
 : Used for determining cardinality.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:minOccurs-dispatch($node as node()?, $model as map(*)) as map(*) {
    if ($node) then 
    typeswitch($node) 
        case element(xs:element) return xsd2json:minOccurs-element($node, $model)
        case element(xs:attribute) return xsd2json:minOccurs-attribute($node, $model)
        case element(xs:attributeGroup) return xsd2json:minOccurs-attributeGroup($node, $model)
        default return xsd2json:minOccurs-passthru($node, $model) 
    else map { }
};

(:~
 :
 : Used for determining cardinality.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:minOccurs-passthru($node as node()?, $model as map(*)) as map(*) {
    map:merge(if ($node) then for $cnode in $node/* return xsd2json:minOccurs-dispatch($cnode, $model) else ())
};

(:~
 :
 : Used for determining cardinality.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:minOccurs-element($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    map:merge((
        if ($node/@name)
        then
            let $count := 
                if ($node/@minOccurs)
                then xs:integer($node/@minOccurs)
                else 1
            let $preceding-count := 
                for $pnode in $node/following-sibling::xs:element[@name = $node/@name]
                return 
                    if ($pnode/@minOccurs)
                    then xs:integer($pnode/@minOccurs)
                    else 1
            let $total-count := fn:sum(($count, $preceding-count), 0)
            return 
                map:entry($node/@name/string(.), $total-count)
        else
            let $count := 
                if ($node/@minOccurs)
                then xs:integer($node/@minOccurs)
                else 1
            let $preceding-count := 
                for $pnode in $node/following-sibling::xs:element[@ref = $node/@ref]
                return 
                    if ($pnode/@minOccurs)
                    then xs:integer($pnode/@minOccurs)
                    else 1
            let $total-count := fn:sum(($count, $preceding-count), 0)
            return 
                map:entry($node/@ref/string(.), $total-count),
        for $attributeGroup in $node/xs:attributeGroup
        return xsd2json:minOccurs-attributeGroup($attributeGroup, $model),
        for $attribute in $node/xs:attribute
        return xsd2json:minOccurs-attribute($attribute, $model)
    ))
};

(:~
 :
 : Used for determining cardinality.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:minOccurs-attributeGroup($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    map:merge((
        for $attribute in $node/xs:attribute
        return xsd2json:minOccurs-attribute($attribute, $model)
    ))
};

(:~
 :
 : Used for determining cardinality.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:minOccurs-attribute($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    let $count := 
        if (($node/@minOccurs/fn:number(.) = 1) or ($node[@use = 'required']))
        then 1
        else 0
    return 
    if ($node/@name)
    then map:entry('@' || $node/@name/string(.), $count)
    else map:entry('@' || $node/@ref/string(.), $count)
};

(:~
 :
 : The all element specifies that the child elements can appear in any order.  
 : Since, in JSON, the order does not matter, call xsd2json:sequence.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 : @see xsd2json:sequence()
 :)
declare function xsd2json:all($node as node(), $model as map(*)) as map(*) {
    (: Attributes:
:       minOccurs
 : Child Elements:

 :)
    xsd2json:sequence($node, $model)
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:extension($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    if (xsd2json:is-xsd-datatype($node/@base))
    then 
        if ($node/xs:attribute)
        then
            let $minOccurs := xsd2json:minOccurs-passthru($node, $model)
            let $required := for $key in map:keys($minOccurs)
                             order by $key
                             return if (map:get($minOccurs, $key) gt 0) then $key else ()
            return
            map:merge((
                map:entry('type', 'object'),
                map:entry(
                    'properties',
                    map:merge((
                        map:entry(
                            'value', 
                            xsd2json:dataType($node/@base, $model)
                        ), 
                        xsd2json:passthru($node, $model)
                    ))
                ),
                map:entry('additionalProperties', fn:false()),
                map:entry('required', array { for $item in ('value', $required) order by $item return $item } )
             ))
        else
            map:merge((
                xsd2json:dataType($node/@base, $model), 
                xsd2json:passthru($node, $model)
             ))
    else
		let $postfix := xsd2json:postfix-from-qname($node/@base)
		let $schema := xsd2json:schema-from-qname($node, $node/@base, $model)
		let $content :=
            if ($schema//xs:complexType[@name = $postfix])
            then 
                let $ct := $schema//xs:complexType[@name = $postfix]
                return
                    if ($ct)
                    then map:get(xsd2json:complexType($ct, $model), $postfix)
                    else fn:error(xs:QName('xsd2json:err057'), 'missing complexType', $postfix)
            else if ($schema//xs:simpleType[@name = $postfix])
            then 
                let $ct := $schema//xs:simpleType[@name = $postfix]
                return
                    if ($ct)
                    then xsd2json:simpleType($ct, $model)
                    else fn:error(xs:QName('xsd2json:err057'), 'missing simpleType', $postfix)
            else if ($schema//xs:restriction[@name = $postfix])
            then 
                let $ct := $schema//xs:restriction[@name = $postfix]
                return
                    if ($ct)
                    then xsd2json:restriction($ct, $model)
                    else fn:error(xs:QName('xsd2json:err057'), 'missing restriction', $postfix)
            else if ($schema//xs:extension[@name = $postfix])
            then 
                let $ct := $schema//xs:extension[@name = $postfix]
                return
                    if ($ct)
                    then xsd2json:extension($ct, $model)
                    else fn:error(xs:QName('xsd2json:err057'), 'missing extension', $postfix)
            else map { }
        return 
            map:merge((
                for $key in map:keys($content)
                return 
                    map:entry(
                        $key,
                        if ($key = 'properties')
                        then map:merge((
                                map:get($content, $key),
                                if ($node/xs:choice) 
                                then 
                                    xsd2json:choice($node/xs:choice, $model)
                                else if ($node/xs:all) 
                                then 
                                    for $cnode in $node/xs:all/node()
                                    return xsd2json:passthru($cnode, $model) 
                                else
                                    xsd2json:passthru($node, $model)
                            ))
                        else map:get($content, $key)
                    )
            ))
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:annotation($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    map:merge(xsd2json:passthru($node, $model))
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:any($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    xsd2json:passthru($node, $model)
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:anyAttribute($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    xsd2json:passthru($node, $model)
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:appinfo($node as node(), $model as map(*)) as map(*) {
    (: Attributes:
:       source
 : Child Elements:

 :)
    xsd2json:passthru($node, $model)
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:attribute($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
        if ($node/@name)
        then 
            if ($node/@type or $node/xs:simpleType/xs:restriction/@base)
            then 
                let $type := ($node/@type/string(), $node/xs:simpleType/xs:restriction/@base/string(), 'string')[1]
                return
                if (xsd2json:is-xsd-datatype($type))
                then 
                    map:merge((
                        map:entry(
                            '@' || $node/@name/string(), 
                            map:merge((
                                    if ($node/@fixed)
                                    then 
                                        (
                                            map:entry(
                                                'enum', 
                                                array { 
                                                    switch (xsd2json:dataType-basic($type))
                                                    case 'integer' return xs:integer($node/@fixed) 
                                                    case 'number' return xs:decimal($node/@fixed) 
                                                    case 'boolean' return xs:boolean($node/@fixed) 
                                                    default return xs:string($node/@fixed) 
                                                }
                                            )
                                        )
                                    else (),
                                    if ($node/@default)
                                    then
                                        (
                                            map:entry(
                                                'default', 
                                                switch (xsd2json:dataType-basic($type))
                                                case 'integer' return xs:integer($node/@default) 
                                                case 'number' return xs:decimal($node/@default) 
                                                case 'boolean' return xs:boolean($node/@default) 
                                                default return xs:string($node/@default) 
                                            )
                                        )
                                    else
                                        (),
                                    map:entry('isAttribute', fn:true()),
                                    xsd2json:dataType($type, $model), 
                                    xsd2json:passthru($node, $model)
                                    ))
                        )
                     ))
                else
                    let $postfix := xsd2json:postfix-from-qname($node/@type)
                    let $schema := xsd2json:schema-from-qname($node, $node/@type, $model)
                    return
                        if ($schema//xs:simpleType[@name = $postfix])
                        then 
                            let $ct := $schema//xs:simpleType[@name = $postfix]
                            return
                                if ($ct)
                                then 
                                    map:entry(
                                        '@' || $node/@name/string(), 
                                        map:merge((
                                            if ($node/@fixed)
                                            then 
                                                (
                                                    map:entry(
                                                        'enum', 
                                                        array { 
                                                            switch (xsd2json:simpleType-base($node, $model))
                                                            case 'integer' return xs:integer($node/@fixed) 
                                                            case 'number' return xs:decimal($node/@fixed) 
                                                            case 'boolean' return xs:boolean($node/@fixed) 
                                                            default return xs:string($node/@fixed) 
                                                        }
                                                    )
                                                )
                                            else (),
                                            if ($node/@default)
                                            then
                                                (
                                                    map:entry(
                                                        'default', 
                                                        switch (xsd2json:simpleType-base($node, $model))
                                                        case 'integer' return xs:integer($node/@default) 
                                                        case 'number' return xs:decimal($node/@default) 
                                                        case 'boolean' return xs:boolean($node/@default) 
                                                        default return xs:string($node/@default) 
                                                    )
                                                )
                                            else
                                                (),
                                            map:entry('isAttribute', fn:true()), 
                                            xsd2json:simpleType($ct, map:merge(($model, map:entry('noName', fn:true()))))
                                        ))
                                    )
                                else fn:error(xs:QName('xsd2json:err057'), 'missing simpleType', $postfix)
                        else map:merge(())
                        
            else map:entry('@' || $node/@name/string(), map:merge(xsd2json:passthru($node, $model)))
        else 
            let $postfix := xsd2json:postfix-from-ref($node)
            let $schema := xsd2json:schema-from-ref($node, $model)
            return
                if ($schema//xs:attribute[@name = $postfix])
                then 
                    let $attribute := $schema//xs:attribute[@name = $postfix]
                    return
                        if ($attribute)
                        then xsd2json:attribute($attribute, $model)
                        else fn:error(xs:QName('xsd2json:err057'), 'missing element', $postfix)
                else map:entry('@' || $node/@ref/string(), map:merge(()))
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:attributeGroup($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    if ($node/@name)
    then 
        xsd2json:passthru($node, $model)
    else 
        let $postfix := xsd2json:postfix-from-ref($node)
        let $schema := xsd2json:schema-from-ref($node, $model)
        return
            if ($schema//xs:attributeGroup[@name = $postfix])
            then 
                let $attribute := $schema//xs:attributeGroup[@name = $postfix]
                return
                    if ($attribute)
                    then xsd2json:attributeGroup($attribute, $model)
                    else fn:error(xs:QName('xsd2json:err057'), 'missing attributeGroup', $postfix)
            else map { }
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:choice($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    let $enhance := map:put($model, 'noDoc', fn:false())
    let $oneof :=    
        map:entry(
            'oneOf', 
            array {
                for $child in $node/*
                return 
                    typeswitch($child)
                    case element(xs:annotation) return ()
                    case element(xs:sequence)
                        return map:merge((xsd2json:sequence($child, $model)))
                    case element(xs:element)
                        return
                            let $required := xsd2json:require-passthru($child, $model)
                            let $maxOccurs := xsd2json:maxOccurs-passthru($child, $model)
                            let $emodel := map:merge(($model, $maxOccurs))
                            let $enhance := map:remove($emodel, 'noDoc')
                            return 
                                map:merge((
                                    map:entry(
                                        'properties', 
                                        xsd2json:element($child, $emodel)
                                    ),
                                    map:entry('additionalProperties', fn:false()),
                                    if (fn:count($required) gt 0) 
                                    then 
                                        map:entry(
                                            'required', 
                                            array { 
                                                for $item in fn:distinct-values($required)
                                                order by $item
                                                return $item 
                                            } 
                                        ) 
                                    else 
                                        ()
                                ))
                    default
                        return
                            xsd2json:passthru($child, $model)
            }
        )
    return
        map:merge((
            if ($node/../local-name() = 'sequence') 
            then 
                map { }
            else 
                (
                    map:entry('properties', map:merge(())),
                    map:entry('additionalProperties', fn:false())
                ),
            $oneof
        ))
};

(:~
 :
 : Overrides any setting on complexType parent.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:complexContent($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    if ($node/xs:extension)
    then xsd2json:extension($node/xs:extension, $model)
    else if ($node/xs:restriction)
    then xsd2json:restriction($node/xs:restriction, $model)
    else map { }
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:complexType($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    let $content := map:merge((
        if ($node/xs:annotation) then xsd2json:annotation($node/xs:annotation, $model) else (),
        if ($node/xs:complexContent)
        then (map:entry('type', 'object'), map:entry('additionalProperties', fn:false()), xsd2json:complexContent($node/xs:complexContent, $model))
        else if ($node/xs:simpleContent)
        then (map:entry('type', 'object'), map:entry('additionalProperties', fn:false()), xsd2json:simpleContent($node/xs:simpleContent, $model))
        else if ($node/xs:sequence)
        then (map:entry('type', 'object'), map:entry('additionalProperties', fn:false()), xsd2json:sequence($node/xs:sequence, $model))
        else if ($node/xs:choice)
        then for $choice in $node/xs:choice return xsd2json:choice($choice, $model)
        else if ($node/xs:all)
        then (map:entry('type', 'object'), map:entry('additionalProperties', fn:false()), xsd2json:all($node/xs:all, $model))
        else if ($node/xs:attribute)
        then 
            (
                map:entry('type', 'object'), 
                map:entry('additionalProperties', fn:false()), 
                if (xsd2json:require-dispatch($node, $model))
                then
                    map:entry(
                        'required',
                        array { 
                            for $item in 
                            xsd2json:require-dispatch($node, $model) 
                            order by $item
                            return $item 
                        }
                    )
                else
                    (),
                map:entry(
                    'properties', 
                    map:merge((
                        for $attr in $node/xs:attribute 
                        return xsd2json:attribute($attr, $model)
                    ))
                )
            )
        else ()
    ))
    return 
        if ($node/@name and map:contains($model, 'definitions'))
        then map:entry($node/@name/string(), $content)
        else $content
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $nodes the current node being processed - possibly multiple
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:documentation($nodes as node()*, $model as map(*)) as map(*) {
    (: Attributes:
:       source
 : Child Elements:

 :)
    let $nl := "&#10;"
    let $params := 
        <output:serialization-parameters 
                xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
            <output:omit-xml-declaration value="yes"/>
            <output:method value="xml"/>
            <output:escape-uri-attributes value="no"/>
        </output:serialization-parameters>
    return
    if (fn:empty($nodes) or map:get($model, 'noDoc'))
    then 
        map { }
    else
        map:entry(
            'description', 
            fn:string-join(
                for $node in $nodes 
                return 
                    if ($node/text() and not($node/*))
                    then xsd2json:trim(xs:string($node))
                    else xsd2json:trim(fn:replace(fn:serialize(xsd2json:change-element-ns-deep($node, '', '')/node(), $params), "&amp;gt;", ">"))
                    ,
                $nl
            )
        )
};

(:~
 :
 : Return the JSON Schema equivalent for the requested XML Schema data type
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $type the name of the XML Schema data type
 : @param   $model - If the map contains the key-value pair 'restrictive' and false then get the non-restrictive type mapping 
 :)
declare function xsd2json:dataType($type as xs:string, $model as map(*)) as map(*) {
    if (map:contains($model, $xsd2json:RESTRICTIVE))
    then 
        if (map:get($model, $xsd2json:RESTRICTIVE))
        then xsd2json:dataType-restrictive($type)
        else xsd2json:dataType-non-restrictive($type)
    else xsd2json:dataType-restrictive($type)
};

(:~
 :
 : Return the restrictive JSON Schema equivalent for the requested XML Schema data type
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $type the name of the XML Schema data type
 :)
declare function xsd2json:dataType-restrictive($type as xs:string) as map(*) {
    let $xsdType := xsd2json:postfix-from-qname($type)
    return
    map:merge((
        switch($xsdType) 
            case 'string' return map {
                'type': 'string'
            }
            case 'normalizedString' return map {
                'type': 'string'
            }
            case 'token' return map {
                'type': 'string'
            }
            case 'base64Binary' return map {
                'type': 'string',
                'pattern': '^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$'
            }
            case 'hexBinary' return map {
                'type': 'string',
                'pattern': '^([0-9a-fA-F]{2})*$'
            }
            case 'integer' return map {
                'type': 'integer'
            }
            case 'positiveInteger' return map {
                'type': 'integer',
                'minimum': 0,
                'exclusiveMinimum': fn:true()
            }
            case 'negativeInteger' return map {
                'type': 'integer',
                'maximum': 0,
                'exclusiveMaximum': fn:true()
            }
            case 'nonNegativeInteger' return map {
                'type': 'integer',
                'minimum': 0,
                'exclusiveMinimum': fn:false()
            }
            case 'nonPositiveInteger' return map {
                'type': 'integer',
                'maximum': 0,
                'exclusiveMaximum': fn:false()
            }
            case 'long' return map {
                'type': 'integer',
                'minimum': -9223372036854775808,
                'maximum': 9223372036854775807,
                'exclusiveMinimum': fn:false(),
                'exclusiveMaximum': fn:false()
            }
            case 'unsignedLong' return map {
                'type': 'integer',
                'minimum': 0,
                'maximum': 18446744073709551615,
                'exclusiveMinimum': fn:false(),
                'exclusiveMaximum': fn:false()
            }
            case 'int' return map {
                'type': 'integer',
                'minimum': -2147483648,
                'maximum': 2147483647,
                'exclusiveMinimum': fn:false(),
                'exclusiveMaximum': fn:false()
            }
            case 'unsignedInt' return map {
                'type': 'integer',
                'minimum': 0,
                'maximum': 4294967295,
                'exclusiveMinimum': fn:false(),
                'exclusiveMaximum': fn:false()
            }
            case 'short' return map {
                'type': 'integer',
                'minimum': -32768,
                'maximum': 32767,
                'exclusiveMinimum': fn:false(),
                'exclusiveMaximum': fn:false()
            }
            case 'unsignedShort' return map {
                'type': 'integer',
                'minimum': 0,
                'maximum': 65535,
                'exclusiveMinimum': fn:false(),
                'exclusiveMaximum': fn:false()
            }
            case 'byte' return map {
                'type': 'integer',
                'minimum': -128,
                'maximum': 127,
                'exclusiveMinimum': fn:false(),
                'exclusiveMaximum': fn:false()
            }
            case 'unsignedByte' return map {
                'type': 'integer',
                'minimum': 0,
                'maximum': 255,
                'exclusiveMinimum': fn:false(),
                'exclusiveMaximum': fn:false()
            }
            case 'decimal' return map {
                'type': 'number'
            }
            case 'float' return map {
                'type': 'number'
            }
            case 'double' return map {
                'type': 'number'
            }
            case 'duration' return map {
                'type': 'string',
                'pattern': '^P(?!$)(\d+Y)?(\d+M)?(\d+W)?(\d+D)?(T(?=\d+[HMS])(\d+H)?(\d+M)?(\d+S)?)?$'
            }
            case 'dateTime' return map {
                  'type': 'string',
                  'pattern': '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))(T((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$'
            }
            case 'date' return map {
                'type': 'string',
                'pattern': '^\d{4}-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])$'
            }
            case 'time' return map {
                'type': 'string',
                'pattern': '^([01]\d|2[0-3]):([0-5]\d)(?::([0-5]\d)(.(\d{3}))?)?$'
            }
            case 'gYear' return map {
                'type': 'integer',
                'minimum': 1,
                'maximum': 9999,
                'exclusiveMinimum': fn:false(),
                'exclusiveMaximum': fn:false()
            }
            case 'gYearMonth' return map {
                'type': 'string',
                'pattern': '^(19|20)\d\d-(0[1-9]|1[012])$'
            }
            case 'gMonth' return map {
                'type': 'integer',
                'minimum': 1,
                'maximum': 12,
                'exclusiveMinimum': fn:false(),
                'exclusiveMaximum': fn:false()
            }
            case 'gMonthDay' return map {
                'type': 'string',
                'pattern': '^(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])$'
            }
            case 'gDay' return map {
                'type': 'integer',
                'minimum': 1,
                'maximum': 31,
                'exclusiveMinimum': fn:false(),
                'exclusiveMaximum': fn:false()
            }
            case 'Name' return map {
                'type': 'string',
                'pattern': '^[:A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9:A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
            }
            case 'QName' return map {
                'type': 'string',
                'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*: [A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
            }
            case 'NCName' return map {
                'type': 'string',
                'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
            }
            case 'anyURI' return map {
                'type': 'string',
                'pattern': '^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?'
            }
            case 'language' return map {
                'type': 'string', 
                'pattern': '^[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*$'
            }
            case 'ID' return map {
                'type': 'string',
                'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
            }
            case 'IDREF' return map {
                'type': 'string',
                'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
            }
            case 'IDREFS' return map {
                'type': 'string',
                'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
            }
            case 'ENTITY' return map {
                'type': 'string',
                'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
            }
            case 'ENTITIES' return map {
                'type': 'array',
                'items': map {
                    'type': 'string',
                    'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
                }
            } 
            case 'NMTOKEN' return map {
                'type': 'string',
                'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
            }
            case 'NMTOKENS' return map {
                'type': 'array',
                'items': map {
                    'type': 'string',
                    'pattern': '^[A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-.0-9A-Z_a-z\u00B7\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*$'
                }
            } 
            
            case 'anySimpleType' return map {
                'oneOf': array {
                    map { 'type': 'integer' },
                    map { 'type': 'string' },
                    map { 'type': 'number' },
                    map { 'type': 'boolean' },
                    map { 'type': 'null' }
                }
            }
            
            case 'anyType' return map { }

            case 'token' return map {                 
                'type': 'string' 
            }

            case 'decimal' return map {                 
                'type': 'number' 
            }
            case 'boolean' return map {
                'type': 'boolean' 
            }
            default return map {
                'type': $type 
            }
    ))
    
};

(:~
 :
 : Return the non-restrictive JSON Schema equivalent for the requested XML Schema data type
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $type the name of the XML Schema data type
 :)
declare function xsd2json:dataType-non-restrictive($type as xs:string) as map(*) {
    let $xsdType := xsd2json:postfix-from-qname($type)
    return
    map:merge((
        switch($xsdType) 
            case 'string' return map {
                'type': 'string'
            }
            case 'normalizedString' return map {
                'type': 'string'
            }
            case 'token' return map {
                'type': 'string'
            }
            case 'base64Binary' return map {
                'type': 'string'
            }
            case 'hexBinary' return map {
                'type': 'string'
            }
            case 'integer' return map {
                'type': 'integer'
            }
            case 'positiveInteger' return map {
                'type': 'integer',
                'minimum': 0,
                'exclusiveMinimum': fn:true()
            }
            case 'negativeInteger' return map {
                'type': 'integer',
                'maximum': 0,
                'exclusiveMaximum': fn:true()
            }
            case 'nonNegativeInteger' return map {
                'type': 'integer',
                'minimum': 0,
                'exclusiveMinimum': fn:false()
            }
            case 'nonPositiveInteger' return map {
                'type': 'integer',
                'maximum': 0,
                'exclusiveMaximum': fn:false()
            }
            case 'long' return map {
                'type': 'integer'
            }
            case 'unsignedLong' return map {
                'type': 'integer',
                'minimum': 0,
                'exclusiveMinimum': fn:false()
            }
            case 'int' return map {
                'type': 'integer'
            }
            case 'unsignedInt' return map {
                'type': 'integer',
                'minimum': 0,
                'exclusiveMinimum': fn:false()
            }
            case 'short' return map {
                'type': 'integer'
            }
            case 'unsignedShort' return map {
                'type': 'integer',
                'minimum': 0,
                'exclusiveMinimum': fn:false()
            }
            case 'byte' return map {
                'type': 'integer'
            }
            case 'unsignedByte' return map {
                'type': 'integer',
                'minimum': 0,
                'exclusiveMinimum': fn:false()
            }
            case 'decimal' return map {
                'type': 'number'
            }
            case 'float' return map {
                'type': 'number'
            }
            case 'double' return map {
                'type': 'number'
            }
            case 'duration' return map {
                'type': 'string',
                'pattern': '^P(?!$)(\d+Y)?(\d+M)?(\d+W)?(\d+D)?(T(?=\d+[HMS])(\d+H)?(\d+M)?(\d+S)?)?$'
            }
            case 'dateTime' return map {
                  'type': 'string',
                  'pattern': '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))(T((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$'
            }
            case 'date' return map {
                'type': 'string',
                'pattern': '^\d{4}-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])$'
            }
            case 'time' return map {
                'type': 'string',
                'pattern': '^([01]\d|2[0-3]):([0-5]\d)(?::([0-5]\d)(.(\d{3}))?)?$'
            }
            case 'gYear' return map {
                'type': 'integer'
            }
            case 'gYearMonth' return map {
                'type': 'string',
                'pattern': '^(19|20)\d\d-(0[1-9]|1[012])$'
            }
            case 'gMonth' return map {
                'type': 'integer'
            }
            case 'gMonthDay' return map {
                'type': 'string',
                'pattern': '^(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])$'
            }
            case 'gDay' return map {
                'type': 'integer'
            }
            case 'Name' return map {
                'type': 'string'
            }
            case 'QName' return map {
                'type': 'string'
            }
            case 'NCName' return map {
                'type': 'string'
            }
            case 'anyURI' return map {
                'type': 'string'
            }
            case 'language' return map {
                'type': 'string'
            }
            case 'ID' return map {
                'type': 'string'
            }
            case 'IDREF' return map {
                'type': 'string'
            }
            case 'IDREFS' return map {
                'type': 'string'
            }
            case 'ENTITY' return map {
                'type': 'string'
            }
            case 'ENTITIES' return map {
                'type': 'array',
                'items': map {
                    'type': 'string'
                }
            } 
            case 'NMTOKEN' return map {
                'type': 'string'
            }
            case 'NMTOKENS' return map {
                'type': 'array',
                'items': map {
                    'type': 'string'
                }
            } 
            
            case 'anySimpleType' return map {
                'oneOf': array {
                    map { 'type': 'integer' },
                    map { 'type': 'string' },
                    map { 'type': 'number' },
                    map { 'type': 'boolean' },
                    map { 'type': 'null' }
                }
            }

            case 'anyType' return map { }

            case 'token' return map {                 
                'type': 'string' 
            }

            case 'decimal' return map {                 
                'type': 'number' 
            }
            case 'boolean' return map {
                'type': 'boolean' 
            }
            default return map {
                'type': $type 
            }
    ))
    
};

(:~
 :
 : Return the non-restrictive JSON Schema equivalent for the requested XML Schema data type
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $type the name of the XML Schema data type
 :)
declare function xsd2json:dataType-basic($type as xs:string) as xs:string {
    let $xsdType := xsd2json:postfix-from-qname($type)
    return
        switch($xsdType) 
            case 'integer' return 'integer'
            case 'gYear' return 'integer'
            case 'gMonth' return 'integer'
            case 'gDay' return 'integer'
            case 'positiveInteger' return 'integer'
            case 'negativeInteger' return 'integer'
            case 'nonNegativeInteger' return 'integer'
            case 'nonPositiveInteger' return 'integer'
            case 'long' return 'integer'
            case 'unsignedLong' return 'integer'
            case 'int' return 'integer'
            case 'unsignedInt' return 'integer'
            case 'short' return 'integer'
            case 'unsignedShort' return 'integer'
            case 'byte' return 'integer'
            case 'unsignedByte' return 'integer'
            case 'decimal' return 'number'
            case 'float' return 'number'
            case 'double' return 'number'
            case 'decimal' return 'number' 
            case 'boolean' return 'boolean' 
            default return 'string'
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:element-type($node as node(), $model as map(*)) as map(*) {
    map:merge((
    if (xsd2json:is-xsd-datatype($node/@type))
    then 
        (
            xsd2json:dataType($node/@type, $model),
            if ($node/@fixed)
            then 
                (
                    map:entry(
                        'enum', 
                        array { 
                            switch (xsd2json:dataType-basic($node/@type))
                            case 'integer' return xs:integer($node/@fixed) 
                            case 'number' return xs:decimal($node/@fixed) 
                            case 'boolean' return xs:boolean($node/@fixed) 
                            default return xs:string($node/@fixed) 
                        }
                    )
                )
            else (),
            xsd2json:passthru($node, $model)
        )
    else
        let $prefix := if (fn:contains($node/@type, ':')) then fn:substring-before($node/@type, ':') else ""
        let $postfix := if (fn:contains($node/@type, ':')) then fn:substring-after($node/@type, ':') else $node/@type/string()
        let $ns := if (fn:contains($node/@type, ':')) then (map:get($model, $prefix), 'target')[1] else ()
        let $schema := if (fn:contains($node/@type, ':')) then map:get($model, $ns) else $node/ancestor::xs:schema
        let $emodel := 
            if ($node/xs:annotation/xs:documentation)
            then map:merge(($model, map:entry('noDoc', fn:true())))
            else $model
        return
            (
                if ($node/xs:annotation/xs:documentation)
                then xsd2json:documentation($node/xs:annotation/xs:documentation, map { })
                else (),
                if ($schema//xs:complexType[@name = $postfix])
                then 
                    let $ct := $schema//xs:complexType[@name = $postfix]
                    let $content := 
                        if ($ct)
                        then xsd2json:complexType($ct, $emodel)
                        else fn:error(xs:QName('xsd2json:err057'), 'missing complexType', $postfix)
                    return
                        (
                            $content,
                            if ($node/@fixed)
                            then 
                                (
                                    map:entry(
                                        'enum', 
                                        array { 
                                            switch (map:get($content, 'type'))
                                            case 'integer' return xs:integer($node/@fixed) 
                                            case 'number' return xs:decimal($node/@fixed) 
                                            case 'boolean' return xs:boolean($node/@fixed) 
                                            default return xs:string($node/@fixed) 
                                        }
                                    )
                                )
                            else ()
                        )
                        
                else if ($schema//xs:simpleType[@name = $postfix])
                then 
                    let $st := $schema//xs:simpleType[@name = $postfix]
                    let $content := 
                        if ($st)
                        then xsd2json:simpleType($st, $emodel)
                        else fn:error(xs:QName('xsd2json:err057'), 'missing simpleType', $postfix)
                    return
                        (
                            $content,
                            if ($node/@fixed)
                            then 
                                (
                                    map:entry(
                                        'enum', 
                                        array { 
                                            switch (map:get($content, 'type'))
                                            case 'integer' return xs:integer($node/@fixed) 
                                            case 'number' return xs:decimal($node/@fixed) 
                                            case 'boolean' return xs:boolean($node/@fixed) 
                                            default return xs:string($node/@fixed) 
                                        }
                                    )
                                )
                            else ()
                        )
                else ()
            )
    ))
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:element($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    let $maximums := if (map:contains($model, 'maxOccurs')) then map:get($model, 'maxOccurs') else map { }
    let $minimums := if (map:contains($model, 'minOccurs')) then map:get($model, 'minOccurs') else map { }
    return
    if ($node/@name)
    then 
        let $minOccurs := if (map:contains($minimums, $node/@name)) then map:get($minimums, $node/@name) else '1'
        let $maxOccurs := if (map:contains($maximums, $node/@name)) then map:get($maximums, $node/@name) else '1'
        return
        if ($node/@abstract/string() = 'true')
        then map:entry(
                        $node/@name/string(), 
                        map:merge((
                            map:entry('abstract', fn:true()),
                            for $prefix in xsd2json:prefixes-from-namespace(fn:root($node)/@targetNamespace/string(), $model)
                            return map:for-each($model, function($k, $v) {
                                                            try {
                                                                let $subGroup := $prefix || ':' || $node/@name/string()
                                                                let $element := $v//xs:element[@substitutionGroup = $subGroup]
                                                                return
                                                                    if ($element)
                                                                    then map:merge(( map:entry('substitutionGroup', $subGroup), xsd2json:element-type($element, $model)))
                                                                    else map { }
                                                            } catch * { map { } }
                                                        } )
                        ))
            )
        else
            let $enhance := map:put($model, 'noDoc', fn:true())
            let $passthrough-content := xsd2json:passthru($node, $model)
            let $content := map:merge((   
                if ($node/xs:annotation/xs:documentation)
                then
                    xsd2json:documentation($node/xs:annotation/xs:documentation, map { })
                else 
                    (),
                if ($node/@type)
                then if (($node/xs:attribute, $node/xs:attributeGroup))
                     then map:entry('value', xsd2json:element-type($node, $model))
                     else xsd2json:element-type($node, $model)
                else if ($node/@fixed)
                then 
                    let $err := fn:error(xs:QName("xsd2json:aaa"), "fixed type is ", xs:string(map:get($passthrough-content, 'type')))
                    return
                    (
                        map:entry(
                            'enum', 
                            array { 
                                switch (xs:string((
                                    map:get($passthrough-content, 'type'),
                                    map:get(map:get($passthrough-content, 'items')[1], 'type')
                                    )[1])
                                )
                                case 'integer' return xs:integer($node/@fixed) 
                                case 'number' return xs:decimal($node/@fixed) 
                                case 'boolean' return xs:boolean($node/@fixed) 
                                default return xs:string($node/@fixed) 
                            }
                        )
                    )
                else (),
                $passthrough-content))
            return
                map:entry(
                    $node/@name/string(),
                    switch ($maxOccurs)
                    case '1' return $content
                    case 'unbounded' 
                        return 
                            map:merge((
                                map:entry('type', 'array'), 
                                map:entry('minItems', xs:integer(($node/@minOccurs/string(), '1')[1])), 
                                map:entry('items', map:merge((map:entry('type', 'object'), $content)))
                            ))
                    default 
                        return 
                            map:merge((
                                map:entry('type', 'array'), 
                                map:entry('minItems', xs:integer($minOccurs)), 
                                map:entry('maxItems', xs:integer($maxOccurs)), 
                                map:entry('items', map:merge((map:entry('type', 'object'), $content)))
                            ))
            )
    else let $postfix := xsd2json:postfix-from-ref($node)
        let $schema := xsd2json:schema-from-ref($node, $model)
        let $minOccurs := if (map:contains($minimums, $postfix)) then map:get($minimums, $postfix) else '1'
        let $maxOccurs := if (map:contains($maximums, $postfix)) then map:get($maximums, $postfix) else '1'
        return
            if ($schema//xs:element[@name = $postfix])
            then 
                let $element := $schema//xs:element[@name = $postfix]
                return
                    xsd2json:element(
                        element { 'xs:element' } { 
                            for $attr in $element/@*
                            return 
                                typeswitch ($attr)
                                case attribute(name) 
                                return 
                                    attribute name { 
                                        if (map:get($model, $xsd2json:KEEP_NAMESPACES)) 
                                        then $node/@ref/string() 
                                        else $element/@name/string() 
                                    } 
                                case attribute(maxOccurs) return ()
                                case attribute(minOccurs) return ()
                                default return $attr
                            , 
                            $node/@minOccurs, 
                            $node/@maxOccurs, 
                            $element/* 
                        }, 
                        $model
                    )
                    else fn:error(xs:QName('xsd2json:err057'), 'missing element', $postfix)

};

(:~
 : 
 : A subset of XPath expressions for use in fields
 : 
 : A utility type, not for public use
 : 
 : The following pattern is intended to allow XPath
 :                            expressions per the same EBNF as for selector,
 :                            with the following change:
 :           Path    ::=    ('.//')? ( Step '/' )* ( Step | '@' NameTest ) 
 :          
 : 
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:field($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    xsd2json:passthru($node, $model)
};

(:~
 :
 : This item is not supported in JSON Schema as JavaScript has no restrictions in the number of digits of a floating point number.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:fractionDigits($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    map { }
};

(:~
 : 
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:group($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    if ($node/@name)
    then
        xsd2json:passthru($node, $model)
    else
        let $schema := xsd2json:schema-from-ref($node, $model)
        let $postfix := xsd2json:postfix-from-ref($node)
        return
            if ($schema//xs:group[@name = $postfix])
            then 
                xsd2json:group($schema//xs:group[@name = $postfix], $model)
            else fn:error(xs:QName('xsd2json:err057'), 'missing group', $postfix)
};

(:~
 : 
 : Handled in the parse-level() while loading the schemas.
 : 
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:import($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    map { }
};

(:~
 : 
 : Handled in the parse-level() while loading the schemas.
 : 
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:include($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    map { }
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:key($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    xsd2json:passthru($node, $model)
};

(:~
 : 
 : TODO: Document this function.
 : 
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:keyref($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    xsd2json:passthru($node, $model)
};

(:~
 : 
 : TODO: Document this function.
 : 
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:length($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    map:merge((
        map:entry('minLength', $node/@value/number()),
        map:entry('maxLength', $node/@value/number())
    ))
};

(:~
 :
 :        itemType attribute and simpleType child are mutually
 :        exclusive, but one or other is required
 :      
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:list($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    map:merge(( 
        map:entry('type', 'array'),
        if ($node/xs:annotation)
        then
            xsd2json:annotation($node/xs:annotation, $model)
        else
            (),
        map:entry(
            'items', 
            array {
                if ($node/@itemType)
                then 
                    xsd2json:dataType($node/@itemType, $model)
                else
                    for $simpleType in $node/xs:simpleType
                    return xsd2json:simpleType($simpleType, $model)
            }
        )
    ))
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:maxExclusive($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    map { 
        'maximum': $node/@value/number(.),
        'exclusiveMaximum': true()
    }
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:maxInclusive($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    map { 
        'maximum': $node/@value/number(.),
        'exclusiveMaximum': false()
    }
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:maxLength($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    map:entry('maxLength', $node/@value/number())
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:minExclusive($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    map { 
        'minimum': $node/@value/number(.),
        'exclusiveMinimum': true()
    }
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:minInclusive($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    map { 
        'minimum': $node/@value/number(.),
        'exclusiveMinimum': false()
    }
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:minLength($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    map:entry('minLength', $node/@value/number())
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:notation($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    xsd2json:passthru($node, $model)
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:pattern($node as node(), $model as map(*)) as map(*) {
    (: Attributes:
:       value
 : Child Elements:
:       xs:annotation
 :)
    if ($node/preceding-sibling::xs:pattern)
    then map { }
    else if ($node/following-sibling::xs:pattern)
    then
        map:entry('pattern', fn:concat('^(', fn:string-join(($node/@value/string(), $node/following-sibling::xs:pattern/@value/string()), '|'), ')$'))
    else
        map:entry('pattern', fn:concat('^', $node/@value/string(), '$'))
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:redefine($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    xsd2json:passthru($node, $model)
};

(:~
 :
 :        base attribute and simpleType child are mutually
 :        exclusive, but one or other is required
 :      
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:restriction($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    map:merge((
            if (xsd2json:is-xsd-datatype($node/@base))
            then (
                    xsd2json:passthru($node, $model),
                    xsd2json:dataType($node/@base, $model)
                 )
            else
                let $postfix := xsd2json:postfix-from-qname($node/@base)
                let $schema := xsd2json:schema-from-qname($node, $node/@base, $model)
                return
                    if ($schema//xs:complexType[@name = $postfix])
                    then 
                        let $ct := $schema//xs:complexType[@name = $postfix]
                        return
                            if ($ct)
                            then xsd2json:complexType($ct, $model)
                            else fn:error(xs:QName('xsd2json:err057'), 'missing complexType', $postfix)
                    else if ($schema//xs:simpleType[@name = $postfix])
                    then 
                        let $ct := $schema//xs:simpleType[@name = $postfix]
                        return
                            if ($ct)
                            then xsd2json:simpleType($ct, $model)
                            else fn:error(xs:QName('xsd2json:err057'), 'missing simpleType', $postfix)
                    else if ($schema//xs:restriction[@name = $postfix])
                    then 
                        let $ct := $schema//xs:restriction[@name = $postfix]
                        return
                            if ($ct)
                            then xsd2json:restriction($ct, $model)
                            else fn:error(xs:QName('xsd2json:err057'), 'missing restriction', $postfix)
                    else if ($schema//xs:extension[@name = $postfix])
                    then 
                        let $ct := $schema//xs:extension[@name = $postfix]
                        return
                            if ($ct)
                            then xsd2json:extension($ct, $model)
                            else fn:error(xs:QName('xsd2json:err057'), 'missing extension', $postfix)
                    else map:merge(()),
                    
        
                if ($node/xs:enumeration)
                then (
                    map:entry(
                        'enum', 
                        array { 
                            for $enumeration in $node/xs:enumeration 
                            return $enumeration/@value/string() 
                        }
                    )
                    )
                else (),
                xsd2json:passthru($node, $model)
    ))
};

(:~
 :
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:schema($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    xsd2json:passthru($node, $model)
};

(:~
 : 
 : A subset of XPath expressions for use
 : in selectors
 : 
 : A utility type, not for public
 : use
 : 
 : The following pattern is intended to allow XPath
 :                            expressions per the following EBNF:
 :           Selector    ::=    Path ( '|' Path )*  
 :           Path    ::=    ('.//')? Step ( '/' Step )*  
 :           Step    ::=    '.' | NameTest  
 :           NameTest    ::=    QName | '*' | NCName ':' '*'  
 :                            child:: is also allowed
 :          
 : 
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:selector($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    xsd2json:passthru($node, $model)
};

(:~
 : 
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:sequence($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
        let $minOccurs := map:merge((
                            xsd2json:minOccurs-passthru($node, $model),
                            for $attr in ($node/../xs:attribute, $node/../xs:attributeGroup)
                            return xsd2json:minOccurs-passthru($attr, $model)
                          ))
        let $maxOccurs := xsd2json:maxOccurs-passthru($node, $model)
        let $required := for $key in map:keys($minOccurs)
                         order by $key
                         return if (map:get($minOccurs, $key) gt 0) then $key else ()
        return
            map:merge((
                map:entry('type', 'object'),
                map:entry(
                    'properties', 
                    map:merge(
                        for $cnode in ($node/*, $node/../xs:attribute, $node/../xs:attributeGroup) 
                        return 
                            typeswitch($cnode)
                            case element(xs:choice) return ()
                            default return xsd2json:dispatch($cnode, map:merge(($model, map:entry('maxOccurs', $maxOccurs), map:entry('minOccurs', $minOccurs))))
                    )
                ),
                map:entry('additionalProperties', if ($node/xs:any) then fn:true() else fn:false()),
                if (fn:count($required) gt 0) 
                then map:entry('required', array { $required } ) 
                else (),
                (: oneOf needs to be outside of properties :)
                for $cnode in $node/xs:choice
                return xsd2json:choice($cnode, $model)
            ))
    (: :)
};

(:~
 : 
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:simpleContent($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    if ($node/xs:extension)
    then xsd2json:extension($node/xs:extension, $model)
    else if ($node/xs:restriction)
    then xsd2json:restriction($node/xs:restriction, $model)
    else map { }
};

(:~
 : 
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:simpleType($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    let $content := xsd2json:passthru($node, $model)
    return 
        if (map:contains($model, "noName"))
        then $content
        else
        if ($node/@name and map:contains($model, 'definitions'))
        then map:entry($node/@name/string(), $content)
        else $content
};

(:~
 : 
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:simpleType-base($node as node(), $model as map(*)) as xs:string {
    (: Attributes:

 : Child Elements:

 :)
    (map:get(xsd2json:passthru($node, $model), 'type'), 'string')[1]
};

(:~
 : 
 :  This item is not supported in JSON Schema as JavaScript has no restrictions in the number of digits of a floating point number.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:totalDigits($node as node(), $model as map(*)) as map(*) {
    (: Attributes:
:       value
 : Child Elements:
:       xs:annotation
 :)
    map { }
};

(:~
 : 
 :           memberTypes attribute must be non-empty or there must be
 :           at least one simpleType child
 :         
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:union($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    map:merge((
    
        (: If the attribute memberTypes is populated, then tokenize the attribute and get the simpleType and process :)
        for $memberType in fn:tokenize($node/@memberTypes/string(), ' ')
        let $schema := xsd2json:schema-from-qname($node, $memberType, $model)
        let $simpleType := $schema/xs:simpleType[@name = $memberType]
        return xsd2json:dispatch($simpleType, $model),
        
        (: If there are multiple simpleTypes within this union, then process each, ignoring the annotation :)
        for $simpleType in $node/xs:SimpleType
        return xsd2json:dispatch($simpleType, $model)
    ))
};

(:~
 : 
 : TODO: Document this function.
 :
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:unique($node as node(), $model as map(*)) as map(*) {
    (: Attributes:

 : Child Elements:

 :)
    xsd2json:passthru($node, $model)
};

(:~
 : 
 :  This item is not supported in JSON Schema as JavaScript has no restrictions that match.
 : 
 : @author  Loren Cahlander
 : @version 1.0
 : @param   $node the current node being processed
 : @param   $model a map(*) used for passing additional information between the levels
 :)
declare function xsd2json:whiteSpace($node as node(), $model as map(*)) as map(*) {
    (: Attributes:
:       value
 : Child Elements:
:       xs:annotation
 :)
    map { }
};
