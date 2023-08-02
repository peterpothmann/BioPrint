## species-info.csv
- All species included in study

| var                | description     |
|--------------------|-----------------|
| ID                 | unique identifer of observation |
| taxonID            | unique identifer of the species  |
| binomial           | scientific name of the species |
| habitat            | name of IUCN habitat type |
| suitability        | if habitat class is suitable or marginal  |
| class_id           | unique identifer of IUCN habitat type |

## species-response-spill-over-parameter.csv
- Classification of species into response groups
- Parameter values for responses and spill over effects

| var                | description     |
|--------------------|-----------------|
| paraID             | unique identifer of the parameter pair |
| taxonID            | unique identifer of the species  |
| response           | response group classification  |
| responseParameter  | response parameter |
| spillParameter     | spill-over parameter  |

## lulc-iucn-translation.csv
- Translation of iucn habitat categories into MAPBIOMAS classification system
- MAPBIOMAS project: https://mapbiomas.org/
- IUCN habitat classification: https://www.iucnredlist.org/resources/habitat-classification-scheme

| var                | description     |
|--------------------|-----------------|
| lulcID             | unique identifer of the MAPBIOMAS lulc class  |
| lulc               | name of the MAPBIOMAS lulc class  |
| iucn               | name of the associated IUCN habitat type |

## yield-translation.csv
- Translation of yield classes into MAPBIOMAS classification system

| var                | description     |
|--------------------|-----------------|
| lulcID             | unique identifer of the MAPBIOMAS lulc class  |
| lulc               | name of the MAPBIOMAS lulc class  |
| ontoName           | name of the associated yield class |

