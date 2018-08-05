# -*- coding: utf-8 -*-

from multicorn import ForeignDataWrapper, ColumnDefinition
from multicorn.utils import log_to_postgres, DEBUG, INFO, ERROR, WARNING, CRITICAL
import dateutil.parser		# from rpm python-dateutil
import datetime


from SPARQLWrapper import SPARQLWrapper, JSON

import json

class SparqlForeignDataWrapper(ForeignDataWrapper):

    def __init__(self, options, columns):
        super(SparqlForeignDataWrapper, self).__init__(options, columns)
        self.columns = columns
        self.options = options

    def execute(self, quals, columns):
        try:
            # log options
            log_to_postgres('sparqlfdw columns : %s' % ( str(self.columns) ), DEBUG)
            log_to_postgres('sparqlfdw options : %s' % ( str(self.options) ), DEBUG)

            # create sparql wrapper with enpoint url
            sparql = SPARQLWrapper(self.options['endpoint'])

            query=self.options['sparql']

            sparql.setQuery(query)
            log_to_postgres('sparqlfdw request : %s' % ( query ), DEBUG)

            sparql.setReturnFormat(JSON)


            results = sparql.query().convert()

	    #log_to_postgres('sparqlfdw results %s'%(str(results["results"]["bindings"])), DEBUG)

            for result in results["results"]["bindings"]:
	        #log_to_postgres('sparqlfdw result : %s'%(result), DEBUG)
                line = {}
                for column_name in self.columns:
                    if column_name in result:
                        #line[column_name] = result[column_name]['value']
                        line[column_name] = self.json2column(result[column_name], self.columns[column_name])
                    else:
                        line[column_name] = None
                    #log_to_postgres('yeld result %s for column %s'%(line[column_name], column_name))

                #log_to_postgres('yeld result line %s'%(str(line)))
                yield line

	    log_to_postgres('sparqlfdw query finished',DEBUG)

        except Exception as e:
            log_to_postgres(str(e), ERROR)
            raise

    def json2column(self, result, column ):
        ''' result is for the moment in json format and column is ColumnDefinition objeect'''
        try:
    
            def json2text(result):
                return result['value']
    
            def json2json(result):
                return json.dumps(result)
    
            def json2int(result):
                return int(result['value'])
    
            def json2real(result):
                return float(result['value'])
    
            def json2timestamp(result):
                return dateutil.parser.parse(result['value'])
    
            def json2time(result):
                return (dateutil.parser.parse(result['value']).time())
    
            def json2timetz(result):
                return (dateutil.parser.parse(result['value']).timetz())
    
            transformFunction={
                'json' : json2json,
                'text' : json2text,
                'character varying' : json2text,
                'integer' : json2int,
                'double precision' : json2real,
                'real' : json2real,
                'date' : json2timestamp,
                'time without time zone' : json2time,
                'time with time zone' : json2timetz,
                'timestamp with time zone' : json2timestamp,
                'timestamp without time zone' : json2timestamp,
                }
    
            return transformFunction[column.base_type_name](result)

        except Exception as e:
    	    log_to_postgres('sparqlfdw error %s json2column( result %s column %s'%(str(e), result, column), ERROR)
    	    raise
    
