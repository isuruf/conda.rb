# Conda

## Installation

Execute:

    gem install conda --user

Note: `--user` switch is important as conda.rb needs to be installed in a 
writable folder.

## Usage

To use the package do:

    require 'conda'

To install a conda package do

    Conda.add("jupyter")

To use a custom channel do

    Conda.add_channel("conda-forge")

To update a package do

    Conda.update("jupyter")

To install a specific version of a package do

    Conda.install("jupyter==1.0")

To get the version of a package do

    Conda.version("jupyter")

## Development

    gem build conda.gemspec
    gem install conda-0.1.0.gem

## License

The gem is available as open source under the terms of the 
[MIT License](https://github.com/isuruf/conda.rb).

