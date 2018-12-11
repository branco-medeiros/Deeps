# Deeps #

## Developping addons using Ace

### Preparing the environment

> *Steps learned at the
[Getting Started site](https://wow.gamepedia.com/WelcomeHome_-_Your_first_Ace3_Addon)
and
[the Ace3 getting started site](https://www.wowace.com/projects/ace3/pages/getting-started)*

- The ace subsystem goes inside the `<addon>/Lib` folder.
- The initial ace libraries we will use are:
    - **LibStub**:
      used to access the other libraries
    - **AceAddon-3.0**:
      creates the addon
    - **AceDB-3.0**:
      provides profiles for the addon's variables
    - **AceConfig-3.0**:
      provides configuration options and slash commands
    - **AceConsole-3.0**:
      print and slash commands
    - **AceEvent-3.0**:
      handle wow events and create events
    - **AceGUI-3.0**:
      used to create UI elements
    - **CallbackHandler-1.0**:
      ???

- An ace library is contained in its own folder (e.g. `<addon>/Lib/AceDB-3.0/`), and is composed of a `.lua` file and a `.xml` file.
- These library files are loaded from an `embeds.xml` file that must be saved in the `<addon>` folder. This file must also be in `<addon>.toc` file, but not the files loaded by it:

```
  <Ui xmlns="http://www.blizzard.com/wow/ui/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.blizzard.com/wow/ui/
  ..\FrameXML\UI.xsd">
      <Script file="Libs\LibStub\LibStub.lua"/>
      <Include file="Libs\CallbackHandler-1.0\CallbackHandler-1.0.xml"/>
      <Include file="Libs\AceAddon-3.0\AceAddon-3.0.xml"/>
      <Include file="Libs\AceEvent-3.0\AceEvent-3.0.xml"/>
      <Include file="Libs\AceDB-3.0\AceDB-3.0.xml"/>
      <Include file="Libs\AceConsole-3.0\AceConsole-3.0.xml"/>
      <Include file="Libs\AceGUI-3.0\AceGUI-3.0.xml"/>
      <Include file="Libs\AceConfig-3.0\AceConfig-3.0.xml"/>
  </Ui>
```


> Even though the addon `.toc` file references both the `embeds.xml` file and the main `<addon>.lua` file, why not load the lua file from the embeds file itself?


### Accessing addons

Addons can be accessed as mixins or as stand-alone objects.

- As mixins: loaded when the addon is created by `AceAddon`.

```
    local Deeps = LibStub("AceAddon-3.0"):NewAddon(
      "Deeps", --- the addon name
      -- mixins: add their own methods to the main object
      "AceConsole-3.0",
      "AceConfig-3.0",
      ...
    )
```


- As standalone: loaded by `LibStub`:

```
    local AceAddon = LibStub("AceAddon-3.0")
    local AceConsole = LibStub("AceConsole-3.0")
```


### Initilizing the addon

- To initialize the addon via Ace, create the addon with AceAddon:

```
    AddonName = LibStub("AceAddon-3.0"):NewAddon(
      "addon name",
      list of mixins
    )
```

  Most of the libraries will be loaded as mixins(e.g. `AceConsole-3.0`, `AceEvents-3.0`)

- The addon should then handle the following overrides:

```
    function AddonName:OnInitialize()
    --- called once, when the ui loads
    --- register events, e.g.
      self:RegisterEvent("EVENT_NAME")
    end

    function AddonName:OnEnable()

    end

    function AddonName:OnDisable()

    end

    --- handle events:
    function AddonName:EVENT_NAME(...)

    end
```
