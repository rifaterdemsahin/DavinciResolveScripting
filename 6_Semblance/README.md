# 6_Semblance - Error Logs and Solutions

## Common Issues

### API Limitations

* *Issue*: Unable to change specific node parameters in Color Page via API.
* *Workaround*: Use preset `.drx` grades and apply them via script.

### Audio Normalization

* *Issue*: Native "Normalize Audio Levels" command might not be directly exposed in API.
* *Solution*: creating a macro or using fairlight automation data if direct command unavailable.

### Debugging

* Use `print()` which outputs to the Resolve console.
* Check `C:\ProgramData\Blackmagic Design\DaVinci Resolve\Support\logs\` for crash dumps.
