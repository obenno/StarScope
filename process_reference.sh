#! /usr/bin/env bash

## This script is to prepare the same reference dataset
## used in 10x cellranger

## Please visit 10x document website for details:
## https://support.10xgenomics.com/single-cell-gene-expression/software/release-notes/build#header

## Code for data preparing were directly modified from 10x's document site



process_fasta(){

    local fasta_in=$1 # only support gzipped

    # Modify sequence headers in the Ensembl FASTA to match the file
    # "GRCh38.primary_assembly.genome.fa" from GENCODE. Unplaced and unlocalized
    # sequences such as "KI270728.1" have the same names in both versions.
    #
    # Input FASTA:
    #   >1 dna:chromosome chromosome:GRCh38:1:1:248956422:1 REF
    #
    # Output FASTA:
    #   >chr1 1
    # sed commands:
    # 1. Replace metadata after space with original contig name, as in GENCODE
    # 2. Add "chr" to names of autosomes and sex chromosomes
    # 3. Handle the mitochrondrial chromosome
    gunzip -c "$fasta_in" \
        | sed -E 's/^>(\S+).*/>\1 \1/' \
        | sed -E 's/^>([0-9]+|[XY]) />chr\1 /' \
        | sed -E 's/^>MT />chrM /' \
              > genome.fa

}

process_gtf(){

    local gtf_in=$1 # only support gzipped

    # Remove version suffix from transcript, gene, and exon IDs in order to match
    # previous Cell Ranger reference packages
    #
    # Input GTF:
    #     ... gene_id "ENSG00000223972.5"; ...
    # Output GTF:
    #     ... gene_id "ENSG00000223972"; gene_version "5"; ...
    gtf_modified=$(mktemp -p ./ tmp.XXXXXX.gtf)
    # Pattern matches Ensembl gene, transcript, and exon IDs for human or mouse:
    ID="(ENS([A-Z]{3})?[GTE][0-9]+)\.([0-9]+)"
    gunzip -c "$gtf_in" \
        | sed -E 's/gene_id "'"$ID"'";/gene_id "\1"; gene_version "\3";/' \
        | sed -E 's/transcript_id "'"$ID"'";/transcript_id "\1"; transcript_version "\3";/' \
        | sed -E 's/exon_id "'"$ID"'";/exon_id "\1"; exon_version "\3";/' \
              > "$gtf_modified"


    # Define string patterns for GTF tags
    # NOTES:
    # - Since GENCODE release 31/M22 (Ensembl 97), the "lincRNA" and "antisense"
    #   biotypes are part of a more generic "lncRNA" biotype.
    # - These filters are relevant only to GTF files from GENCODE. The GTFs from
    #   Ensembl release 98 have the following differences:
    #   - The names "gene_biotype" and "transcript_biotype" are used instead of
    #     "gene_type" and "transcript_type".
    #   - Readthrough transcripts are present but are not marked with the
    #     "readthrough_transcript" tag.
    #   - Only the X chromosome versions of genes in the pseudoautosomal regions
    #     are present, so there is no "PAR" tag.
    BIOTYPE_PATTERN="(protein_coding|lncRNA|\
IG_C_gene|IG_D_gene|IG_J_gene|IG_LV_gene|IG_V_gene|\
IG_V_pseudogene|IG_J_pseudogene|IG_C_pseudogene|\
TR_C_gene|TR_D_gene|TR_J_gene|TR_V_gene|\
TR_V_pseudogene|TR_J_pseudogene)"
    GENE_PATTERN="gene_biotype \"${BIOTYPE_PATTERN}\""
    TX_PATTERN="transcript_biotype \"${BIOTYPE_PATTERN}\""
    READTHROUGH_PATTERN="tag \"readthrough_transcript\""
    PAR_PATTERN="tag \"PAR\""

    # Construct the gene ID allowlist. We filter the list of all transcripts
    # based on these criteria:
    #   - allowable gene_type (biotype)
    #   - allowable transcript_type (biotype)
    #   - no "PAR" tag (only present for Y chromosome PAR)
    #   - no "readthrough_transcript" tag
    # We then collect the list of gene IDs that have at least one associated
    # transcript passing the filters.
    cat "$gtf_modified" \
        | awk '$3 == "transcript"' \
        | grep -E "$GENE_PATTERN" \
        | grep -E "$TX_PATTERN" \
        | grep -Ev "$READTHROUGH_PATTERN" \
        | grep -Ev "$PAR_PATTERN" \
        | sed -E 's/.*(gene_id "[^"]+").*/\1/' \
        | sort \
        | uniq \
              > gene_allowlist


    # Filter the GTF file based on the gene allowlist
    # Copy header lines beginning with "#"
    grep -E "^#" "$gtf_modified" > genes.gtf
    # Filter to the gene allowlist
    grep -Ff gene_allowlist "$gtf_modified" \
         >> genes.gtf
    rm $gtf_modified gene_allowlist
}

usage(){
    cat <<-EOF
	This script will help you to generate 10X style genome fasta and gtf files,
	output files are "genome.fa" and "genes.gtf".

	The detail preparing procedures could be referred from 10x's documentation website:
	https://support.10xgenomics.com/single-cell-gene-expression/software/release-notes/build#header

	usage:
	$(basename $0) --fasta inputGenome.fa.gz --gtf inputGTF.gtf.gz
	EOF

    exit 0;
}


if [[ -z $1 ]] || [[ $1 -eq "-h" ]] || [[ $1 -eq "-help" ]] || [[ $1 -eq "--help" ]]
then
    usage
fi

while [[ ! -z $1 ]]
do
    case $1 in
        "--fasta")
            inputFasta=$2
            shift 2
            ;;
        "--gtf")
            inputGTF=$2
            shift 2
            ;;
        *)
            echo "argument is not supported: $1"
            usage
            ;;
    esac
done

process_fasta $inputFasta
process_gtf $inputGTF
