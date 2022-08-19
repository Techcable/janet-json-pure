janet-json-pure
===============
A lightweight pure-janet implementation of json.

Uses builtin PEG engine for parsing, allowing it to fit in a single file less than 100 lines.

For speed (or better error messages), please prefer the official module.

## Installation & Packaging
The prefered method of "installation" is to just copy this project
directly into your project.

However, it is also usable as a `jpm` package.
You can run `jpm install` and it will be installed as `pure/janet` module.

The "pure" prefix helps reflect its difference from the regular `json` module (and avoids conflicts).

## TODO
- **HIGH**: Implement *encoding*
- More flexiblity on encoding (callbacks?)
- Register on official package list
- Support bigints through [janet-big](https://github.com/andrewchambers/janet-big)?
