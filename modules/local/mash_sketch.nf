// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process MASH_SKETCH {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:meta.id) }

    conda (params.enable_conda ? "bioconda::mash=2.3" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/mash:2.3--ha61e061_0"
    } else {
        container "quay.io/biocontainers/mash:2.3--ha61e061_0"
    }

    input:
    tuple val(meta), path(read)

    output:
    tuple val(meta), path("*.msh"), emit: mash
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    mash \\
        sketch \\
        $options.args \\
        -p $task.cpus \\
        -o ${prefix} \\
        -r $read

    mash --version > ${software}.version.txt
    """
}
