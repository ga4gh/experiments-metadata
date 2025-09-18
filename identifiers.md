## Identifiers Checklist

This checklist contains identifiers that are relevant to include with a genomic dataset.

This checklist contains identifiers that are relevant to include with a genomic dataset. These identifiers help ensure that data elements can be referenced consistently within a given context.
Important: The identifiers listed here are intended to be locally unique, meaning unique within a single database, project, or archive, and not globally unique across all systems. This approach supports internal consistency while allowing flexibility for integration with external identifier systems when needed.

### Columns explanation
* **Field Name**: A suggestion on the way to name this property in one's model.
* **Definition**: What does this property represent?
* **Mandatory**: Is the property considered essential to properly understand the nature of the dataset? Should it be provided for every release dataset?
* **Type of data expected**: What kind of value is expected? Examples include an ontology CURIE, a string, or an URL.
* **Examples**: A few values that could be provided for that property. Those do not represent a exhaustive list.

### Checklist

| Field Name         | Definition                                                                                                                                                     | Mandatory  | Type of data expected                   | Examples          |
|--------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|------------|-----------------------------------------|-------------------|
| template id        | Version of this GA4GH Experiments Metadata checklist that was used.                                                                                            | FALSE      | String representing a unique identifier | v1                |
| study id           | Unique identifier for a study after registering a study with the an archival service.                                                                          | TRUE       | String representing a unique identifier | STUDY_1           |
| sample id          | Unique identifier to the biological sample extracted for the experiment. Called the BioSample accession at ENA, and is typically used in journal publications. | TRUE       | String representing a unique identifier | BIOSAMPLE_1       |
| library id         | Unique identifier of the nucleotide sequencing library.                                                                                                        | TRUE       | String representing a unique identifier | LIBRARY_1         |
| library extract id | Unique identifier of a given extraction for a sequencing library. An extraction is a portion of a constructed library, used for a sequencing run.              | FALSE      | String representing a unique identifier | LIBRARY_EXTRACT_1 |
| experiment id      | Unique identifier of the experiment within a study.                                                                                                            | TRUE       | String representing a unique identifier | EXPERIMENT_1      |
