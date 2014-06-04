xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace err  = "http://www.w3.org/2005/xqt-errors";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:page()
   as element()+
{
   let $id-str := t:mandatory-field('id')
   let $id     := xs:unsignedLong($id-str)
   let $as     := a:get-appserver($id)
   let $name   := xs:string($as/a:name)
   return (
      try {
         (: either it contains the element or an error is thrown, but for extra safety...:)
         if ( fn:exists(a:appserver-init-repo($as)/a:repo) ) then
            <p>Package repository correctly initialized for the app server "<code>{ $name }</code>".</p>
         else
            t:error('local-init-repo-01', 'Error initializing the package repository for the app server: ' || $name)
      }
      catch c:packages-file-exists {
         <p><b>Error</b>: package repository already initialized for the app server
            "<code>{ $name }</code>".</p>,
         <p>{ $err:description }</p>
      },
      <p>Back to the app server <a href="../{ $as/@id }">{ $name }</a>.</p>
   )
};

v:console-page('../../', 'pkg', 'App server', local:page#0)
