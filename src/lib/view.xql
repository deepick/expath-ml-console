xquery version "3.0";

(:~
 : Library to help generating the view.
 :)
module namespace v = "http://expath.org/ns/ml/console/view";

import module namespace a = "http://expath.org/ns/ml/console/admin"  at "admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace err  = "http://www.w3.org/2005/xqt-errors";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $v:pages as element(pages) :=
   <pages>
      <page name="pkg"      title="Packages"                      label="Packages"/>
      <!--page name="web"      title="Web Applications Containers"   label="Web"/>
      <page name="cxan"     title="CXAN Config"                   label="CXAN"/>
      <page name="xproject" title="XProject Tools"                label="XProject"/>
      <page name="xspec"    title="XSpec Tools"                   label="XSpec"/>
      <page name="browser"  title="Documents and triples browser" label="Browser"/-->
      <page name="db"       title="Database browser"              label="Databases"/>
      <page name="loader"   title="The document manager"          label="Loader"/>
      <page name="profiler" title="XQuery Profiler"               label="Profiler"/>
      <page name="project"  title="The project manager"           label="Projects"/>
      <page name="tools"    title="Goodies for MarkLogic"         label="Tools"/>
      <!--page name="help"     title="Console Help"                  label="Help"/-->
      <!--page name="devel"    title="Devel's evil"                  label="Devel"/-->
   </pages>;

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Generic view tools
 :)

(:~
 : Redirect to `$url`, using a 302 HTTP status code.
 :
 : Note: I am not a fan of using side-effect functions like this.  The user
 : should be able to return a different status code and message than "200 OK"
 : on the view itself.
 :)
declare function v:redirect($url as xs:string)
   as empty-sequence()
{
   xdmp:set-response-code(302, 'Found'),
   xdmp:add-response-header('Location', $url)
};

(:~
 : Format the top-level menu of a console page.
 :
 : $page: the current page (must be the key of one menu)
 : $root: '' if a top-level page, or '../' if in a sub-directory
 :)
declare function v:console-page-menu($page as xs:string, $root as xs:string)
   as element(h:li)+
{
   for $p in $v:pages/page
   return
      <li xmlns="http://www.w3.org/1999/xhtml"> {
         attribute { 'class' } { 'active' }[$p/@name eq $page],
         <a href="{ $root }{ $p/(@href, @name)[1] }" title="{ $p/@title }"> {
            $p/fn:string(@label)
         }
         </a>
      }
      </li>
};

(:~
 : Format a console page.
 :
 : @param page    the current page (must be the key of one menu)
 : @param title   the title of the page (to appear on top of the page)
 : @param root    `''` if a top-level page, or `'../'` if in a sub-directory
 : @param content the actual HTML content, pasted as the content of the page
 :)
declare function v:console-page(
   $root    as xs:string,
   $page    as xs:string,
   $title   as xs:string,
   $content as function() as element()+
) as element(h:html)
{
   v:console-page($root, $page, $title, $content, ())
};

(:~
 : Format a console page.
 :
 : @param page    the current page (must be the key of one menu)
 : @param title   the title of the page (to appear on top of the page)
 : @param root    `''` if a top-level page, or `'../'` if in a sub-directory
 : @param content the actual HTML content, pasted as the content of the page
 : @param scripts extra HTML "script" elements, to be added at the very end
 :)
declare function v:console-page(
   $root    as xs:string,
   $page    as xs:string,
   $title   as xs:string,
   $content as function() as element()+,
   $scripts as element(h:script)*
) as element(h:html)
{
   let $cnt  := v:eval-content($content)
   let $pres := $cnt/descendant-or-self::h:pre
   return
      v:console-page-static($root, $page, $title, $cnt, $scripts)
};

(:~
 : Eval content, protecting from exceptions.
 :
 : The return value is the result of calling `$content`.  In case it throws an
 : error, this function returns HTML elements describing the error instead, to
 : be displayed to the user.
 :
 : FIXME: In order to be sure the transaction is rolled back in case of failure,
 : do NOT use try/catch here.  Move the error handling to the error handler
 : module, set on the appserver.
 :)
declare %private function v:eval-content(
   $content as function() as element()+
) as element()+
{
   try {
      $content()
   }
   catch c:* {
      <p xmlns="http://www.w3.org/1999/xhtml"><b>Error</b>: { $err:description }</p>
   }
   catch * {
      <p xmlns="http://www.w3.org/1999/xhtml"><b>SYSTEM ERROR</b>
         (please report this to the mailing list): { $err:description }</p>,
      v:display-xml($err:additional)
   }
};

