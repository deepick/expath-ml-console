xquery version "1.0";

(:~
 : Provides XProject-related tools.
 :)

import module namespace v = "http://expath.org/ns/ml/console/view" at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

v:console-page(
   'xproject',
   'XProject',
   <p><b>TODO</b>: Provide XProject-related tools, in particular generating a
      XAR package out of a project directory, plus xqdoc, unit tests, etc.</p>)
