# International Human Epigenome Consortium

[Data Model](https://github.com/IHEC/ihec-ecosystems/blob/master/docs/metadata/2.0/Ihec_metadata_specification.md)

Most IHEC members have deposited their datasets at the EGA. Therefore, some of the properties of the checklist are covered by the EGA data model.

## Core checklist:

| Experiments Metadata Checklist Property | Property in the project/platform data model         |
|-----------------------------------------|-----------------------------------------------------|
| experiment type                         | EXPERIMENT_TYPE                                     |
| assay type                              | LIBRARY_STRATEGY                                    |
| molecule type                           | MOLECULE_ONTOLOGY_CURIE                             |
| design description                      | EGA field: experiment.design_description            |
| sequencing protocol                     | Not available                                       |
| library description                     | EGA field: experiment.library_construction_protocol |
| library layout                          | EGA field: experiment.library_layout                |
| insert size                             | Not available                                       |
| instrument                              | EGA field: experiment.platform                      |
| instrument metadata                     | Not available                                       |

## Identifiers checklist:

| Experiments Metadata Checklist Property | Property in the project/platform data model |
|-----------------------------------------|---------------------------------------------|
| template id                             | Not available                               |
| study id                                | provisional_id                              |                               
| sample id                               | EGA field: sample.biosample_id              |                              
| library id                              | Not available                               |                             
| library extract id                      | Not available                               |               
| experiment id                           | EGA field: experiment.provisional_id        |              