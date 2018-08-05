


\timing

-- create wikidata server
drop server IF EXISTS wikidata cascade
CREATE server if not exists wikidata foreign data wrapper multicorn 
options ( wrapper 'sparqlfdw.SparqlForeignDataWrapper', endpoint 'https://query.wikidata.org/sparql');

-- create dbpedia server
drop server IF EXISTS dbpedia cascade;
CREATE server if not exists dbpedia foreign data wrapper multicorn options ( wrapper 'sparqlfdw.SparqlForeignDataWrapper', endpoint 'http://dbpedia.org/sparql' );


-- type testing
-- character types
CREATE FOREIGN TABLE if not exists chartest ( t_character_varying character varying(25), t_varchar varchar(25), t_character character(25), t_char char(25), t_text text, float_ double precision  ) 
server wikidata options ( sparql '
SELECT ?t_character_varying ?t_varchar ?t_character ?t_char ?t_text where {
BIND ("toto" as ?t_character_varying)
BIND ("toto" as ?t_varchar)
BIND ("toto" as ?t_character)
BIND ("toto" as ?t_char)
BIND ("toto" as ?t_text)
}
');

-- numeric types
CREATE FOREIGN TABLE if not exists numtest ( t_float double precision  ) 
server wikidata options ( sparql '
SELECT ?t_float where {
BIND ("3.146" as ?t_float)
}
');

-- date testing
--CREATE FOREIGN TABLE if not exists datetest ( now_text text, now_date date, now_timestamp timestamp  ) 
CREATE FOREIGN TABLE if not exists datetest ( now_text text, now_date date, now_time time, now_timetz time with time zone, now_timestamp timestamp  ) 
server wikidata options ( sparql '
SELECT ?now_text ?now_date ?now_time ?now_timetz ?now_timestamp
WHERE
{
	BIND(NOW() as ?now_text).
	BIND(NOW() as ?now_date).
	BIND(NOW() as ?now_time).
	BIND(NOW() as ?now_timetz).
	BIND(NOW() as ?now_timestamp).
}
');



-- tropical fruits
CREATE FOREIGN TABLE if not exists tropical_fruits ( fruit text, label text, object json ) 
server dbpedia options ( sparql 'PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?fruit ?label ?object
WHERE {
  ?fruit dct:subject dbc:Tropical_fruit .
  ?fruit ?property ?object .
  ?property rdfs:label ?label
  filter(langMatches(lang(?label),"EN"))
  filter(?label != "Link from a Wikipage to another Wikipage"@en)
}
' );

create materialized view tropical_fruits_mv as select * from tropical_fruits;

-- couleur des yeux
CREATE FOREIGN TABLE if not exists yeux ( "eyeColorLabel" json, count int, rien text ) 
server wikidata options ( sparql 'SELECT ?eyeColorLabel (COUNT(?human) AS ?count) 
WHERE { ?human wdt:P31 wd:Q5.  ?human wdt:P1340 ?eyeColor.  
SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". } } 
GROUP BY ?eyeColorLabel ');

-- liste des chats
CREATE FOREIGN TABLE if not exists chats ( item text, "itemLabel" text ) 
server wikidata options ( 
  sparql 'SELECT ?item ?itemLabel 
WHERE { ?item wdt:P31 wd:Q146.
SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }}' );


CREATE FOREIGN TABLE if not exists asturia ( label text ) 
server dbpedia options ( sparql 'PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?label
WHERE {
	<http://dbpedia.org/resource/Asturias> rdfs:label ?label 
}');

CREATE FOREIGN TABLE if not exists country_properties ( country text, "propertyLabel" text, object json, "objectLabel" text )
server wikidata options ( sparql '
SELECT ?country ?propertyLabel ?object ?objectLabel WHERE {
  ?country wdt:P1705 "France"@fr .
  ?country ?p ?object .
  ?property wikibase:directClaim ?p .
    SERVICE wikibase:label {
        bd:serviceParam wikibase:language "en" .
    }
}
');

CREATE MATERIALIZED VIEW IF NOT EXISTS country_properties_mv
as select * from country_properties
--where object->>'type' in ('literal','uri')
;




CREATE FOREIGN TABLE if not exists desert_islands ( ile text, coord json, surface real, latitude real  ) 
server wikidata options ( sparql '
#defaultView:Map
SELECT ?ile  ?coord ?surface ?latitude WHERE {
  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
  ?ile (wdt:P31*/wdt:P279*) wd:Q23442.
  ?ile wdt:P2046 ?surface.
  BIND(geof:latitude( ?coord) as ?latitude) 
  ?ile wdt:P625 ?coord.
  ?ile wdt:P1082 0. .
filter ( ?latitude < 40 && ?latitude > -40).
}
order by desc(?surface)
');

-- events from wikidata
CREATE FOREIGN TABLE if not exists events ( event text, "eventLabel" text, event_date date  ) 
server wikidata options ( sparql '
SELECT ?event ?eventLabel ?event_date
WHERE
{
	?event wdt:P31/wdt:P279* wd:Q1190554.
	OPTIONAL { ?event wdt:P585 ?event_date. }
	OPTIONAL { ?event wdt:P580 ?event_date. }
	FILTER(BOUND(?event_date) && DATATYPE(?event_date) = xsd:dateTime).
	BIND(NOW() - ?event_date AS ?distance).
	FILTER(0 <= ?distance && ?distance < 31).
	OPTIONAL {
		?event rdfs:label ?eventLabel.
		FILTER(LANG(?eventLabel) = "en").
	}
}
LIMIT 5
');


