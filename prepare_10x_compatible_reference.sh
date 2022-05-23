#! /usr/bin/env bash

## This script is to prepare the same reference dataset
## used in 10x cellranger

## Please visit 10x document website for details:
## https://support.10xgenomics.com/single-cell-gene-expression/software/release-notes/build#header

## Code for data preparing were directly modified from 10x's document sites

mk_human_ref(){
    local starscope_opts=$@
    # Genome metadata
    genome="GRCh38"
    version="2020-A"


    # Set up source and build directories
    outdir=$genome"-"$version
    mkdir -p "$outdir"


    # Download source files if they do not exist in reference_sources/ folder
    source="reference_sources"
    mkdir -p "$source"


    ##fasta_url="http://ftp.ensembl.org/pub/release-98/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz"
    ##fasta_in="${source}/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz"
    ##gtf_url="http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_32/gencode.v32.primary_assembly.annotation.gtf.gz"
    ##gtf_in="${source}/gencode.v32.primary_assembly.annotation.gtf.gz"
    fasta_url="rsync://ftp.ensembl.org/ensembl/pub/release-98/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz"
    fasta_in="${source}/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz"
    gtf_url="rsync://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_32/gencode.v32.primary_assembly.annotation.gtf.gz"
    gtf_in="${source}/gencode.v32.primary_assembly.annotation.gtf.gz"

    echo "Downloading reference fasta..."
    ##curl -sS "$fasta_url" | zcat > "$fasta_in"
    rsync -avP --append-verify $fasta_url $fasta_in

    echo "Downloading reference gtf..."
    ##curl -sS "$gtf_url" | zcat > "$gtf_in"
    rsync -avP $gtf_url $gtf_in


    # Modify sequence headers in the Ensembl FASTA to match the file
    # "GRCh38.primary_assembly.genome.fa" from GENCODE. Unplaced and unlocalized
    # sequences such as "KI270728.1" have the same names in both versions.
    #
    # Input FASTA:
    #   >1 dna:chromosome chromosome:GRCh38:1:1:248956422:1 REF
    #
    # Output FASTA:
    #   >chr1 1
    fasta_modified=$fasta_in".modified"
    # sed commands:
    # 1. Replace metadata after space with original contig name, as in GENCODE
    # 2. Add "chr" to names of autosomes and sex chromosomes
    # 3. Handle the mitochrondrial chromosome
    gunzip -c "$fasta_in" \
        | sed -E 's/^>(\S+).*/>\1 \1/' \
        | sed -E 's/^>([0-9]+|[XY]) />chr\1 /' \
        | sed -E 's/^>MT />chrM /' \
              > "$fasta_modified"

    # Remove version suffix from transcript, gene, and exon IDs in order to match
    # previous Cell Ranger reference packages
    #
    # Input GTF:
    #     ... gene_id "ENSG00000223972.5"; ...
    # Output GTF:
    #     ... gene_id "ENSG00000223972"; gene_version "5"; ...
    gtf_modified=$gtf_in".modified"
    # Pattern matches Ensembl gene, transcript, and exon IDs for human or mouse:
    ID="(ENS(MUS)?[GTE][0-9]+)\.([0-9]+)"
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
    GENE_PATTERN="gene_type \"${BIOTYPE_PATTERN}\""
    TX_PATTERN="transcript_type \"${BIOTYPE_PATTERN}\""
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
              > "${source}/gene_allowlist"


    # Filter the GTF file based on the gene allowlist
    gtf_filtered=$gtf_in".filtered"
    # Copy header lines beginning with "#"
    grep -E "^#" "$gtf_modified" > "$gtf_filtered"
    # Filter to the gene allowlist
    grep -Ff "${source}/gene_allowlist" "$gtf_modified" \
         >> "$gtf_filtered"

    ## copy prepared genome fasta to $outdir
    cp $fasta_modified $outdir/genome.fa
    ## copy prepared gtf to $outdir
    cp $gtf_filtered $outdir/genes.gtf
    # Create reference package
    echo "Running starscope command:"
    cat <<-EOF
	starscope mkref \\
	          --genomeFasta $outdir/genome.fa \\
	          --genomeGTF $outdir/genes.gtf \\
	          --outdir $outdir \\
	          ${starscope_opts[@]}
	EOF
    starscope mkref \
              --genomeFasta $outdir/genome.fa \
              --genomeGTF $outdir/genes.gtf \
              --outdir $outdir \
              ${starscope_opts[@]}
}

