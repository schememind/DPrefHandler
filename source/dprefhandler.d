module dprefhandler;

import std.stdio;
import std.conv: to;
import std.process: environment;
import std.file: mkdirRecurse, exists;
import std.exception: basicExceptionCtors;

/**
Collection of preferences, addressed by names, each containing actual value,
initial value and default value.
*/
class DPrefHandler
{
private:
    // TODO switch to dchar and dstring
    static const string ROW_PREFIX = ":::::";
    static const char EQSIGN = '=';
    static const string CFG_FILE_NAME = "config.ini";
    version(Windows)
    {
        static const string PATH_SEP = "\\";
    }
    version(Posix)
    {
        static const string PATH_SEP = "/";
    }

    string _name, _configDirectoryPath;
    DPref[string] prefs;

    /**
    Fill the value of class variable _configDirectoryPath with directory
    which stores the config file.
    */
    void generateConfigDirectoryPath()
    {
        string appDataDir = null;
        version(Windows)
        {
            appDataDir = environment.get("APPDATA");
        }
        version(linux)
        {
            appDataDir = "~/.local/share";
        }
        version(OSX)
        {
            appDataDir = "~/Library/Application Support";
        }
        if (appDataDir !is null)
        {
            _configDirectoryPath = appDataDir ~ PATH_SEP ~ name;
        }
    }
    
public:
    /**
    Constructs instance of DPrefHandler.
    pName is later used as directory name in OS user preferences directory.
    */
    this(string pName)
    {
        name = pName;
        generateConfigDirectoryPath;
    }
    
    /**
    Fill actual and initial values of all existing preferences, as well as
    create new preferences with initial == existing == default values, from
    config file, that is stored in OS user preferences directory.

    Loading of values from file does not happen in constructor!
    First developer creates the instance, then adds prefs with default values,
    only after that pref values can be populated from file by calling this method.
    If file has a pref that is no defined by developer, new pref is created automatically.
    */
    string loadFromFile()
    {
        if (configDirectoryPath !is null)
        {
            mkdirRecurse(configDirectoryPath);
            string fileFullPath = configDirectoryPath ~ PATH_SEP ~ CFG_FILE_NAME;
            if (!exists(fileFullPath)) {
                return null;
            }

            File file = File(fileFullPath, "r");

            char[] buf;
            while (!file.eof)
            {
                char[] line = buf;
                file.readln(line);
                if (line.length > ROW_PREFIX.length + 1)
                {
                    if (line[0..ROW_PREFIX.length] == ROW_PREFIX)
                    {
                        // Start of the config line
                        foreach (size_t i, char c; line[ROW_PREFIX.length..$])
                        {
                            if (c == EQSIGN)
                            {
                                string key = line[ROW_PREFIX.length..ROW_PREFIX.length + i].idup;
                                string value = line[ROW_PREFIX.length + i + 1..$ - 1].idup;
                                try
                                {
                                    // Key already exists
                                    prefs[key].actualValue = value;
                                    prefs[key].initialValue = value;
                                }
                                catch (core.exception.RangeError e)
                                {
                                    // Key does not exist yet
                                    prefs[key] = new DPref(key, value);
                                }
                                break;
                            }
                        }
                    }
                }
                else
                {
                    // TODO
                }
            }
            debug writeln(this);
            return file.name;
        }
        return null;
    }
    
    /**
    Save actual values of all preferences to config file,
    that is stored in OS user preferences directory.
    */
    string saveToFile()
    {
        if (configDirectoryPath !is null)
        {
            mkdirRecurse(configDirectoryPath);
            File file = File(configDirectoryPath ~ PATH_SEP ~ CFG_FILE_NAME, "w+");
            foreach (key; prefs.byKey)
            {
                file.writeln(ROW_PREFIX ~ key ~ EQSIGN ~ prefs[key].actualValue);
            }
            return file.name;
        }
        return null;
    }
    
    /**
    Create new preference or overwrite an existing one.
    */
    DPrefHandler addPref(T)(string name, T defaultValue)
    {
        // TODO validate name, replace spaces with _, etc
        prefs[name] = new DPref(name, to!string(defaultValue));
        return this;
    }
    
