task combine_rda {
     Array[File] individual_rdas
     String set_name

     command {
     	     Rscript /Rscripts/combine_rda_wrapper.R --rdaFiles ${sep=',' individual_rdas} --outFile ${set_name}
     }
     runtime {
             docker: "adunford/methy:9"
     }
     output  {
     	     File combined_rda = "${set_name}.combined.rda"
     }
}

task qc_report {
     File combined_rda
     String organism
     String outdir
     File genome
     command {
	     Rscript /Rscripts/generate_qc_report.R -f ${combined_rda}  -o ${outdir} #-g ${genome} -r ${organism}
     }
     runtime {
     	     docker: "adunford/methy:9"
     }
     output {
     	    File qc_report = "qcReport.html"
	    }

}

workflow methpipeagg {
	 String set_name
	 File genome
	 call combine_rda {input: set_name = set_name}
	 call qc_report {input: combined_rda = combine_rda.combined_rda, organism = set_name, genome = genome}
}