## Transcriptomics

These are properties for Transcriptomics that are non-core, and thus not found in all sequencing experiments. 

Some will be unique to this type of experiment and some common to several types.

Table of Transcriptomics properties

| Field name | Specificity | Definition | Mandatory | Example | Type | Controlled Vocab Terms | Comment | INSDC | IHEC (International Human<br>Epigenome Consortium) | https://faircookbook.elixir-europe.org/content/recipes/interoperability/transcriptomics-metadata.html#:~:text=Analysis%2Dlevel%20metadata%20includes%20any,of%20data%2C%20e.g.%20enrichment%20analysis |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| nucl_acid_ext_kit |  | The name of the extraction kit used to recover the nucleic acid fraction of an input material is performed | TRUE | QIAamp DNA Blood Mini Kit | string |  | (please hack, put in as an idea) | nucl_acid_ext_kit |  |  |
| nucleic acid extraction method |  |  | TRUE |  |  |  | (please hack, put in as an idea) |  |  | nucleic acid extraction method |
| cDNA library amplication method |  | Technique used to amplify a cDNA library | TRUE |  |  |  | (please hack, put in as an idea) |  |  | cDNA library amplication method |
| extracted nucleic acid/material type |  | The type of material that was extracted from the sample | TRUE | polyA RNA |  |  | (please hack, put in as an idea) |  |  | extracted nucleic acid/material type |
| cell quality | single_cell_sequencing | Information about the quality of a single cell such as morphology or percent viability |  |  |  |  | (please hack, put in as an idea) |  |  | cell quality |
| cell barcode | single_cell_sequencing | Information about the cell identifier barcode used to tag individual cells in single cell sequencing |  |  |  |  | (please hack, put in as an idea) |  |  | cell barcode |
| UMI barcode | specific to UMI-Seq in libray prep | Information about the Unique Molecular Identifier barcodes used to tag DNA fragments<br><br> |  |  |  |  | (please hack, put in as an idea) |  |  | UMI barcode |
| spike-in kit used |  | Information about the spike-in kit used during sequencing library preparation |  |  |  |  | (please hack, put in as an idea) |  |  | spike-in kit used |