(:~
 : Inject the content into the overall page structure of the console.
 :)
declare %private function v:console-page-static(
   $root    as xs:string,
   $page    as xs:string,
   $title   as xs:string,
   $content as element()+,
   $scripts as element(h:script)*
) as element(h:html)
{
   <html lang="en" xmlns="http://www.w3.org/1999/xhtml">
      <head>
         <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
         <meta name="viewport" content="width=device-width, initial-scale=1"/>
         <meta name="ml.time"  content="{ xdmp:elapsed-time() }"/>
         <title>{ $title }</title>
         {
            v:import-css($root || 'style/', (
               'bootstrap.css',
               'bootstrap-select.css',
               'typeahead.css',
               'expath-theme.css'
            )),
            v:import-css($root || 'js/', (
               'datatables-1.10.10/css/dataTables.bootstrap.css',
               'file-upload-9.11.2/jquery.fileupload.css',
               'file-upload-9.11.2/jquery.fileupload-ui.css',
               'gallery-2.16.0/blueimp-gallery.min.css',
               'highlight/styles/default.css'
            ))
         }
         <link href="{ $root }images/expath-icon.png" rel="shortcut icon" type="image/png"/>
      </head>
      <body>
         <nav class="navbar navbar-inverse navbar-fixed-top">
            <div class="container">
               <div class="navbar-header">
                  <button type="button" class="navbar-toggle collapsed" data-toggle="collapse"
                          data-target="#navbar" aria-expanded="false" aria-controls="navbar">
                     <span class="sr-only">Toggle navigation</span>
                     <span class="icon-bar"/>
                     <span class="icon-bar"/>
                     <span class="icon-bar"/>
                  </button>
                  <a class="navbar-brand" href="{ $root }./">EXPath Console</a>
               </div>
               <div id="navbar" class="navbar-collapse collapse">
                  <ul class="nav navbar-nav"> {
                     v:console-page-menu($page, $root)
                  }
                  </ul>
                  <p class="navbar-text navbar-right">User: { xdmp:get-current-user() }</p>
               </div>
            </div>
         </nav>
         <div class="container theme-showcase" role="main">
         {
            <h1>{ $title }</h1>[fn:empty($content[@class = 'jumbotron'])],
            $content
         }
         </div>
         {
            v:import-javascript($root || 'js/', (
               'jquery.js',
               'bootstrap.js',
               'bootstrap-select.js',
               'ace/ace.js',
               'ace/ext-static_highlight.js',
               'datatables-1.10.10/js/jquery.dataTables.js',
               'datatables-1.10.10/js/dataTables.bootstrap.js',
               'file-upload-9.11.2/vendor/jquery.ui.widget.js',
               'templates-2.5.5/tmpl.min.js',
               'load-image-1.14.0/load-image.all.min.js',
               'canvas-to-blob-2.2.0/canvas-to-blob.min.js',
               'gallery-2.16.0/jquery.blueimp-gallery.min.js',
               'file-upload-9.11.2/jquery.iframe-transport.js',
               'file-upload-9.11.2/jquery.fileupload.js',
               'file-upload-9.11.2/jquery.fileupload-process.js',
               'file-upload-9.11.2/jquery.fileupload-image.js',
               'file-upload-9.11.2/jquery.fileupload-audio.js',
               'file-upload-9.11.2/jquery.fileupload-video.js',
               'file-upload-9.11.2/jquery.fileupload-validate.js',
               'file-upload-9.11.2/jquery.fileupload-ui.js',
               'expath-console.js'
            )),
            $scripts
         }
      </body>
   </html>
};

declare function v:import-javascript($root as xs:string, $paths as xs:string+)
   as element(h:script)+
{
   $paths ! <script xmlns="http://www.w3.org/1999/xhtml"
                    type="text/javascript"
                    src="{ $root }{ . }"/>
};

declare function v:import-css($root as xs:string, $paths as xs:string+)
   as element(h:link)+
{
   $paths ! <link xmlns="http://www.w3.org/1999/xhtml"
                  rel="stylesheet"
                  type="text/css"
                  href="{ $root }{ . }"/>
};

(:~
 : Return an error message if `$db` does not exist, or eval `$fun` if it does.
 :
 : @param db  The name or the ID of a database.
 : @param fun A 1-arity function, the value of which is returned when `$db` exists.
 :    Its only parameter is the database element, `a:database`.
 :)
