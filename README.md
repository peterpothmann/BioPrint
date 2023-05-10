# BioPrint

## Resources that need to be uploaded:
1. Einteilung der Arten in habitat kategorien (x) -->  species-response-spill-over-parameter.csv
2. PDF-Dateien der Module der Abbildungen (kann vielleicht auch in die Shiny app)
3. Tabelle der Uebersetzung von LULC und Yield daten (x)
4. ...

## species-info.csv
- species included in study (all vertebrates with iucn raneg maps whose range map overlaps with brazil and has valid geometries)

| var                | description     | 
|--------------------|-----------------|
| ID                 | unique identifer of obeservation |
| taxonID            | unique identifer of the species  | 
| binomial           | scientific name of the species | 
| habitat            | name of iucn habitat classes | 
| suitability        | if habitat class is suitable or marginal  | 

## species-response-spill-over-parameter.csv
- Classification of species into response groups
- parameter values for responses and spill over effects

| var                | description     | 
|--------------------|-----------------|
| paraID             | unique identifer of the parameter pair |
| taxonID            | unique identifer of the species  | 
| response           | response group classification  | 
| responseParameter  | response parameter | 
| spillParameter     | spill-over parameter  | 

## lulc-iucn-translation.csv
- translation of iucn habitat categories into map biomas classification system 

| var                | description     | 
|--------------------|-----------------|
| lulcID             | unique identifer of the map biomas lulc class  |
| lulc               | name of the translated map biomas lulc class  |
| iucn               | name of the iucn habitat preference class |



## yield-translation.csv
- translation of yield classes into map biomas classification system 

| var                | description     | 
|--------------------|-----------------|
| lulcID             | unique identifer of the map biomas lulc class  |
| lulc               | name of the translated map biomas lulc class  |
| ontoName           | name of the yield class |
