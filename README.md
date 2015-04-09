# gdcl - GoldenDict command-line interface written in Ruby

gdcl is a command-line interface for searching [GoldenDict](https://github.com/goldendict/goldendict) dictionaries. A request for a command-line version is currently [the third most commented issue](https://github.com/goldendict/goldendict/issues/37) on the GoldenDict issue tracker. This script is a very rudimentary workaround to allow searching through groups of dictionaries until an official command-line interface is available.

As an example of a similar interface, [StarDict](http://code.google.com/p/stardict-3/) has [sdcv](http://sdcv.sourceforge.net/) (StarDict Console Version), but it can only handle dictionaries in the StarDict format. For users of GoldenDict who have large collections of dictionaries in other formats (e.g. DSL or BGL), converting and maintaining two parallel sets of dictionaries is not a practical solution.

This script answers a practical need: namely the ability to search through groups of dictionaries from the command-line over ssh. The script can be used to search dictionaries interactively, but also has a non-interactive mode which allows results from GoldenDict dictionaries to be piped to standard output or used as part of a toolchain.

Currently, gdcl does not require an installation of GoldenDict, as it simply searches through subdirectories of existing dictionaries in the GoldenDict folder (which can be configured) and could conceivably be used to search through any collection of dictionaries in DSL format. However, the eventual goal of the project is to read preferences from GoldenDict's config file, support the full range of formats that GoldenDict can use and, ideally, to use GoldenDict's pre-made index files for faster searching.


* [1.1 Installation from distro packages](#installation-from-distro-packages)
  * [1.1.1 User packaged](#user-packaged)
* [2.1 Usage](#usage)
  * [2.1.1 Summary](#summary)
  * [2.1.2 Setup and configuration](#setup-and-configuration)
    * [2.1.2.1 gdcg.rb (deprecated)](#gdcgrb-deprecated)
    * [2.1.2.2 gdcl.rb](#gdclrb)
    * [2.1.2.3 forvo.rb](#forvorb)
  * [2.1.3 Searching](#searching)
  * [2.1.4 Options](#options)
* [3.1 Supported formats](#supported-formats)
* [4.1 To do](#to-do)
* [5.1 License](#license)


## Installation

To install you can either download the project source and run the scripts directly, or use a package manager to install the appropriate files for your distro. See below for more details and also the section on [setup and configuration](#setup-and-configuration) for how to customize your installation once you've downloaded the source files.


### Installation from Distro Packages
#### User Packaged
* ![logo](http://www.monitorix.org/imgs/archlinux.png "arch logo")Arch Linux: in the [AUR](https://aur.archlinux.org/packages/gdcl) and [Firef0x's Arch Linux Repository](http://firef0x.github.io/archrepo.html).

## Usage
### Summary

Interactive search:

  `ruby gdcl.rb`

Non-interactive search:

  `ruby gdcl.rb [group] [keyword]`

See below for configuration and usage details.

### Setup and configuration
#### gdcg.rb (deprecated)
* __note: this helper script has been phased out since gdcl now reads compressed dictionaries directly from the GoldenDict folder - the information below is provided for users who may have installed a legacy version of gdcl through their package manager, and will be removed once all distro packages have been updated__

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

See also the Options section for more details on how to specify some of these as command-line options.

#### forvo.rb
Looking up and playing back audio pronunciations from [Forvo](http://forvo.com/) is supported by gdcl using the `forvo.rb` script and mplayer. This requires registering for a [Forvo API key](http://api.forvo.com/), which is free for non-commercial educational use.

Once you have a key, you just need to copy it into your gdcl config file in your user home directory (i.e. `~/.config/gdcl/config.yml`) under the section "forvo key". Uncomment the line `# :forvo_key: ""` and add your key between the quotation marks `""`. Now you can look up pronunciations by running `forvo.rb`.

Similar to the main dictionary lookup, `forvo.rb` has both interactive and non-interactive modes. If run without any command-line arguments, it will prompt for a [language code](http://www.forvo.com/languages-codes/) and word to pronounce. You can find a full list of the supported codes [here](http://www.forvo.com/languages-codes/).

You can skip the prompts by supplying the language code and word to be pronounced as arguments when running `forvo.rb`, in the form `ruby forvo.rb [lang_code] [word_to_be_pronounced]`. For example, if you wanted to find the pronounciation of the word "сегодня" in Russian, you would enter:

`ruby forvo.rb ru сегодня`

The last argument should probably be in quotes to avoid problems -- this also allows for pronunciation of phrases and other terms with spaces:

`ruby forvo.rb sv "Johannes Robert Rydberg"`

The script will let you know how many pronunciations were found and print out a numbered list (example below):

* command: `ruby forvo.rb zh 发音`

* output:
```
4 pronunciations found for "发音" in zh:

  1. by Gliese (f from China)           0 [+1 -1]
  2. by witenglish (m from China)       0 [+0 0]
  3. by cloudrainner (m from China)     0 [+0 0]
  4. by JuliaWu (f from China)          0 [+0 0]


Select a number to hear the corresponding pronunciation, or press "a" to hear all available pronunciations.
```

To hear any of the listed pronunciations just enter the corresponding number and it will start playing automatically. If you press "a", all of the pronunciations will play in order. The numbers to the far right are the user rating that each pronunciation has received, in the format `rating [+upvotes -downvotes]`.

The Forvo script also has a number of options that can be supplied at the command-line:

* `-m`, `--mp3` (_Use mp3 format instead of ogg_)
* `-l`, `--list` (_List all pronunciations_)
* `-u`, `--urls` (_Print a list of audio urls_)
* `-a`, `--play-all` (_Play back all pronunciations without interaction_)
* `-s`, `--save` (_Save all audio files to disk_)

Many of these options can be combined, for example:

`ruby forvo.rb -lum en photogrammetry` (_Lookup the word "photogrammetry" and produce a list of pronunciations and urls in mp3 format_)

If you want to skip all interaction entirely and just play each audio result automatically, use the `-a` option and supply the language code and lookup terms on the command-line, e.g.:

`ruby forvo.rb -a fr prononciation`


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

### Options

Most default options can be configured in the user's config.yml file (see [here](#gdclrb) for more details on setting up the config.yml file).

There are also a number of settings that can be specified on the fly as command-line options. Use `ruby gdcl.rb -h` to print a list of all available command-line options. Currently, gdcl supports the following options:

* `-d DIRECTORY`, `--dict-directory DIRECTORY` (_Directory in which to look for dictionaries_)
* `-i FILENAMES`, `--ignore FILENAMES` (_List of dictionaries to ignore while searching_)
* `-g`, `--groups (_Print a list of all available dictionary groups_)
* `-l GROUP`, `--list GROUP (_List all dictionaries in specified group_)
* `-n`, `--no-headers (_Remove headers and footers from results output_)
* `-m`, `--markup (_Don't strip DSL markup from output_)

Most of these can be combined, e.g.: `ruby gdcl.rb -nm -d /path/to/dictionaries` to search in `/path/to/dictionaries` and print out results with no headers or footers and without stripping DSL markup.

Some options provide information that can be supplied to other options. For example, you can use `-g` to get a list of available groups, and then print out a list of all dictionaries in one of those groups using the `-l` option. The results of `-l` can, in turn, be used to specify a list of dictionaries to ignore with the `-i` option.


## Supported formats

gdcl currently supports compressed dictionary files in [ABBYY Lingvo .dsl dictionary format](http://lingvo.helpmax.net/en/troubleshooting/dsl-compiler/your-first-dsl-dictionary/) (i.e., files ending in the extension `.dsl.dz`) as well as online pronunciation audio files from Forvo.com (see [the section above](#forvorb) on using forvo.rb to look up pronunciations). Support for other formats and online dictionaries is planned for future releases.

## To do

Features that need to be implemented:
* Read search and dictionary preferences from GoldenDict config file
* Search using GoldenDict's existing index files
* ~~Dictzip support (i.e. search dictionaries in place rather than needing to unzip them to tmp folder)~~
* bgl, dict and other formats support
* Online dictionaries support (Wikipedia, Wiktionary etc)


## License

MIT -- see LICENSE file for details.
