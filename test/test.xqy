xquery version "3.1";

import module namespace xsd2json="http://easymetahub.com/ns/xsd2json" at "../xsd2json.xqy";

declare namespace file="http://expath.org/ns/file";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization"; 
declare namespace xs="http://www.w3.org/2001/XMLSchema";

declare option output:method "html";
declare option output:indent "yes";

let $children := 
            for $child in file:list(fn:concat(file:base-dir(), 'xsd')) 
            order by $child
            return 
                if (fn:contains($child, "recursive"))
                then ()
                else
                if (fn:ends-with($child, '.xsd'))
                then $child
                else ()
let $success :=
            for $child in $children 
            let $name := fn:substring-before($child, '.xsd')
            let $outfile := fn:concat($name, '.json')
            let $generated := 
                xsd2json:run(
                    fn:doc(fn:concat('xsd/', $child))//xs:schema, 
                    map { 
                        $xsd2json:KEEP_NAMESPACES: fn:true(), 
                        $xsd2json:SCHEMAID: $outfile,
                        $xsd2json:RESTRICTIVE: fn:true()
                    }
                )
            let $toTest := fn:json-doc(fn:concat('json-draft-4/', $name, '.json'))
            let $option := map {'method': 'json', 'use-character-maps' : map { '/' : '/' }, 'indent': fn:true()}
            return if (fn:deep-equal($generated, $toTest)) then 1 else 0

return
element { 'html' } {
    element { 'head' } { 
        element { 'style' } {
'
.tests {
  table-layout: fixed;
  width: 100%;
  white-space: nowrap;
}
.test {
  table-layout: fixed;
  width: 100%;
  white-space: nowrap;
}
/* Column widths are based on these cells */
.row-ID {
  width: 10%;
}
.row-name {
  width: 40%;
}
.row-job {
  width: 30%;
}
.row-email {
  width: 20%;
}
.tests td {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.tests th.success {
  background: darkgreen;
  color: white;
}
.tests th.failure {
  background: darkred;
  color: white;
}
.tests td,
.tests th {
  text-align: left;
  padding: 5px 10px;
}
.tests tr:nth-child(even).success {
  background: lightgreen;
}
.tests tr:nth-child(even).failure {
    background: #FF9494;
}
'
        }
    },
    element { 'body' } {
        element { 'table' } {
            element { 'tr' } { 
                attribute { 'style' } { "width: 500px;" },
                element { 'th' } { 'total' },
                element { 'th' } { 'success' },
                element { 'th' } { 'failure' }
            },
            element { 'tr' } { 
                attribute { 'style' } { "width: 500px;" },
                element { 'td' } { fn:count($children) },
                element { 'td' } { fn:sum($success) },
                element { 'td' } { fn:count($children) - fn:sum($success) }
            } 
        },
        element { 'table' } {
            attribute { 'class' } { "tests" },
            for $child in $children 
            let $name := fn:substring-before($child, '.xsd')
            let $outfile := fn:concat($name, '.json')
            let $generated := 
                xsd2json:run(
                    fn:doc(fn:concat('xsd/', $child))//xs:schema, 
                    map { 
                        $xsd2json:KEEP_NAMESPACES: fn:true(), 
                        $xsd2json:SCHEMAID: $outfile,
                        $xsd2json:RESTRICTIVE: fn:true()
                    }
                )
            let $toTest := fn:json-doc(fn:concat('json-draft-4/', $name, '.json'))
            let $option := map {'method': 'json', 'use-character-maps' : map { '/' : '/' }, 'indent': fn:true()}
            let $equal := fn:deep-equal($generated, $toTest)
            let $success-attribute := attribute { 'class' } { if ($equal) then 'success' else 'failure' }
            return 
                if (fn:not($equal)) 
                then
                    element { 'tr' } {
                        $success-attribute,
                        element { 'td' } {
                            element { 'table' } {
                                attribute { 'class' } { "test" },
                                element { 'tr' } { 
                                    element { 'th' } { 
                                        $name 
                                    },
                                    element { 'th' } { 
                                        if ($equal) then 'success' else 'failure'
                                    }
                                },
                                element { 'tr' } { 
                                    element { 'th' } { $success-attribute, 'generated' },
                                    element { 'th' } { $success-attribute, 'test' }
                                },
                                element { 'tr' } { 
                                    element { 'td' } { 
                                        element { 'pre' } { element { 'code' } { fn:serialize($generated, $option) } } 
                                    },
                                    element { 'td' } { 
                                        element { 'pre' } { element { 'code' } { fn:serialize($toTest, $option) } } 
                                    }
                                } 
                            }
                        }
                    }
                else (),
            for $child in $children 
            let $name := fn:substring-before($child, '.xsd')
            let $outfile := fn:concat($name, '.json')
            let $generated := 
                xsd2json:run(
                    fn:doc(fn:concat('xsd/', $child))//xs:schema, 
                    map { 
                        $xsd2json:KEEP_NAMESPACES: fn:true(), 
                        $xsd2json:SCHEMAID: $outfile,
                        $xsd2json:RESTRICTIVE: fn:true()
                    }
                )
            let $toTest := fn:json-doc(fn:concat('json-draft-4/', $name, '.json'))
            let $option := map {'method': 'json', 'use-character-maps' : map { '/' : '/' }, 'indent': fn:true()}
            let $equal := fn:deep-equal($generated, $toTest)
            let $success-attribute := attribute { 'class' } { if ($equal) then 'success' else 'failure' }
            return 
                if ($equal) 
                then
                    element { 'tr' } {
                        $success-attribute,
                        element { 'td' } {
                            element { 'table' } {
                                attribute { 'class' } { "test" },
                                element { 'tr' } { 
                                    element { 'th' } { 
                                        $name 
                                    },
                                    element { 'th' } { 
                                        if ($equal) then 'success' else 'failure'
                                    }
                                },
                                element { 'tr' } { 
                                    element { 'th' } { $success-attribute, 'generated' },
                                    element { 'th' } { $success-attribute, 'test' }
                                },
                                element { 'tr' } { 
                                    element { 'td' } { 
                                        element { 'pre' } { element { 'code' } { fn:serialize($generated, $option) } } 
                                    },
                                    element { 'td' } { 
                                        element { 'pre' } { element { 'code' } { fn:serialize($toTest, $option) } } 
                                    }
                                } 
                            }
                        }
                    }
                else (),
            ()
        }
    }
}
