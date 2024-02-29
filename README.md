# SysML XMI Importer
## Import SysML 1.6 Models into MathWorks Tools

This PSP is a replacement of the XMI PSP that ships with R2024a and earlier releases of MATLAB.

This PSP imports:
- Architectures (SysML:Block), Ports, Connectors, Interfaces
- Requirements
- Activity Diagrams (No stereotypes or Swimlanes for now)
- Sequence Diagrams (Lifelines only for now)

To-Do:
- State Diagrams
- Use Case Diagrams

To import:
importSysML('my_sysml_file.xml');

## R2024A Pre-Release