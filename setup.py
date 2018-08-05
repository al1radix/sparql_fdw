import subprocess
from setuptools import setup, find_packages, Extension
from multicorn import ForeignDataWrapper
from multicorn.utils import log_to_postgres
from SPARQLWrapper import SPARQLWrapper2


setup(
  name='sparqlfdw',
  version='0.0.1',
  author='alain Radix',
  license='Postgresql',
  packages=['sparqlfdw']
)
