xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "lib/admin.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function local:page()
   as element()+
{
   let $groups := a:get-groups()/a:group
   let $count := fn:count($groups)
   return
      <wrapper>
         {
            if ( $count eq 0 ) then
               <p>There is no group in this MarkLogic instance.  A bug, surely...</p>
            else if ( $count eq 1 ) then (
               <p>There is one single group in this MarkLogic instance:
                  <code>{ $groups[1]/xs:string(a:name) }</code>.</p>,
               <p>The app servers in the group are:</p>,
               local:appservers-table($groups)
            )
            else (
               <p>There are { $count } groups in this MarkLogic instance.</p>,
               for $g in $groups
               return (
                  <h4>Group <code>{ $g/a:name }</code></h4>,
                  <p>The app servers in the group are:</p>,
                  local:appservers-table($g)
               )
            )
         }
      </wrapper>/*
};

(:~
 : Return a table with all the app servers in the group.
 :)
declare function local:appservers-table($grp as element(a:group))
   as element(table)
{
   <table class="sortable">
      <thead>
         <td>Name</td>
         <td>Modules</td>
         <td align="center">Repo?</td>
      </thead>
      <tbody> {
         for $as in a:get-appservers($grp)/a:appserver
         let $id   := $as/fn:string(@id)
         let $name := $as/fn:string(a:name)
         order by $name
         return
            <tr>
               <td>
                  <a href="appserver/{ $id }">{ $name }</a>
               </td>
               <td> {
                  if ( fn:exists($as/a:modules-db) ) then
                     fn:string($as/a:modules-db) || ' *'
                  else
                     fn:string($as/a:modules-path)
               }
               </td>
               <td align="center"> {
                  if ( fn:exists(a:appserver-get-packages($as)) ) then
                     '&#x2611;'
                  else
                     '&#x2610;'
               }
               </td>
            </tr>
      }
      </tbody>
   </table>
};

v:console-page('', 'pkg', 'Packages', local:page#0)