declare function v:ensure-db($db as item(), $fun as function(element(a:database)) as item()*)
   as item()*
{
   v:ensure-db($db, $fun, function() {
      t:respond-not-found(
         <p xmlns="http://www.w3.org/1999/xhtml"><b>Error</b>:
            There is no such database: <code>{ $db }</code>.</p>)
   })
};

(:~
 : Return an error message if `$db` does not exist, or eval `$fun` if it does.
 :
 : @param db  The name or the ID of a database.
 : @param fun A 1-arity function, the value of which is returned when `$db` exists.
 :    Its only parameter is the database element, `a:database`.
 : @param msg A 0-arity function, the value of which is returned when `$db` does not exist.
 :)
declare function v:ensure-db(
   $db  as item(),
   $fun as function(element(a:database)) as item()*,
   $msg as function() as item()*
) as item()*
{
   let $database := a:get-database($db)
   return
      if ( fn:exists($database) ) then
         $fun($database)
      else
         $msg()
};

(:~
 : Return an error message if `$db` does not have URI lexicon, or eval `$fun` if it does.
 :
 : @param db  The name or the ID of a database, or an a:database element.
 : @param fun A 0-arity function, the value of which is returned when there is a URI lexicon.
 :)
declare function v:ensure-uri-lexicon($db as item(), $fun as function() as item()*)
   as item()*
{
   v:ensure-uri-lexicon($db, $fun, function($database) {
      t:respond-not-implemented((
         <p xmlns="http://www.w3.org/1999/xhtml"><b>Error</b>:
            The URI lexicon is not enabled on the database
            { xs:string($database/a:name) ! v:db-link('../' || ., .) }.</p>,
         <p xmlns="http://www.w3.org/1999/xhtml">It is required to browse
            documents in a directory-like way.</p>))
   })
};

(:~
 : Return an error message if `$db` does not have URI lexicon, or eval `$fun` if it does.
 :
 : @param db  The name or the ID of a database, or an a:database element.
 : @param fun A 0-arity function, the value of which is returned when there is a URI lexicon.
 : @param msg A 1-arity function, the value of which is returned when there is no URI lexicon.
 :    Its only parameter is the database element, `a:database`.
 :)
declare function v:ensure-uri-lexicon(
   $db  as item(),
   $fun as function() as item()*,
   $msg as function(element(a:database)) as item()*
) as item()*
{
   let $database := a:get-database($db)
   return
      if ( $database/a:lexicons/xs:boolean(a:uri) ) then
         $fun()
      else
         $msg($database)
};

(:~
 : Return an error message if `$db` does not have collection lexicon, or eval `$fun` if it does.
 :
 : @param db  The name or the ID of a database, or an a:database element.
 : @param fun A 0-arity function, the value of which is returned when there is a collection lexicon.
 :)
declare function v:ensure-coll-lexicon($db as item(), $fun as function() as item()*)
   as item()*
{
   v:ensure-coll-lexicon($db, $fun, function($database) {
      t:respond-not-implemented((
         <p xmlns="http://www.w3.org/1999/xhtml"><b>Error</b>:
            The collection lexicon is not enabled on the database
            { xs:string($database/a:name) ! v:db-link('../' || ., .) }.</p>,
         <p xmlns="http://www.w3.org/1999/xhtml">It is required to browse
            collections in a directory-like way.</p>))
   })
};

(:~
 : Return an error message if `$db` does not have collection lexicon, or eval `$fun` if it does.
 :
 : @param db  The name or the ID of a database, or an a:database element.
 : @param fun A 0-arity function, the value of which is returned when there is a collection lexicon.
 : @param msg A 1-arity function, the value of which is returned when there is no collection lexicon.
 :    Its only parameter is the database element, `a:database`.
 :)
declare function v:ensure-coll-lexicon(
   $db  as item(),
   $fun as function() as item()*,
   $msg as function(element(a:database)) as item()*
) as item()*
{
   let $database := a:get-database($db)
   return
      if ( $database/a:lexicons/xs:boolean(a:coll) ) then
         $fun()
      else
         $msg($database)
};

(:~
 : Return an error message if `$db` does not have a triple index, or eval `$fun` if it does.
 :
 : @param db  The name or the ID of a database, or an a:database element.
 : @param fun A 0-arity function, the value of which is returned when there is a triple index.
 :)
declare function v:ensure-triple-index($db as item(), $fun as function() as item()*)
   as item()*
{
   v:ensure-triple-index($db, $fun, function($database) {
      t:respond-not-implemented((
         <p xmlns="http://www.w3.org/1999/xhtml"><b>Error</b>:
            The triple index is not enabled on the database
            { xs:string($database/a:name) ! v:db-link('../' || ., .) }.</p>,
         <p xmlns="http://www.w3.org/1999/xhtml">It is required to browse triples.</p>))
   })
};

