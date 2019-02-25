xquery version "1.0" encoding "UTF-8";

(: paste the result of step 1 into the variable below to generate the register :)

declare namespace loop="http://kb.dk/this/getlist";

declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace fn="http://www.w3.org/2005/xpath-functions";
declare namespace file="http://exist-db.org/xquery/file";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace ft="http://exist-db.org/xquery/lucene";
declare namespace ht="http://exist-db.org/xquery/httpclient";

declare namespace local="http://kb.dk/this/app";
declare namespace m="http://www.music-encoding.org/ns/mei";

declare option exist:serialize "method=xml media-type=text/html"; 

declare variable $database := "/db/dcm";
declare variable $collection := request:get-parameter("c","");

declare variable $names := 
    <div xmlns="http://www.music-encoding.org/ns/mei" id="names">
        <!-- Replace this <div> with the one generated by name_index_step1.xq                       -->
        <!-- Breaking up the list into smaller chunks may be necessary to avoid connection timeout. --> 
    </div>
;

declare function loop:clean-names ($key as xs:string) as xs:string
{
  (: strip off any text not part of the name (marked with a comma or parentheses) :)
  let $txt := concat(translate(normalize-space($key),',;(','***'),'*')
  return substring-before($txt,'*') 
};

declare function loop:invert-names ($key as xs:string) as xs:string
{
  (: put last name first; invert at last space in name string :)
  let $txt := 
  if(contains($key,' ')) then
    concat(tokenize($key,"\s+")[last()],', ',substring($key,1,string-length($key)-string-length(tokenize($key,"\s+")[last()])))
  else 
    $key 
  return $txt 
};

declare function loop:invert-namesAtFirstSpace ($key as xs:string) as xs:string
{
  (: put last name first; invert at first space in name string :)
  let $txt := 
  
  if(contains($key,' ')) then
    concat(normalize-space(substring-after($key,' ')),', ', normalize-space(substring-before($key,' ')))
  else 
    $key 
  return $txt 
};

declare function loop:sort-key ($num as xs:string) as xs:string
{
  let $sort_key:=
      (: make the number a 15 character long string padded with zeros :)
      let $padded_number:=concat("0000000000000000",normalize-space($num))
      let $len:=string-length($padded_number)-14
	return substring($padded_number,$len,15)
  return $sort_key
};

<html xmlns="http://www.w3.org/1999/xhtml">
	<body>

    <h2>Names</h2>
    <!-- Names appearing in <workList> or <sourceDesc> only)-->
    <div>
 
		    {
		    
		          if($collection="") then
                    <p>Please choose a file collection/catalogue by adding &apos;?c=[your collection name]&apos; 
                    (for instance, ?c=CNW) to the URL</p>
                  else 
		    
                    for $c in $names/*
            		(: Add exception to above xPath to exclude the composer, e.g. " [not(contains(.,'Carl Nielsen'))]"  :)
                    order by loop:invert-names($c)
            	    return
            		  <div>{concat(loop:invert-names($c),' &#160; ',$collection,' ')} 
            		  {let $numbers :=
            		  for $n in collection($database)/m:mei/m:meiHead[m:fileDesc/m:seriesStmt/m:identifier[@type="file_collection"] = $collection]
                         where $n/(m:workList | m:fileDesc/m:sourceDesc)//m:persName[normalize-space(loop:clean-names(string())) = $c]
                         (: to include only first performances:  where contains($n/(m:workList | m:fileDesc/m:sourceDesc)//m:persName[not(local-name(..)='event' and count(../preceding-sibling::m:event)>0)],$c)  :)

                         order by loop:sort-key(string($n/m:workList/m:work/m:identifier[@label=$collection])) 
                	     return $n/m:workList/m:work/m:identifier[@label=$collection]/string()
                	   return string-join($numbers,', ') 
                   	   } 
                	   </div>

            }
    </div>


  </body>
</html>
