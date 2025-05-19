# GA4GH Experiments Metadata Standard
Specifies the minimum information needed to characterise a genomic experiment

When a researcher downloads a genomic dataset, they typically get CRAM or VCF documents, which are the results of a sequencing experiment. However, these files contain little information on the nature of the experiment itself: are the data from whole genome sequencing, transcriptomics, or another kind of experiment? Are the data for a bulk sequencing or single cell assay? Have techniques been applied to target specific regions of the genome?

Without metadata explaining the context, researchers cannot make sense of results from experiments in genomics, epigenomics, and more. The GA4GH Discovery Work Stream is aiming to produce a minimal checklist of metadata needed to characterise -omics datasets. The Experiments Metadata Standard will provide a dictionary of properties that makes it easier to search for experiments and to understand their results for analysis.

For more information on the checklist scope, see: [Checklist v1 Scope Statement](https://www.ga4gh.org/document/experiments-metadata-standards-scope-statement/)

Two documents are being presented for this first version of the checklist:
* [Core](./core.md): This checklist contains properties that are relevant to any sequencing assay.
* [Identifiers](./identifiers.md): This checklist contains identifiers that are relevant to include with a genomic dataset.