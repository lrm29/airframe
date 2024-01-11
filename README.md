# SysML XMI Importer
## Import SysML 1.6 Models into MathWorks Tools

This PSP is an extension of the XMI PSP that ships with the product and aims to import other constructs from XMI files.

So far, activity diagrams have been added. 

To import activity diagrams, use:
importActivityDiagrams('my_sysml_file.xml');

A new folder will be created with a top-level package model and a subfolder with the activities. The elements in the activity diagrams are tagged with the XMI IDs from the xml file.
Stereotypes and properties are not currently imported. 
Model reference is not supported yet so referenced activities are built in place.

## R2024A Pre-Release