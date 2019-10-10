DOCUMENTS = ['main', 'response-to-editor']
TEXS = [doc+".tex" for doc in DOCUMENTS]
PDFS = [doc+".pdf" for doc in DOCUMENTS]
FIGURES = ['fig1.pdf']

include: '../../snakefiles/latex.smk'

rule all:
    input:
        PDFS

rule zipit:
    output:
        'upload.zip'
    input:
        TEXS, FIGURES, PDFS
    shell:
        'zip -T {output} {input}'

rule pdfclean:
    shell:
        "rm -f {PDFS}"
