xquery version "3.0";

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xql";
import module namespace cfg = "http://expath.org/ns/ml/console/config" at "../lib/config.xql";
import module namespace r   = "http://expath.org/ns/ml/console/repo"   at "../lib/repo.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace w    = "http://expath.org/ns/ml/webapp";
declare namespace pp   = "http://expath.org/ns/repo/packages";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:page()
   as element()+
{
   (: TODO: Check the parameter has been passed, to avoid XQuery errors! :)
   (: (turn it into a human-friendly error instead...) :)
   (: And validate it! (does the container exist?) :)
   let $id        := t:mandatory-field('id')
   let $ref       := cfg:get-container-ref($id)
   let $container := cfg:get-container($ref)
   return
      <wrapper> {
         (: TODO: Display some infos about the web container (ID, name, etc.) :)
         if ( fn:empty($container/w:application) ) then
            ()
         else
            <table class="sortable">
               <thead>
                  <td>ID</td>
                  <td>Name</td>
                  <td>Root</td>
                  <td>Dir</td>
                  <td>Action</td>
               </thead>
               <tbody> {
                  for $app in $container/w:application
                  order by $app/fn:string(@id)
                  return
                     local:app-row($app)
               }
               </tbody>
            </table>
         }
         <h4>Install from file</h4>
         <p>Install web applications from your filesystem, using a package
            file (usually a *.xaw file).</p>
         <form method="post" action="install-app.xq" enctype="multipart/form-data">
            <input type="file" name="xaw"/>
            <input type="submit" value="Install"/>
            <!--br/><br/>
            <input type="checkbox" name="override" value="true"/>
            <em>Override the package of it already exists</em-->
            <input type="hidden" name="container" value="{ $id }"/>
         </form>
         <h4>Install from CXAN</h4>
         <p>TODO: Still to implement...</p>
         <!--p>Install web applications directly from CXAN, using a package name
            or a CXAN ID (one or the other), and optionally a version number
            (retrieve the latest version by default).</p>
         <form method="post" action="../cxan/install.xq" enctype="multipart/form-data">
            <span>ID:</span>
            <input type="text" name="id" size="25"/>
            <span>Name:</span>
            <input type="text" name="name" size="50"/>
            <span>Version:</span>
            <input type="text" name="version" size="25"/>
            <input type="submit" value="Install"/>
            <input type="hidden" name="container" value="{ $id }"/>
         </form-->
      </wrapper>/*
};

declare function local:app-row($app as element(w:application))
   as element(tr)
{
   <tr>
      <td>{ $app/fn:string(@id) }</td>
      <td>{ $app/fn:string(w:name) }</td>
      <td>{ $app/fn:string(w:root) }</td>
      <td>{ $app/fn:string(w:pkg-dir) }</td>
      <td>
         <a href="delete-app.xq?container={ $app/../@id }&amp;webapp={ $app/fn:string(@id) }">delete</a>
      </td>
   </tr>
};

v:console-page('../',  'web', 'Web container', local:page#0)
