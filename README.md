# gdcl - GoldenDict command-line interface written in Ruby

gdcl is a command-line interface for searching [GoldenDict](https://github.com/goldendict/goldendict) dictionaries. A request for a command-line version is currently [the third most commented issue](https://github.com/goldendict/goldendict/issues/37) on the GoldenDict issue tracker. This script is a very rudimentary workaround to allow searching through groups of dictionaries until an official command-line interface is available.

As an example of a similar interface, [StarDict](http://code.google.com/p/stardict-3/) has [sdcv](http://sdcv.sourceforge.net/) (StarDict Console Version), but it can only handle dictionaries in the StarDict format. For users of GoldenDict who have dictionaries in other formats (e.g. DSL or BGL), converting and maintaining two parallel sets of dictionaries is not a practical solution.

This script answers a practical need: namely the ability to search through groups of dsl format dictionaries from the command-line over ssh. The script can be used to search dictionaries interactively, but also has an interactive mode which allows results from GoldenDict dictionaries to be piped to standard output or used as part of a toolchain.

Currently, gdcl does not require an installation of GoldenDict, as it simply searches through predetermined groups of dictionaries in the GoldenDict folder (which can be configured) and could conceivably be used to search through any collection of dsl format dictionaries. However, the eventual goal of the project is to read preferences from GoldenDict's config file, support the full range of formats that GoldenDict can use and, ideally, to use GoldenDict's pre-made index files for faster searching.


## Usage
### Summary

Interactive search:

  `ruby gdcl.rb`

Non-interactive search:

  `ruby gdcl.rb [group] [keyword]`

See below for configuration and usage details.

### Setup and configuration
#### gdcg.rb
The easiest way to set up dictionaries for use with gdcl is to use the **gdcg.rb** script, which can automatically configure groups of dictionaries for quick searching. By default this looks in the `.goldendict` directory located in the user's home folder, but it can be configured to use any folder containing zipped dsl dictionaries (i.e.: files with the extension .dsl.dz).

If you use gdcg.rb, it assumes that your dictionaries are located in a folder `dic` in your GoldenDict directory, separated into subdirectories representing groups of dictionaries that you would like to search. For example, English dictionaries might be in a subfolder called `en`, French dictionaries in `fr`, and Chemistry dictionaries in a folder `chem`. Using gdcl allows you to search through these groups individually, similar to the way GoldenDict does.

Alternatively, you can just point the gdcl.rb script at any folder containing _unzipped_ dsl files and avoid the need to use gdcg.rb altogether.

#### gdcl.rb
The script for actually searching through the dictionary is called **gdcl.rb**.

There are a number of configuration options available in the `config.yml` file. By default, this file should be installed in the standard config folder under the user's home directory (i.e., in the folder `~/.config/gdcl`). If gdcl can't find the file `config.yml` in that folder, it will look for it in $XDG_CONFIG_DIRS (i.e., `/etc/xdg/gdcl`), and failing that, the script folder (i.e., the same directory as the script executable). The `~/.config/gdcl` folder and default `config.yml` file will be created if they do not already exist when you first run gdcl.

The options available in config.yml are commented and should be self-explanatory. They are listed below for reference:

* `group`: _Group name_ (either a subfolder of your GoldenDict home directory setup by gdcg.rb, or any arbitrary folder located [by default] in the script's `tmp` directory
* `kword`: _Keyword to search for_ (use this to specify a keyword in the script; if not specified here, gdcl will search for a term provided either interactively or on the command line)
* `interactive_search`: _Interactive search_ (Set to false for non-interactive search, e.g. to pipe or redirect the search results; defaults to false if a group and keyword are specified as command-line parameters)
* `header_footer`: _Header and footer information_ (Set to false to turn off header and footer information, i.e.: dictionary name and number of hits for search term)
* `temp_dir`: _Temporary working directory_ (The directory where gdcl will store files)
* `search_term`: _Search pattern_ (Specify a pattern to search for; default is headwords starting with _keyword_, but strict matches or any other regex are also supported)
* `del_dict`: _Excluded dictionaries_ (Optionally exlude the specified dictionaries from search results)
* `markup`: _DSL Markup Options_ (Defaults to removing dsl dictionary markup in results; to display markup, comment out this line and uncomment the line `markup = ""`)
* `markup_replace`: _DSL Markup Replacement String_ (Change this if you want to replace dsl markup with some other string)


### Searching

By default, invoking gdcl with the command `ruby gdcl.rb` will search interactively. Command prompts will ask you to specify a group of dictionaries to search in out of a list of available groups, and then a keyword to look for. Results will be displayed immediately to standard output.

In interactive mode, after the search results have finished displaying, there is an option to view the results in a paging program (by default `less`). This is helpful if there are many results or if results exceed the terminal buffer size.

Alternatively, you can use non-interactive mode to search and pipe results to a file or other programs. gdcl will default to interactive mode if a group and keyword are specified as command-line parameters:

  `ruby gdcl.rb [group] [keyword]`

For example, if you want to search for the term _aardvark_ in the _en_ dictionary group, you can use:

  `ruby gdcl.rb en aardvark`

As always, it is a good practice to quote or escape search strings, and this is mandatory for terms that contain e.g. spaces:

  `ruby gdcl.rb en "monkey wrench"`

To pipe dictionary search results to a file:

  `ruby gdcl.rb en "monkey wrench" > output.txt`


## To do

Features that need to be implemented:
* Read search and dictionary preferences from GoldenDict config file
* Search using GoldenDict's existing index files
* Dictzip support (i.e. search dictionaries in place rather than needing to unzip them to tmp folder)
* bgl, dict and other formats support
* Online dictionaries support (Wikipedia, Wiktionary etc)


## License

MIT -- see LICENSE file for details.
