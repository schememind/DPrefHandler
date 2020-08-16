# DPrefHandler
*WARNING: This library is in the early stage of development!*

Simple D language library for managing and storing of preferences of desktop applications (Windows, Linux, OS X)

## Usage
### DUB
Add dependency your project's DUB description file and perform `import dprefhandler;` in a module that would use it.
#### dub.json format:
```json
"dependencies": {
    "dprefhandler": "~>0.0.1"
},
```
### Direct usage
Copy `dprefhandler.d` source file into your project's directory and perform `import dprefhandler;` in a module that would use it.

## Build
To build the source code as a library, navigate into project's root directory and run DUB command: `dub build`

## Example
TODO
```d
import dprefhandler;

// Create instance of DPrefHandler
DPrefHandler dph = new DPrefHandler("yourappname");

// Set preferences' names with their default values
dph
    .addPref!int("winX", 45)
    .addPref!int("winY", 30)
    .addPref!bool("fullscreen", false)
    .addPref!string("font", "Consolas")
    .addPref!size_t("init_array_size", 100)
;

// Load actual values from config file (located in OS user directory)
dph.loadFromFile;

// Change actual values of some preferences
dph.setActualValue!int("winX", 145);
dph.setActualValue!int("winY", 230);

// Save actual values to config file (located in OS user directory)
dph.saveToFile;
```
