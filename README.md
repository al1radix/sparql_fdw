# Sparql FDW for PostgreSQL
sparql_fdw is experimantal code

## Installation
* CentOs 7 install with postgresql installed from PGDG repository
Install multicorn
```
yum install multicorn10
```

Install needed packages
```
yum install -y epel-release
yum install -y python-setuptools git python-pip python-dateutil
pip install --upgrade pip
pip install SPARQLWrapper
```

clone and execute 'python setup.py install' as root
```
git clone git@bitbucket.org:al1radix/sparql_fdw.git
cd sparql_fdw
python setup.py install
```

## Usage
### create multicorn extension
```
create extension multicorn;
```
### create server
```
CREATE server wikidata foreign data wrapper multicorn
	options ( wrapper 'sparqlfdw.SparqlForeignDataWrapper', endpoint 'https://query.wikidata.org/sparql');

CREATE server dbpedia foreign data wrapper multicorn
	options ( wrapper 'sparqlfdw.SparqlForeignDataWrapper', endpoint 'http://dbpedia.org/sparql' );
```

### Create foreign tables with sparql query
* matching is done between table's column names and sparql selected variables names

```
-- tropical fruits from dbpedia
CREATE FOREIGN TABLE tropical_fruits ( fruit text, label text, object json )
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

-- eyes colors from wikidata
CREATE FOREIGN TABLE eyes ( "eyeColorLabel" json, count int, rien text )
server wikidata options ( sparql 'SELECT ?eyeColorLabel (COUNT(?human) AS ?count)
WHERE { ?human wdt:P31 wd:Q5.  ?human wdt:P1340 ?eyeColor.
SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". } }
GROUP BY ?eyeColorLabel ');
```

The actual implementation is simplist and don't push down restriction, group by, order by nor limit to sparql

