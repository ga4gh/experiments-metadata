# Exome Sequencing Typical Flow
The colouration legend illustrates the commonality metadata for other experimental assays.

```mermaid
flowchart TD
    classDef common_elements fill:#dcfce7,stroke:#16a34a,stroke-width:2px
    classDef relatively_common fill:#e0f2fe,stroke:#0284c7,stroke-width:2px
    classDef probably_unique fill:#e9f,stroke:#0284c7,stroke-width:2px

    subgraph sample_and_extraction
        A[Biological Sample] --> B[DNA Extraction]
    end

    B --> C[Library Preparation]

    subgraph library_preparation
        C --> C1["Fragment genomic DNA"]
        C1 --> C2["End repair & A-tailing"]
        C2 --> C3["Ligate sequencing adapters"]
        C3 --> C4["PCR amplification of library"]
    end

    C4 --> D

    subgraph exome_capture
        D["Hybridization with exome probes"]
        D --> D1["Biotinylated probes bind exons"]
        D1 --> D2["Magnetic beads capture probe-DNA complexes"]
        D2 --> D3["Wash away non-target DNA"]
        D3 --> D4["Enriched exome library"]
    end

    D4 --> E

    subgraph sequencing
        E["Sequence enriched DNA library"]
    end

    E --> F

    subgraph variant_identification
        F["Align reads to reference genome"]
        F --> F1["Call variants (SNVs & Indels)"]
        F1 --> F2["Annotate variants"]
        F2 --> F3["ClinVar"]
        F2 --> F4["gnomAD"]
        F2 --> F5["dbSNP"]
        F2 --> F6["Ensembl / VEP"]
    end

    %% Legend
    subgraph Legend ["Legend"]
        direction TD
        common
        relatively_common
        probably_unique
    end

    %% Assign classes
    class sequencing,common,sample_and_extraction common_elements;
    class library_preparation,relatively_common relatively_common;
    class exome_capture,variant_identification,probably_unique probably_unique;

    classDef default fill:#ffffff,stroke:#333,stroke-width:2px,color:#000000;

   ``` 


    