(:~
 : Return an error message if `$db` does not have a triple index, or eval `$fun` if it does.
 :
 : @param db  The name or the ID of a database, or an a:database element.
 : @param fun A 0-arity function, the value of which is returned when there is a triple index.
 : @param msg A 1-arity function, the value of which is returned when there is no triple index.
 :    Its only parameter is the database element, `a:database`.
 :)
declare function v:ensure-triple-index(
   $db  as item(),
   $fun as function() as item()*,
   $msg as function(element(a:database)) as item()*
) as item()*
{
   let $database := a:get-database($db)
   return
      if ( $database/xs:boolean(a:triple-index) ) then
         $fun()
      else
         $msg($database)
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : ACE editor tools
 :)

declare variable $serial-options :=
   <options xmlns="xdmp:quote">
      <indent-untyped>yes</indent-untyped>
   </options>;

(:~
 : Format a `pre` element containing some XML.
 :
 : $elem: the element to serialize and display in a `pre` (with syntax highlighted)
 :)
declare function v:display-xml(
   $elem as node()
) as element(h:pre)
{
   v:ace-editor($elem, 'code', 'xml', (), (), (), ())
};

(:~
 : Format a `pre` element containing some XML, and turn it into an editor.
 :
 : @param $elem The element to serialize and display in the editor.
 : 
 : @param $id The ID to use on the page (in HTML) for the editor.
 : 
 : @param $uri The URI (in the database) of the document being edited.
 : 
 : @param $top The relative reference to the top, for breadcrums.
 :)
declare function v:edit-xml(
   $elem as node(),
   $id   as xs:string,
   $uri  as xs:string,
   $dir  as xs:string,
   $root as xs:string,
   $sep  as xs:string,
   $top  as xs:string
) as element()+
{
   v:edit-node($elem, 'xml', 'xml', $id, $uri, $dir, $root, $sep, $top)
};

(:~
 : Like v:edit-xml(), but for JSON.
 :
 : For editing "attached" text (attached to a document in the database, so with
 : a URI).
 :)
declare function v:edit-json(
   $json as node(),
   $id   as xs:string,
   $uri  as xs:string,
   $dir  as xs:string,
   $root as xs:string,
   $sep  as xs:string,
   $top  as xs:string
) as element()+
{
   v:edit-node($json, 'json', 'json', $id, $uri, $dir, $root, $sep, $top)
};

(:~
 : Like v:edit-xml(), but for text.  $mode is an ACE mode, e.g. "xquery".
 :
 : For editing "detached" text (not attached to a document in the database, so
 : without any URI).
 :)
declare function v:edit-text(
   $elem as text(),
   $mode as xs:string,
   $id   as xs:string
) as element(h:pre)
{
   v:ace-editor($elem, 'editor', $mode, $id, (), (), '250pt')
};

(:~
 : Like v:edit-xml(), but for text.  $mode is an ACE mode, e.g. "xquery".
 :
 : For editing "detached" text (not attached to a document in the database, so
 : without any URI).
 :)
declare function v:edit-text(
   $elem as text(),
   $mode as xs:string,
   $id   as xs:string,
   $top  as xs:string
) as element(h:pre)
{
   v:ace-editor($elem, 'editor', $mode, $id, (), $top, '250pt')
};

(:~
 : Like v:edit-xml(), but for text.  $mode is an ACE mode, e.g. "xquery".
 :
 : For editing "attached" text (attached to a document in the database, so with
 : a URI).
 :)
declare function v:edit-text(
   $text as text(),
   $mode as xs:string,
   $id   as xs:string,
   $uri  as xs:string,
   $dir  as xs:string,
   $root as xs:string,
   $sep  as xs:string,
   $top  as xs:string
) as element()+
{
   v:edit-node($text, $mode, 'text', $id, $uri, $dir, $root, $sep, $top)
};

(:~
 : Implementation of v:edit-xml() and v:edit-text().
 :
 : For editing "attached" nodes (attached to a document in the database, so with
 : a URI).
 :)