mk_mouse_ref(){
    local starscope_opts=$@
    # Genome metadata
    genome="mm10"
    version="2020-A"

    # Set up source and build directories
    outdir="${genome}-${version}"
    mkdir -p "$outdir"

    # Download source files if they do not exist in reference_sources/ folder
    source="reference_sources"
    mkdir -p "$source"

    ##fasta_url="http://ftp.ensembl.org/pub/release-98/fasta/mus_musculus/dna/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz"
    ##fasta_in="${source}/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz"
    ##gtf_url="http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M23/gencode.vM23.primary_assembly.annotation.gtf.gz"
    ##gtf_in="${source}/gencode.vM23.primary_assembly.annotation.gtf.gz"
    fasta_url="rsync://ftp.ensembl.org/ensembl/pub/release-98/fasta/mus_musculus/dna/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz"
    fasta_in="${source}/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz"
    gtf_url="rsync://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M23/gencode.vM23.primary_assembly.annotation.gtf.gz"
    gtf_in="${source}/gencode.vM23.primary_assembly.annotation.gtf.gz"

    if [ ! -f "$fasta_in" ]
    then
        echo "Downloading reference fasta..."
        ##curl -sS "$fasta_url" | zcat > "$fasta_in"
        rsync -avP $fasta_url $fasta_in
    fi
    if [ ! -f "$gtf_in" ]
    then
        echo "Downloading reference gtf..."
        ##curl -sS "$gtf_url" | zcat > "$gtf_in"
        rsync -avP $gtf_url $gtf_in
    fi

    # Modify sequence headers in the Ensembl FASTA to match the file
    # "GRCm38.primary_assembly.genome.fa" from GENCODE. Unplaced and unlocalized
    # sequences such as "GL456210.1" have the same names in both versions.
    #
    # Input FASTA:
    #   >1 dna:chromosome chromosome:GRCm38:1:1:195471971:1 REF
    #
    # Output FASTA:
    #   >chr1 1
    fasta_modified=$fasta_in".modified"
    # sed commands:
    # 1. Replace metadata after space with original contig name, as in GENCODE
    # 2. Add "chr" to names of autosomes and sex chromosomes
    # 3. Handle the mitochrondrial chromosome
    gunzip -c "$fasta_in" \
        | sed -E 's/^>(\S+).*/>\1 \1/' \
        | sed -E 's/^>([0-9]+|[XY]) />chr\1 /' \
        | sed -E 's/^>MT />chrM /' > "$fasta_modified"

    # Remove version suffix from transcript, gene, and exon IDs in order to match
    # previous Cell Ranger reference packages
    #
    # Input GTF:
    #     ... gene_id "ENSMUSG00000102693.1"; ...
    # Output GTF:
    #     ... gene_id "ENSMUSG00000102693"; gene_version "1"; ...
    gtf_modified=$gtf_in".modified"
    # Pattern matches Ensembl gene, transcript, and exon IDs for human or mouse:
    ID="(ENS(MUS)?[GTE][0-9]+)\.([0-9]+)"
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
    BIOTYPE_PATTERN="(protein_coding|lncRNA|\
IG_C_gene|IG_D_gene|IG_J_gene|IG_LV_gene|IG_V_gene|\
IG_V_pseudogene|IG_J_pseudogene|IG_C_pseudogene|\
TR_C_gene|TR_D_gene|TR_J_gene|TR_V_gene|\
TR_V_pseudogene|TR_J_pseudogene)"
    ##BIOTYPE_PATTERN=\
    ##"(protein_coding|lncRNA|\
    ##IG_C_gene|IG_D_gene|IG_J_gene|IG_LV_gene|IG_V_gene|\
    ##IG_V_pseudogene|IG_J_pseudogene|IG_C_pseudogene|\
    ##TR_C_gene|TR_D_gene|TR_J_gene|TR_V_gene|\
    ##TR_V_pseudogene|TR_J_pseudogene)"
    GENE_PATTERN="gene_type \"${BIOTYPE_PATTERN}\""
    TX_PATTERN="transcript_type \"${BIOTYPE_PATTERN}\""
    READTHROUGH_PATTERN="tag \"readthrough_transcript\""

    # Construct the gene ID allowlist. We filter the list of all transcripts
    # based on these criteria:
    #   - allowable gene_type (biotype)
    #   - allowable transcript_type (biotype)
    #   - no "readthrough_transcript" tag
    # We then collect the list of gene IDs that have at least one associated
    # transcript passing the filters.
    cat "$gtf_modified" \
        | awk '$3 == "transcript"' \
        | grep -E "$GENE_PATTERN" \
        | grep -E "$TX_PATTERN" \
        | grep -Ev "$READTHROUGH_PATTERN" \
        | sed -E 's/.*(gene_id "[^"]+").*/\1/' \
        | sort \
        | uniq \
              > "${source}/gene_allowlist"

    # Filter the GTF file based on the gene allowlist
    gtf_filtered=$gtf_in".filtered"
    # Copy header lines beginning with "#"
    grep -E "^#" "$gtf_modified" > "$gtf_filtered"
    # Filter to the gene allowlist
    grep -Ff "${source}/gene_allowlist" "$gtf_modified" \
         >> "$gtf_filtered"

    ## copy prepared genome fasta to $outdir
    cp $fasta_modified $outdir/genome.fa
    ## copy prepared gtf to $outdir
    cp $gtf_filtered $outdir/genes.gtf
    # Create reference package
    echo "Running starscope command:"
    cat <<-EOF
	starscope mkref \\
	          --genomeFasta $outdir/genome.fa \\
	          --genomeGTF $outdir/genes.gtf \\
	          --outdir $outdir \\
	          ${starscope_opts[@]}
	EOF
    starscope mkref \
              --genomeFasta $outdir/genome.fa \
              --genomeGTF $outdir/genes.gtf \
              --outdir $outdir \
              ${starscope_opts[@]}
}

