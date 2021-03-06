workflow call_bismark_pool {
  call step1_bismark_rrbs { }
}

task merge_replicates {
  String samplename
  Array[File] bams
  File genome_index
  File monitoring_script
  
  String multicore
  String memory
  String disks
  Int cpu
  Int preemptible
  
  command {
    chmod u+x ${monitoring_script}
    ${monitoring_script} > monitoring.log &
      mkdir bismark_index
    tar zxf ${genome_index} -C bismark_index
    
    bismark --genome bismark_index --multicore ${multicore} -1 ${r1_fastq} -2 ${r2_fastq}
    # The file renaming below is necessary since this version of bismark doesn't allow the 
    # use of --multicore with --basename
    mv *bismark_bt2_pe.bam ${libraryname}.bam
    mv *bismark_bt2_PE_report.txt ${libraryname}_report.txt
    
    samtools merge {samplename}.merged.bam ${sep=' ',${libraryname}.bam}
    
    bismark_methylation_extractor --multicore ${multicore} --gzip --bedGraph --buffer_size 50% --genome_folder bismark_index ${samplename}.merged.bam
    bismark2report --alignment_report ${samplename}_report.txt --output ${samplename}_bismark_report.html   
  }
  
  output {
    File output_covgz = "${samplename}.bismark.cov.gz"
    File output_report = "${samplename}_report.txt"
    File mbias_report = "${samplename}.M-bias.txt"
    File bismark_report_html = "${samplename}_bismark_report.html"
  }
  
  runtime {
    continueOnReturnCode: false
    docker: "sowmyaiyer/bismark_image:latest"
    memory: memory
    disks: disks
    cpu: cpu
    preemptible: preemptible
  }
}