declare function v:edit-node(
   $node as node(),
   $mode as xs:string,
   $type as xs:string,
   $id   as xs:string,
   $uri  as xs:string,
   $dir  as xs:string,
   $root as xs:string,
   $sep  as xs:string,
   $top  as xs:string
) as element()+
{
   v:ace-editor($node, 'editor', $mode, $id, $uri, $top, '250pt'),
   <dummy xmlns="http://www.w3.org/1999/xhtml">
      <button class="btn btn-default" onclick='saveDoc("{ $id }", "{ $type }");'>Save</button>
      <button class="btn btn-danger pull-right" onclick='deleteDoc("{ $id }");'>Delete</button>
      <form method="POST" action="{ $top }delete" style="display: none" id="{ $id }-delete">
         <input type="hidden" name="doc"        value="{ $uri }"/>
         <input type="hidden" name="back-label" value="the directory"/>
         <input type="hidden" name="back-url"   value="dir?uri={
            fn:encode-for-uri($dir) }&amp;root={ fn:encode-for-uri($root) }&amp;sep={ fn:encode-for-uri($sep) }"/>
      </form>
   </dummy>/*
};

(:~
 : Common implementation of `v:display-xml()` and `v:edit-xml()`.
 :)
declare function v:ace-editor(
   $content  as item(),
   $class    as xs:string,
   $mode     as xs:string,
   $id       as xs:string?,
   $uri      as xs:string?,
   $top      as xs:string?,
   $height   as xs:string?
) as element(h:pre)
{
   <pre xmlns="http://www.w3.org/1999/xhtml"
        class="{ $class }"
        ace-mode="ace/mode/{ $mode }"
        ace-theme="ace/theme/pastel_on_dark"
        ace-gutter="true">
   {
      attribute { 'id'         } { $id }[fn:exists($id)],
      attribute { 'ace-uri'    } { $uri }[fn:exists($uri)],
      attribute { 'ace-top'    } { $top }[fn:exists($top)],
      attribute { 'style'      } { 'height: ' || $height }[fn:exists($height)],
      if ( $content instance of node() ) then
         xdmp:quote($content, $serial-options)
      else
         $content
   }
   </pre>
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Form tools
 :)

declare function v:inject-attr($name as xs:string, $value as xs:string, $sep as xs:string, $attrs as attribute()*)
   as attribute()+
{
   let $a := $attrs[fn:name(.) eq $name]
   return
      if ( fn:exists($a) ) then (
         attribute { $name } { $value || $sep || $a },
         $attrs except $a
      )
      else (
         attribute { $name } { $value },
         $attrs
      )
};

declare function v:form($action as xs:string, $content as element()+)
   as element(h:form)
{
   v:form($action, (), $content)
};

declare function v:form($action as xs:string, $attrs as attribute()*, $content as element()+)
   as element(h:form)
{
   v:form($action, $attrs, $content, ())
};

declare function v:form($action as xs:string, $attrs as attribute()*, $content as element()+, $method as xs:string?)
   as element(h:form)
{
   v:form-impl($action, v:inject-attr('class', 'form-horizontal', ' ', $attrs), $content, $method)
};

declare function v:inline-form($action as xs:string, $content as element()+)
   as element(h:form)
{
   v:inline-form($action, (), $content)
};

declare function v:inline-form($action as xs:string, $attrs as attribute()*, $content as element()+)
   as element(h:form)
{
   v:form-impl(
      $action,
      v:inject-attr('class', 'form-inline', ' ',
         v:inject-attr('style', 'height: 12pt', '; ', $attrs)),
      $content,
      ())
};

declare function v:one-liner-form($action as xs:string, $submit as xs:string, $content as element()+)
   as element(h:form)
{
   v:one-liner-form($action, $submit, (), $content)
};

declare function v:one-liner-form($action as xs:string, $submit as xs:string, $method as xs:string?, $content as element()+)
   as element(h:form)
{
   v:one-liner-form($action, $submit, $method, (), $content)
};

declare function v:one-liner-form(
   $action  as xs:string,
   $submit  as xs:string,
   $method  as xs:string?,
   $attrs   as attribute()*,
   $content as element()+
) as element(h:form)
{
   v:form($action, $attrs,
      <div xmlns="http://www.w3.org/1999/xhtml" class="form-group">
         { $content/label }
         <div class="col-sm-9">
            { $content/descendant-or-self::input }
         </div>
         <div class="col-sm-1">
            <button type="submit" class="btn btn-default">{ $submit }</button>
         </div>
      </div>,
      $method)
};

declare function v:one-liner-link($label as xs:string, $action as xs:string, $submit as xs:string)
   as element(h:form)
{
   v:one-liner-link($label, $action, $submit, 'get', ())
};

declare function v:one-liner-link(
   $label  as xs:string,
   $action as xs:string,
   $submit as xs:string,
   $hidden as element(h:input)*
) as element(h:form)
{
   v:one-liner-link($label, $action, $submit, 'post', $hidden)
};

declare function v:one-liner-link(
   $label  as xs:string,
   $action as xs:string,
   $submit as xs:string,
   $method as xs:string,
   $hidden as element(h:input)*
) as element(h:form)
{
   if ( fn:exists($hidden[fn:not(@type eq 'hidden')]) ) then
      t:error('invalid-form', 'Non-hidden input fieldd')
   else
      v:form($action, (),
         <div xmlns="http://www.w3.org/1999/xhtml" class="form-group">
            <label class="col-sm-2 control-label">{ $label }</label>
            <div class="col-sm-10">
               { $hidden }
               <button class="btn btn-default">{ $submit }</button>
            </div>
         </div>,
         $method)
};

declare %private function v:form-impl(
   $action  as xs:string,
   $attrs   as attribute()*,
   $content as element()+,
   $method  as xs:string?
) as element(h:form)
{
   <form xmlns="http://www.w3.org/1999/xhtml"
         method="{ ($method, 'post')[1] }"
         action="{ $action }"
         enctype="multipart/form-data"> {
      $attrs,
      $content
   }
   </form>
};

declare function v:input-text($id as xs:string, $label as xs:string, $placeholder as xs:string)
   as element(h:div)
{
   v:input-text($id, $label, $placeholder, ())
};

declare function v:input-text(
   $id          as xs:string,
   $label       as xs:string,
   $placeholder as xs:string,
   $div-attrs   as attribute()*
) as element(h:div)
{
   v:input-text($id, $label, $placeholder, $div-attrs, ())
};

declare function v:input-text(
   $id          as xs:string,
   $label       as xs:string,
   $placeholder as xs:string,
   $div-attrs   as attribute()*,
   $input-attrs as attribute()*
) as element(h:div)
{
   <div xmlns="http://www.w3.org/1999/xhtml">
      { v:inject-attr('class', 'form-group', ' ', $div-attrs) }
      <label for="{ $id }" class="col-sm-2 control-label">{ $label }</label>
      <div class="col-sm-10">
         <input type="text" name="{ $id }" placeholder="{ $placeholder }"> {
            v:inject-attr('class', 'form-control', ' ', $input-attrs)
         }
         </input>
      </div>
   </div>
};

declare function v:submit($label as xs:string)
   as element(h:div)
{
   <div xmlns="http://www.w3.org/1999/xhtml" class="form-group">
      <div class="col-sm-offset-2 col-sm-10">
         <button type="submit" class="btn btn-default">{ $label }</button>
      </div>
   </div>
};

declare function v:input-select($id as xs:string, $label as xs:string, $options as element(h:option)*)
   as element(h:div)
{
   <div xmlns="http://www.w3.org/1999/xhtml" class="form-group">
      <label for="{ $id }" class="col-sm-2 control-label">{ $label }</label>
      <div class="col-sm-10">
         <select name="{ $id }" class="form-control"> {
            $options
         }
         </select>
      </div>
   </div>
};

declare function v:input-select(
   $id           as xs:string,
   $label        as xs:string,
   $options      as element(h:option)*,
   $div-attrs    as attribute()*,
   $select-attrs as attribute()*
) as element(h:div)
{
   <div xmlns="http://www.w3.org/1999/xhtml">
      { v:inject-attr('class', 'form-group', ' ', $div-attrs) }
      <label for="{ $id }" class="col-sm-2 control-label">{ $label }</label>
      <div class="col-sm-10">
         <select name="{ $id }"> {
            v:inject-attr('class', 'form-control', ' ', $select-attrs),
            $options
         }
         </select>
      </div>
   </div>
};

declare function v:input-option($val as xs:string, $label as xs:string)
   as element(h:option)
{
   v:input-option($val, $label, ())
};

declare function v:input-option($val as xs:string, $label as xs:string, $attrs as attribute()*)
   as element(h:option)
{
   <option xmlns="http://www.w3.org/1999/xhtml" value="{ $val }">{ $attrs, $label }</option>
};

declare function v:input-select-databases($id as xs:string, $label as xs:string)
   as element(h:div)
{
   v:input-select-databases($id, $label, a:get-databases()/a:database)
};

declare function v:input-select-databases(
   $id    as xs:string,
   $label as xs:string,
   $dbs   as element(a:database)*
) as element(h:div)
{
   v:input-select($id, $label,
      for $db   in $dbs
      let $name := $db/a:name
      order by $name
      return
         v:input-option($name, $name))
};

declare function v:input-select-rulesets(
   $id      as xs:string,
   $label   as xs:string,
   $checked as xs:string*
) as element(h:div)
{
   v:input-select-rulesets($id, $label, $checked, (), ())
};

declare function v:input-select-rulesets(
   $id           as xs:string,
   $label        as xs:string,
   $checked      as xs:string*,
   $div-attrs    as attribute()*,
   $select-attrs as attribute()*
) as element(h:div)
{
   v:input-select($id, $label,
      let $selected := attribute { 'selected' } { 'selected' }
      let $dir      := './Config/'
      for $r at $pos in
            a:browse-files($dir, function($file) {
               $file[fn:ends-with(., '.rules')] ! fn:substring-after(., $dir)
            })
      order by $r
      return
         (: TODO: What if one of `$checked` is not in any of the `$r`...? :)
         v:input-option($r, $r, $selected[$r = $checked]),
      $div-attrs,
      v:inject-attr('class', 'selectpicker', ' ',
         v:inject-attr('multiple', 'multiple', ' ', $select-attrs)))
};

declare function v:input-file($id as xs:string, $label as xs:string)
   as element(h:div)
{
   <div xmlns="http://www.w3.org/1999/xhtml" class="form-group">
      <label for="{ $id }" class="col-sm-2 control-label">{ $label }</label>
      <div class="col-sm-10">
         <input type="file" name="{ $id }"/>
      </div>
   </div>
};

declare function v:input-checkbox($id as xs:string, $label as xs:string, $checked as xs:string)
   as element(h:div)
{
   <div xmlns="http://www.w3.org/1999/xhtml" class="form-group">
      <label for="{ $id }" class="col-sm-2 control-label">{ $label }</label>
      <div class="col-sm-10">
         <input type="checkbox" name="{ $id }" checked="{ $checked }"/>
      </div>
   </div>
};

declare function v:input-hidden($id as xs:string, $val as xs:string)
   as element(h:input)
{
   v:input-hidden($id, $val, ())
};

declare function v:input-hidden($id as xs:string, $val as xs:string, $attrs as attribute()*)
   as element(h:input)
{
   <input xmlns="http://www.w3.org/1999/xhtml" type="hidden" name="{ $id }" value="{ $val }"> {
      $attrs
   }
   </input>
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Link display tools
 :)

declare function v:proj-link($href as xs:string, $name as xs:string)
{
   v:component-link($href, $name, 'proj')
};

declare function v:db-link($href as xs:string, $name as xs:string)
{
   v:component-link($href, $name, 'db')
};

declare function v:as-link($href as xs:string, $name as xs:string)
{
   v:component-link($href, $name, 'as')
};

declare function v:doc-link($root as xs:string, $uri as xs:string)
{
   v:component-link($root || 'doc?uri=' || fn:encode-for-uri($uri), $uri, 'doc')
};

declare function v:doc-link($root as xs:string, $uri as xs:string, $sep as xs:string)
{
   let $label := fn:tokenize($uri, $sep)[fn:last()]
   return
      v:component-link($root || 'doc?uri=' || fn:encode-for-uri($uri), $label, 'doc')
};

declare function v:coll-link($root as xs:string, $uri as xs:string)
{
   v:component-link($root || 'coll?uri=' || fn:encode-for-uri($uri), $uri, 'coll')
};

declare function v:coll-link($root as xs:string, $uri as xs:string, $sep as xs:string)
{
   let $label := fn:tokenize($uri, $sep)[fn:last()]
   return
      v:component-link($root || 'coll?uri=' || fn:encode-for-uri($uri), $label, 'coll')
};

declare function v:dir-link($root as xs:string, $uri as xs:string)
{
   v:component-link($root || 'dir?uri=' || fn:encode-for-uri($uri), $uri, 'dir')
};

declare function v:dir-link($root as xs:string, $uri as xs:string, $sep as xs:string)
{
   let $label := fn:tokenize($uri, $sep)[fn:last() - 1] || $sep
   return
      v:component-link($root || 'dir?uri=' || fn:encode-for-uri($uri), $label, 'dir')
};

declare function v:cdir-link($root as xs:string, $uri as xs:string, $sep as xs:string)
{
   let $label := fn:tokenize($uri, $sep)[fn:last() - 1] || $sep
   return
      v:component-link($root || 'cdir?uri=' || fn:encode-for-uri($uri), $label, 'dir')
};

declare function v:root-link($root as xs:string, $uri as xs:string)
{
   v:component-link($root || 'dir?uri=' || fn:encode-for-uri($uri), $uri, 'dir')
};

declare function v:croot-link($root as xs:string, $uri as xs:string)
{
   v:component-link($root || 'cdir?uri=' || fn:encode-for-uri($uri), $uri, 'dir')
};

(:~
 : Create a link to an iri.
 :
 : If the `$iri` has a short name, then it appends `/the:resource` after the
 : `$endpoint`.  If not, it uses `?rsrc=the-full-resource-iri` instead.  The
 : name of the parameter to use in the latter case is `$param`.
 :
 : $endpoint The endpoint.
 : $iri      The RDF resource.
 :)
declare function v:iri-link(
   $endpoint as xs:string,
   $iri      as xs:string,
   $decls    as element(c:decl)*,
   $kind     as xs:string,
   $param    as xs:string
)
{
   let $curie := v:shorten-resource($iri, $decls)
   return
      if ( $curie ) then
         v:component-link($endpoint || '/' || $curie, $curie, $kind)
      else
         v:component-link($endpoint || '?' || $param || '=' || fn:encode-for-uri($iri), $iri, $kind)
};

declare function v:rsrc-link($endpoint as xs:string, $iri as xs:string, $decls as element(c:decl)*)
{
   v:iri-link($endpoint, $iri, $decls, 'rsrc', 'rsrc')
};

declare function v:blank-link($endpoint as xs:string, $iri as xs:string, $decls as element(c:decl)*)
{
   v:iri-link($endpoint, $iri, $decls, 'blank', 'rsrc')
};

declare function v:class-link($endpoint as xs:string, $iri as xs:string, $decls as element(c:decl)*)
{
   v:iri-link($endpoint, $iri, $decls, 'class', 'super')
};

declare function v:prop-link($endpoint as xs:string, $iri as xs:string, $decls as element(c:decl)*)
{
   v:iri-link($endpoint, $iri, $decls, 'prop', 'rsrc')
};

declare function v:component-link($href as xs:string, $name as xs:string, $kind as xs:string)
   as element(h:a)
{
   <a xmlns="http://www.w3.org/1999/xhtml" href="{ $href }">
      <code class="{ $kind }">{ $name }</code>
   </a>
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Triple display tools
 :)

(:~
 : Shorten a resource URI, if a prefix can be found for it.
 :
 : The first entry in `$decls` that matches $uri (that is, the first one for which
 : $uri starts with the text value of) is used.  If there is no such entry, return
 : the empty sequence.
 :)
declare function v:shorten-resource($uri as xs:string, $decls as element(c:decl)*)
   as xs:string?
{
   v:find-prefix-by-uri($uri, $decls)
      ! ( c:prefix || ':' || fn:substring-after($uri, c:uri) )
};

(:~
 : Expand a CURIE notation to the full URI.
 :
 : The first entry in `$decls` that matches the prefix of the CURIE is used.  If
 : there is no such entry, the function returns the original one.
 :)
declare function v:expand-curie($curie as xs:string, $decls as element(c:decl)*)
   as xs:string
{
   let $prefix := fn:substring-before($curie, ':')
   let $decl   := $prefix[.] ! v:find-prefix-by-prefix(., $decls)
   return
      if ( fn:empty($decl) ) then
         $curie
      else
         $decl/c:uri || fn:substring-after($curie, ':')
};

(:~
 : Return the first matching prefix declaration, for a complete resource URI.
 :)
declare function v:find-prefix-by-uri($uri as xs:string, $decls as element(c:decl)*)
   as element(c:decl)?
{
   v:find-matching-prefix($decls, function($decl) {
      fn:starts-with($uri, $decl/c:uri)
   })
};

(:~
 : Return the first matching prefix declaration, for a given prefix.
 :)
declare function v:find-prefix-by-prefix($prefix as xs:string, $decls as element(c:decl)*)
   as element(c:decl)?
{
   v:find-matching-prefix($decls, function($decl) {
      $decl/c:prefix eq $prefix
   })
};

(:~
 : Return the first matching prefix declaration, for a given predicate.
 :)
declare function v:find-matching-prefix(
   $decls as element(c:decl)*,
   $pred  as function(element(c:decl)) as xs:boolean
) as element(c:decl)?
{
   if ( fn:empty($decls) ) then
      ()
   else if ( $pred($decls[1]) ) then
      $decls[1]
   else
      v:find-matching-prefix(fn:remove($decls, 1), $pred)
};