mk_human_mouse_ref(){
    local starscope_opts=$@
    human_genome="GRCh38"
    mouse_genome="mm10"
    version="2020-A"


    outdir="${human_genome}_${mouse_genome}-${version}"
    mkdir -p "$outdir"


    # Download source files if they do not exist in reference_sources/ folder
    source="reference_sources"
    mkdir -p "$source"


    ##human_fasta_url="http://ftp.ensembl.org/pub/release-98/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz"
    ##human_fasta_in="${source}/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz"
    ##human_gtf_url="http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_32/gencode.v32.primary_assembly.annotation.gtf.gz"
    ##human_gtf_in="${source}/gencode.v32.primary_assembly.annotation.gtf.gz"
    ##mouse_fasta_url="http://ftp.ensembl.org/pub/release-98/fasta/mus_musculus/dna/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz"
    ##mouse_fasta_in="${source}/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz"
    ##mouse_gtf_url="http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M23/gencode.vM23.primary_assembly.annotation.gtf.gz"
    ##mouse_gtf_in="${source}/gencode.vM23.primary_assembly.annotation.gtf.gz"
    human_fasta_url="rsync://ftp.ensembl.org/ensembl/pub/release-98/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz"
    human_fasta_in="${source}/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz"
    human_gtf_url="rsync://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_32/gencode.v32.primary_assembly.annotation.gtf.gz"
    human_gtf_in="${source}/gencode.v32.primary_assembly.annotation.gtf.gz"
    mouse_fasta_url="rsync://ftp.ensembl.org/ensembl/pub/release-98/fasta/mus_musculus/dna/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz"
    mouse_fasta_in="${source}/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz"
    mouse_gtf_url="rsync://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M23/gencode.vM23.primary_assembly.annotation.gtf.gz"
    mouse_gtf_in="${source}/gencode.vM23.primary_assembly.annotation.gtf.gz"

    if [ ! -f "$human_fasta_in" ]
    then
        echo "Downloading human reference fasta..."
        ##curl -sS "$human_fasta_url" | zcat > "$human_fasta_in"
        rsync -avP $human_fasta_url $human_fasta_in
    fi
    if [ ! -f "$human_gtf_in" ]
    then
        echo "Downloading human reference gtf..."
        ##curl -sS "$human_gtf_url" | zcat > "$human_gtf_in"
        rsync -avP $human_gtf_url $human_gtf_in
    fi
    if [ ! -f "$mouse_fasta_in" ]
    then
        echo "Downloading mouse reference fasta..."
        ##curl -sS "$mouse_fasta_url" | zcat > "$mouse_fasta_in"
        rsync -avP $mouse_fasta_url $mouse_fasta_in
    fi
    if [ ! -f "$mouse_gtf_in" ]
    then
        echo "Downloading mouse reference gtf..."
        ##curl -sS "$mouse_gtf_url" | zcat > "$mouse_gtf_in"
        rsync -avP $mouse_gtf_url $mouse_gtf_in
    fi

    # String patterns used for both genomes
    ID="(ENS(MUS)?[GTE][0-9]+)\.([0-9]+)"

    BIOTYPE_PATTERN="(protein_coding|lncRNA|\
IG_C_gene|IG_D_gene|IG_J_gene|IG_LV_gene|IG_V_gene|\
IG_V_pseudogene|IG_J_pseudogene|IG_C_pseudogene|\
TR_C_gene|TR_D_gene|TR_J_gene|TR_V_gene|\
TR_V_pseudogene|TR_J_pseudogene)"
    GENE_PATTERN="gene_type \"${BIOTYPE_PATTERN}\""
    TX_PATTERN="transcript_type \"${BIOTYPE_PATTERN}\""
    READTHROUGH_PATTERN="tag \"readthrough_transcript\""
    PAR_PATTERN="tag \"PAR\""

    #################### HUMAN ####################
    # Please see the GRCh38-2020-A build documentation for details on these steps.

    # Process FASTA -- translate chromosome names
    human_fasta_modified=$human_fasta_in".modified"
    gunzip -c "$human_fasta_in" \
        | sed -E 's/^>(\S+).*/>\1 \1/' \
        | sed -E 's/^>([0-9]+|[XY]) />chr\1 /' \
        | sed -E 's/^>MT />chrM /' \
              > "$human_fasta_modified"

    # Process GTF -- split Ensembl IDs from version suffixes
    human_gtf_modified=$human_gtf_in".modified"
    gunzip -c "$human_gtf_in" \
        | sed -E 's/gene_id "'"$ID"'";/gene_id "\1"; gene_version "\3";/' \
        | sed -E 's/transcript_id "'"$ID"'";/transcript_id "\1"; transcript_version "\3";/' \
        | sed -E 's/exon_id "'"$ID"'";/exon_id "\1"; exon_version "\3";/' \
              > "$human_gtf_modified"

    # Process GTF -- filter based on gene/transcript tags
    cat "$human_gtf_modified" \
        | awk '$3 == "transcript"' \
        | grep -E "$GENE_PATTERN" \
        | grep -E "$TX_PATTERN" \
        | grep -Ev "$READTHROUGH_PATTERN" \
        | grep -Ev "$PAR_PATTERN" \
        | sed -E 's/.*(gene_id "[^"]+").*/\1/' \
        | sort \
        | uniq \
              > "${source}/gene_allowlist"

    human_gtf_filtered=$human_gtf_in".filtered"
    grep -E "^#" "$human_gtf_modified" > "$human_gtf_filtered"
    grep -Ff "${source}/gene_allowlist" "$human_gtf_modified" \
         >> "$human_gtf_filtered"

    #################### MOUSE ####################
    # Please see the mm10-2020-A build documentation for details on these steps.

    # Process FASTA -- translate chromosome names
    mouse_fasta_modified=$mouse_fasta_in".modified"
    gunzip -c "$mouse_fasta_in" \
        | sed -E 's/^>(\S+).*/>\1 \1/' \
        | sed -E 's/^>([0-9]+|[XY]) />chr\1 /' \
        | sed -E 's/^>MT />chrM /' \
              > "$mouse_fasta_modified"

    # Process GTF -- split Ensembl IDs from version suffixes
    mouse_gtf_modified=$mouse_gtf_in".modified"
    gunzip -c "$mouse_gtf_in" \
        | sed -E 's/gene_id "'"$ID"'";/gene_id "\1"; gene_version "\3";/' \
        | sed -E 's/transcript_id "'"$ID"'";/transcript_id "\1"; transcript_version "\3";/' \
        | sed -E 's/exon_id "'"$ID"'";/exon_id "\1"; exon_version "\3";/' \
              > "$mouse_gtf_modified"

    # Process GTF -- filter based on gene/transcript tags
    cat "$mouse_gtf_modified" \
        | awk '$3 == "transcript"' \
        | grep -E "$GENE_PATTERN" \
        | grep -E "$TX_PATTERN" \
        | grep -Ev "$READTHROUGH_PATTERN" \
        | sed -E 's/.*(gene_id "[^"]+").*/\1/' \
        | sort \
        | uniq \
              > "${source}/gene_allowlist"

    mouse_gtf_filtered=$mouse_gtf_in".filtered"
    grep -E "^#" "$mouse_gtf_modified" > "$mouse_gtf_filtered"
    grep -Ff "${source}/gene_allowlist" "$mouse_gtf_modified" \
         >> "$mouse_gtf_filtered"

    #################### MKREF ####################
    ## copy prepared genome fasta to $outdir
    cat $human_fasta_modified $mouse_fasta_modified > $outdir/genome.fa
    ## copy prepared gtf to $outdir
    cat $human_gtf_filtered $mouse_gtf_filtered > $outdir/genes.gtf
    # Create reference package
    echo "Running starscope command:"
    cat <<-EOF
	starscope mkref \\
	          --genomeFasta $outdir/genome.fa \\
	          --genomeGTF $outdir/genes.gtf \\
	          --outdir $outdir \\
	          ${starscope_opts[@]}
	EOF
    starscope mkref \
              --genomeFasta $outdir/genome.fa \
              --genomeGTF $outdir/genes.gtf \
              --outdir $outdir \
              ${starscope_opts[@]}
}

