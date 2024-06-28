# SysML Connector
## Import SysML 1.x Models into MathWorks Tools

This PSP is a replacement of the XMI PSP that ships with R2024a and earlier releases of MATLAB.

### This PSP imports:
- Architectures (SysML:Block), Ports, Connectors, Interfaces, Parameters, Stereotypes Property Values
- Profiles, Stereotypes, Stereotype Properties
- Requirements (No stereotypes for now)
- Activity Diagrams (No stereotypes or Swimlanes for now)
- Sequence Diagrams

**To-Do:**
- State Diagrams
- Use Case Diagrams

### This PSP exports:
- Architectures, Ports, Connectors, Interfaces

### Usage
**To import:**
SysMLConnector.import('my_sysml_file.mdzip');
SysMLConnector.import('my_sysml_file.xml');

**To export:**
SysMLConnector.export(systemcomposer.loadModel('MyModel'), 'my_sysml_file');


## Requires R2024A Update 2