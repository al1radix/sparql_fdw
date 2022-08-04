import subprocess
from setuptools import setup, find_packages, Extension
from multicorn import ForeignDataWrapper
from multicorn.utils import log_to_postgres
from SPARQLWrapper import SPARQLWrapper2


setup(
  name='sparqlfdw',
  version='0.1.0',
  author='alain Radix, Stefanie Janine Stölting',
  license='PostgreSQL',
  packages=['sparqlfdw']
)