usage(){
    cat <<-EOF
	prepare_10x_compatible_reference.sh will help you to generate
	10x cellranger compatible STAR reference set. The detail preparing
	procedures could be referred from 10x's documentation website:
	https://support.10xgenomics.com/single-cell-gene-expression/software/release-notes/build#header
	
	Usage:
	prepare_10x_compatible_reference.sh <human|mouse|hm|all> [starscope_options]
	
	prepare_10x_compatible_reference.sh human    generate human GRh38 reference
	prepare_10x_compatible_reference.sh mouse    generate mouse mm10 reference
	prepare_10x_compatible_reference.sh hm       combine GRh38 and mm10 to
	                                             generate reference for hybrid
	                                             sample analysis
	prepare_10x_compatible_reference.sh all      generate all three reference
	                                             datasets mentioned above

	starscope_options:
	--executor        Define executor of nextflow (local), see:
	                  https://www.nextflow.io/docs/latest/executor.html
	--cpus            CPUs to use for all processes (8)
	--mem             Memory to use for all processes, please note
	                  the special format (16.GB)
	--noDepCheck      Do not check Java and nextflow before
	                  running (false)
	-bg               Running the pipeline in background (false)

	example:
	prepare_10x_compatible_reference.sh human --cpus 8 --mem 32.GB -bg
	EOF

    exit 0;
}

case $1 in
    "" | "-h" | "-help" | "--help")
        usage
        ;;
    "human")
        shift 1
        mk_human_ref $@
        echo "After running, user could remove intermediate directory $source"
        ;;
    "mouse")
        shift 1
        mk_mouse_ref $@
        echo "After running, user could remove intermediate directory $source"
        ;;
    "hm")
        shift 1
        mk_human_mouse_ref $@
        echo "After running, user could remove intermediate directory $source"
        ;;
    "all")
        shift 1
        mk_human_ref $@
        mk_mouse_ref $@
        mk_human_mouse_ref $@
        echo "After running, user could remove intermediate directory $source"
        ;;
    *)
        usage
        ;;
esac
