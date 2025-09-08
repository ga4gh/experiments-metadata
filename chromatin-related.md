## Chromatin-Related

| CORE LIST |  |
|---------|---|
| Field name | Definition |
| experiment_type | The broad type of sequencing experiment performed. A mixture of library strategy and source. |
| design_description | The high-level experiment design including layout, protocol. |
| library_layout | Whether the library was built as paired-end, or single-end. |
| molecule_type | Specifies the type of source material that is being sequenced. |
| assay_type | Sequencing technique intended for this library. |
| library_description | Description of the nucleotide sequencing library, including targeting information, spot, gap descriptors, and any other information relevant to its construction. |
| insert_size | The average insert size found during nucleic acid sequencing. |
| instrument | Technology platform used to perform nucleic acid sequencing, including name and/or number associated with a specific sequencing instrument model. It is recommended to be as specific as possible for this property (e.g. if the model/revision are available, providing that instead of just the instrument maker) |
| instrument_metadata | Captures metadata about sequencing instrument usage (e.g. instruments parameters and usage conditions) |
| sequencing_protocol | Set of rules which guides how the sequencing protocol was followed. Change-tracking services such as Protocol.io or GitHub are encouraged instead of dumping free text in this field. |
| IDENTIFIERS LIST |  |
| Field name | Definition |
| template_id | Version of the checklist used, defining properties to capture and their validation rules. |
| study_id | Unique accession number for a study after registering a study with the an archival service. |
| sample_id | Unique accession number to the biological sample extracted for the experiment. Called the BioSample accession at ENA, and is typically used in journal publications. |
| library_id | Unique accession number of the nucleotide sequencing library. |
| library_extract_id | Unique accession number of a given extraction for a sequencing library. An extraction is a portion of a constructed library, used for a sequencing run. |
| experiment_id | Unique accession number of the experiment within a study. |