    /**
    Get actual value of preference specified by provided name.
    Throws DPrefException if preference with provided name does not exist.
    */
    T getActualValue(T)(string propertyName)
    {
        try
        {
            return to!T(prefs[propertyName].actualValue);
        }
        catch (core.exception.RangeError e)
        {
            throw new DPrefException(
                DPrefException.NO_PREF_FOUND ~ propertyName);
        }
    }

    /**
    Get iniital value of preference specified by provided name.
    Throws DPrefException if preference with provided name does not exist.
    */
    T getInitialValue(T)(string propertyName)
    {
        try
        {
            return to!T(prefs[propertyName].initialValue);
        }
        catch (core.exception.RangeError e)
        {
            throw new DPrefException(
                DPrefException.NO_PREF_FOUND ~ propertyName); 
        }
    }
    
    /**
    Get default value of preference specified by provided name.
    Throws DPrefException if preference with provided name does not exist.
    */
    T getDefaultValue(T)(string propertyName)
    {
        try
        {
            return to!T(prefs[propertyName].defaultValue);
        }
        catch (core.exception.RangeError e)
        {
            throw new DPrefException(
                DPrefException.NO_PREF_FOUND ~ propertyName); 
        }
    }
    
    /**
    Set provided value as actual value of preference specified by provided name.
    Throws DPrefException if preference with provided name does not exist.
    */
    void setActualValue(T)(string propertyName, T actualValue)
    {
        try
        {
            prefs[propertyName].actualValue = to!string(actualValue);
        }
        catch (core.exception.RangeError e)
        {
            throw new DPrefException(
                DPrefException.NO_PREF_FOUND ~ propertyName); 
        }
    }

    /**
    Revert actual value to initial one for the preference specified by provided name.
    Throws DPrefException if preference with provided name does not exist.
    */
    void revertActualToInitial(string propertyName)
    {
        try
        {
            prefs[propertyName].actualValue = prefs[propertyName].initialValue;
        }
        catch (core.exception.RangeError e)
        {
            throw new DPrefException(
                DPrefException.NO_PREF_FOUND ~ propertyName); 
        }
    }

    /**
    Revert actual values of all preferences to initial values.
    */
    void revertAllActualToInitial()
    {
        foreach (key; prefs.byKey)
        {
            revertActualToInitial(key);
        }
    }

    /**
    Revert actual value to default one for the preference specified by provided name.
    Throws DPrefException if preference with provided name does not exist.
    */
    void revertActualToDefault(string propertyName)
    {
        try
        {
            prefs[propertyName].actualValue = prefs[propertyName].defaultValue;
        }
        catch (core.exception.RangeError e)
        {
            throw new DPrefException(
                DPrefException.NO_PREF_FOUND ~ propertyName); 
        }
    }

    /**
    Revert actual values of all preferences to default values.
    */
    void revertAllActualToDefault()
    {
        foreach (key; prefs.byKey)
        {
            revertActualToDefault(key);
        }
    }
    
    /// Get name of the preference handler (used as name of the config directory)
    string name() const @property
    {
        return _name;
    }
    
    /// Set name of the preference handler (used as name of the config directory)
    void name(string name) @property
    {
        // TODO generate default name if empty or null
        _name = name;
    }

    /// Get path of the config directory
    string configDirectoryPath() const @property
    {
        return _configDirectoryPath;
    }
    
    override string toString() const pure @safe
    {
        string result = _name ~ ":[";
        foreach (key; prefs.byKey)
        {
            result ~= "{" ~ key ~ " : act(" ~ prefs[key].actualValue
                ~ "), ini(" ~ prefs[key].initialValue
                ~ "), def(" ~ prefs[key].defaultValue ~ ")}";
        }
        result ~= "]";
        return result;
    }
}

/**
Single preference contains:
- name
- actual value
- initial value
- default value
*/
private class DPref
{
private:
    string name;
    string defaultValue;
    string initialValue;
    string actualValue;
    
public:
    this(string name, string defaultValue)
    {
        this.name = name;
        this.defaultValue = defaultValue;
        this.initialValue = defaultValue;
        this.actualValue = defaultValue;
    }
}

/**
Common Exception
*/
class DPrefException : Exception
{
    private static const string NO_PREF_FOUND = "No preference found by key: ";
    /// Constructor for an extended exception
    mixin basicExceptionCtors;
}