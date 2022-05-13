#! /bin/bash

highConfJunc=$1
gencode=$2

mkdir -p tmp

# get chromosome sizes
curl -s http://ftp.ensembl.org/pub/release-104/mysql/homo_sapiens_core_104_38/seq_region.txt.gz | \
gunzip -c | awk '($3=="4")' | grep -v CHR | cut -f 2,4 | sort -k1,1 -k2,2n > tmp/chromSizes.bed

# set up for GENCODE annotation
echo "Adding chr prefix"
awk 'BEGIN{OFS="\t"}$1="chr"$1' ${highConfJunc} > tmp/listOfBSJ.bed
sed -i 's/MT/M/g' tmp/chromSizes.bed
awk 'BEGIN{OFS="\t"}$1="chr"$1' tmp/chromSizes.bed > tmp/tmp.tmp && mv tmp/tmp.tmp tmp/chromSizes.bed

cd tmp

### Annotate BSJ coordinates ###
# get exon coordinates
echo "Getting exon coordinates"
cat ${gencode} | awk 'BEGIN{OFS="\t";} $3=="exon" {print $1,$4-1,$5,".",".",$7}' | \
bedtools sort | bedtools merge -i stdin -s -c 6 -o distinct | awk 'BEGIN{OFS="\t";} {print $1,$2,$3,".",".",$4}' > exons.bed 
# "gene" bed file
echo "Getting gene (exon + intron) coordinates"
cat ${gencode} | awk 'BEGIN{OFS="\t";} $3=="gene" {print $1,$4-1,$5,".",".",$7}' | \
bedtools sort > genes.bed
# get intron coordinates
echo "Getting intron coordinates"
cat genes.bed | bedtools subtract -a stdin -b exons.bed -s > introns.bed
# intergenic coordinates 
echo "Getting intergenic coordinates"
complementBed -i genes.bed -g chromSizes.bed > intergenic.bed

### Classifying BSJs ###
# Intergenic BSJs
echo "Annotating intergenic BSJs"
bedtools intersect -a listOfBSJ.bed -b genes.bed -v -s -f 1.00 | cut -f 1,2,3,4,6,7 > BSJ_intergenic.bed
awk 'BEGIN{OFS="\t";} {print $0, "intergenic", "NA", "NA"}' BSJ_intergenic.bed > tmp.tmp && mv tmp.tmp BSJ_intergenic.bed
# Intronic BSJs
echo "Annotating intronic BSJs"
bedtools intersect -a listOfBSJ.bed -b introns.bed -s -f 1.00 > BSJ_intron.bed
# Exonic BSJs
echo "Annotating exonic BSJs"
bedtools intersect -a listOfBSJ.bed -b genes.bed -s -f 1.00 > BSJ_exon.bed
awk 'NR==FNR{a[$0];next} !($0 in a)' BSJ_intron.bed BSJ_exon.bed > tmp.tmp && mv tmp.tmp BSJ_exon.bed
# add on BSJ descriptor columns (intergenic file already has it)
awk 'BEGIN{OFS="\t";} $(NF+1) = "intron"' BSJ_intron.bed > tmp.tmp && mv tmp.tmp BSJ_intron.bed
awk 'BEGIN{OFS="\t";} $(NF+1) = "exon"' BSJ_exon.bed > tmp.tmp && mv tmp.tmp BSJ_exon.bed
# merge exons and intron BSJ to identify gene of origin
echo "Adding gene of origin for exonic and intronic BSJs"
cat BSJ_exon.bed BSJ_intron.bed | sort -k1 > BSJ_annotated.bed
bedtools intersect -a BSJ_annotated.bed -b ${gencode} -wa -wb -s | \
cut -f 1,2,3,4,6,7,16 | cut -d ';' -f 1,3| awk '!seen[$0]++' | grep -vwE "gene_name" | awk 'gsub(";","\t")' > BSJ_annotated.txt
sed -i -e 's/\(gene_id \|"\)//g' BSJ_annotated.txt
sed -i -e 's/\(gene_type \|"\)//g' BSJ_annotated.txt
# merge into one file
echo "Merging into one main BSJ annotation file"
cd ..
cat tmp/BSJ_annotated.txt tmp/BSJ_intergenic.bed > annotatedCircs.txt
# clean up
rm -R tmp/