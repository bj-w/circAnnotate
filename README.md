# circAnnotate
A tool to annotate circRNA/backsplice junctions.
<br>

```
sh annotate.sh candidate_circRNA.bed gencode.v39.annotation.gtf
```
<br>

## Requirements

-   BEDTools (tested on v2.30.0)

-   GENCODE annotation file in GTF format (ungzipped)  
<br>

## Input
List of circRNAs in BED6 format 
<br>

| Chromosome | Junction start | Junction end | circRNA ID | score (ignored) | Strand |
|------------|----------------|--------------|------------|-----------------|--------|
<br>

*Example input*
```
1	100049908	100080659	1:100049908-100080659:+	.	+
```
<br>

## Output
"annotatedCircs.txt"
| Column | Description                             |
|--------|-----------------------------------------|
| 1      | Chromosome                              |
| 2      | Junction start                          |
| 3      | Junction end                            |
| 4      | circRNA ID (chr:start-end:strand)       |
| 5      | Strand                                  |
| 6      | Type (exon, intron, intergenic)         |
| 7      | Host gene ensembl ID (N/A if intergenic |
| 8      | Gene biotype                            |
<br>

*Example output*
```
chr1	100049908	100080659	1:100049908-100080659:+	+	exon	ENSG00000283761.1	 protein_coding
chr1	100049908	100080659	1:100049908-100080659:+	+	exon	ENSG00000156875.14	 protein_coding
```
