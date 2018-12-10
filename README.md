# Deeps #

Developping addons using Ace

- the ace subsystem goes inside the `<addon>/Lib` folder.
- the initial ace libraries we will use are:
    - AceAddon-3.0
    - AceDB-3.0
    - AceConfig-3.0
    - AceConsole-3.0
    - AceEvent-3.0
    - AceGUI-3.0
    - CallbackHandler-1.0
    - LibStub
- an ace library is contained in its own folder (e.g. `<addon>/Lib/AceDB-3.0/`), and ifrmed by a `.lua` file and a `.xml` file.
- these library files are loaded from an `embeds.xml` file that must be saved in the `<addon>` folder. this file must also be in `<addon>.toc` file, but not the files loaded by it:
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
