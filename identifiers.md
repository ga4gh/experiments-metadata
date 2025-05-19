## Identifiers Checklist

This checklist contains identifiers that are relevant to include with a genomic dataset.


### Columns explanation
* **Field Name**: A suggestion on the way to name this property in one's model.
* **Definition**: What does this property represent?
* **Is a Discovery property**: Whether the property is considered a desirable criterion to discover datasets in a given database. For instance, would this property be good to be supported in a GA4GH Beacon search?
* **Mandatory**: Is the property considered essential to properly understand the nature of the dataset? Should it be provided for every release dataset?
* **Type of data expected**: What kind of value is expected? Examples include an ontology CURIE, a string, or an URL.
* **Examples**: A few values that could be provided for that property. Those do not represent a exhaustive list.

### Checklist

| Field name         | Definition                                                                                                                                                           | Is a Discovery property | Mandatory | Type of data expected                   | Examples          |
|--------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------|-----------|-----------------------------------------|-------------------|
| template_id        | Version of the checklist used, defining properties to capture and their validation rules.                                                                            | FALSE                   | FALSE     | String representing a unique identifier | GA4GH_EXPMETA_v1  |
| study_id           | Unique accession number for a study after registering a study with the an archival service.                                                                          | FALSE                   | TRUE      | String representing a unique identifier | STUDY_1           |
| sample_id          | Unique accession number to the biological sample extracted for the experiment. Called the BioSample accession at ENA, and is typically used in journal publications. | FALSE                   | TRUE      | String representing a unique identifier | BIOSAMPLE_1       |
| library_id         | Unique accession number of the nucleotide sequencing library.                                                                                                        | FALSE                   | TRUE      | String representing a unique identifier | LIBRARY_1         |
| library_extract_id | Unique accession number of a given extraction for a sequencing library. An extraction is a portion of a constructed library, used for a sequencing run.              | FALSE                   | FALSE     | String representing a unique identifier | LIBRARY_EXTRACT_1 |
| experiment_id      | Unique accession number of the experiment within a study.                                                                                                            | FALSE                   | TRUE      | String representing a unique identifier | EXPERIMENT_1      |
