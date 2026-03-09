"""
dna_encoding.py — Molecular Biology as Source Code

Demonstrates §7 of PAPER.md: "Molecular Biology as Source Code"

DNA is a base-4 digital storage system with:
  - 4 bases (A, T, G, C) — like 2-bit symbols
  - 3 bases per codon — 4³ = 64 possible codons
  - 64 codons → 20 amino acids + 3 stop signals
  - Redundant encoding (error correction)
  - Telomeres (write-protect headers)
  - Introns (non-coding, like comments)
  - CRISPR (runtime patch system)

This is not a metaphor. DNA is literally a program.

Author: BlackRoad OS, Inc.
"""

import math


# Full codon table (standard genetic code)
CODON_TABLE = {
    # Phenylalanine
    'TTT': 'Phe', 'TTC': 'Phe',
    # Leucine
    'TTA': 'Leu', 'TTG': 'Leu', 'CTT': 'Leu', 'CTC': 'Leu', 'CTA': 'Leu', 'CTG': 'Leu',
    # Isoleucine
    'ATT': 'Ile', 'ATC': 'Ile', 'ATA': 'Ile',
    # Methionine (START)
    'ATG': 'Met',
    # Valine
    'GTT': 'Val', 'GTC': 'Val', 'GTA': 'Val', 'GTG': 'Val',
    # Serine
    'TCT': 'Ser', 'TCC': 'Ser', 'TCA': 'Ser', 'TCG': 'Ser', 'AGT': 'Ser', 'AGC': 'Ser',
    # Proline
    'CCT': 'Pro', 'CCC': 'Pro', 'CCA': 'Pro', 'CCG': 'Pro',
    # Threonine
    'ACT': 'Thr', 'ACC': 'Thr', 'ACA': 'Thr', 'ACG': 'Thr',
    # Alanine
    'GCT': 'Ala', 'GCC': 'Ala', 'GCA': 'Ala', 'GCG': 'Ala',
    # Tyrosine
    'TAT': 'Tyr', 'TAC': 'Tyr',
    # Stop codons
    'TAA': 'STOP', 'TAG': 'STOP', 'TGA': 'STOP',
    # Histidine
    'CAT': 'His', 'CAC': 'His',
    # Glutamine
    'CAA': 'Gln', 'CAG': 'Gln',
    # Asparagine
    'AAT': 'Asn', 'AAC': 'Asn',
    # Lysine
    'AAA': 'Lys', 'AAG': 'Lys',
    # Aspartate
    'GAT': 'Asp', 'GAC': 'Asp',
    # Glutamate
    'GAA': 'Glu', 'GAG': 'Glu',
    # Cysteine
    'TGT': 'Cys', 'TGC': 'Cys',
    # Tryptophan
    'TGG': 'Trp',
    # Arginine
    'CGT': 'Arg', 'CGC': 'Arg', 'CGA': 'Arg', 'CGG': 'Arg', 'AGA': 'Arg', 'AGG': 'Arg',
    # Glycine
    'GGT': 'Gly', 'GGC': 'Gly', 'GGA': 'Gly', 'GGG': 'Gly',
}


def translate(dna: str) -> list[str]:
    """Translate a DNA sequence into amino acids."""
    dna = dna.upper().replace(' ', '')
    proteins = []
    for i in range(0, len(dna) - 2, 3):
        codon = dna[i:i+3]
        amino = CODON_TABLE.get(codon, '???')
        proteins.append((codon, amino))
    return proteins


def show_redundancy():
    """Demonstrate the error-correcting redundancy of the genetic code."""
    print("=" * 60)
    print("DNA AS ERROR-CORRECTING CODE")
    print("=" * 60)

    # Count codons per amino acid
    amino_to_codons: dict[str, list] = {}
    for codon, amino in CODON_TABLE.items():
        amino_to_codons.setdefault(amino, []).append(codon)

    print(f"\n  Total codons:      {len(CODON_TABLE):>4}  (4³ = 64)")
    unique_aminos = len(set(v for v in CODON_TABLE.values() if v != 'STOP'))
    print(f"  Amino acids:       {unique_aminos:>4}")
    print(f"  Stop codons:       {len(amino_to_codons.get('STOP', [])):>4}")
    print(f"  Redundancy ratio:  {64 / (unique_aminos + 1):>4.1f}×\n")

    print(f"  {'Amino Acid':>12}  {'Codons':>6}  {'Example codons'}")
    print("  " + "-" * 50)
    # Sort by number of codons (most redundant first)
    for amino, codons in sorted(amino_to_codons.items(), key=lambda x: -len(x[1]))[:10]:
        print(f"  {amino:>12}  {len(codons):>6}  {', '.join(codons[:4])}")

    print("""
  The most important amino acids have the MOST backup codons.
  Leucine has 6 codons. Change the 3rd base of most Leu codons → still Leu.
  This is called "wobble base pairing" — the 3rd position tolerates mutations.

  This is identical to Reed-Solomon error correction in CDs and QR codes:
    • Add redundancy so single-bit errors don't change the message
    • The message (protein) survives despite copying errors (mutations)

  DNA is not "like" an error-correcting code. It IS one.
""")


def show_start_stop():
    """Show the program structure of DNA."""
    print("=" * 60)
    print("DNA PROGRAM STRUCTURE")
    print("=" * 60)
    print("""
  A gene is a program with:

    [Promoter region]     ← #!interpreter line / function declaration
    ATG                   ← main() / START codon
    [coding sequence]     ← function body
    TAA / TAG / TGA       ← return; / STOP codon
    [3' UTR]              ← post-function cleanup

  Example gene fragment:
""")

    demo_seq = 'ATG GCT AAA GAA TGG CTG TAA'
    proteins = translate(demo_seq)
    print(f"  Sequence: {demo_seq}")
    print(f"  Translation:")
    for codon, amino in proteins:
        marker = ' ← START' if codon == 'ATG' else ' ← STOP' if amino == 'STOP' else ''
        print(f"    {codon}  →  {amino}{marker}")


def storage_density():
    """Calculate DNA's information storage density."""
    print("\n" + "=" * 60)
    print("DNA STORAGE DENSITY")
    print("=" * 60)

    # Each base pair = 2 bits
    bits_per_bp = 2
    # Human genome: ~3 billion base pairs
    human_genome_bp = 3e9
    human_genome_bits = human_genome_bp * bits_per_bp
    human_genome_bytes = human_genome_bits / 8
    human_genome_gb = human_genome_bytes / 1e9

    print(f"\n  Bases:              4 (A, T, G, C) = 2 bits each")
    print(f"  Human genome:       {human_genome_bp/1e9:.0f} billion base pairs")
    print(f"  Information:        {human_genome_gb:.2f} GB per cell")
    print(f"  Cells in body:      ~37 trillion")
    total_tb = human_genome_gb * 37e12 / 1e12
    print(f"  Total stored:       ~{total_tb:.0f} TB (if read out as files)")
    print(f"  DNA density:        ~215 petabytes per gram")
    print(f"  Best flash memory:  ~0.000001 petabytes per gram")
    print(f"\n  DNA stores 215,000,000× more information per gram than flash.")
    print(f"  It has been doing this for 3.8 billion years.")
    print(f"  No human-made storage system comes close.")
    print("""
  The compiler that builds you from this source code is the ribosome.
  It reads the sequence at 15 codons per second.
  It makes about 1 error per 10,000 amino acids.
  The error-correction system fixes most of those.

  This is not biology. This is computer science.
  It has been running since the Archean eon.
""")


def telomere_as_header():
    """Telomeres are like filesystem headers or write-protect flags."""
    print("=" * 60)
    print("TELOMERES — The Write-Protect Headers")
    print("=" * 60)
    print("""
  Telomeres are repetitive sequences at chromosome ends:
    TTAGGG TTAGGG TTAGGG TTAGGG ...  (repeated ~2,500 times)

  They protect coding DNA from replication errors at chromosome ends.
  With each cell division, telomeres shorten by ~50-200 base pairs.
  When they run out: the cell can no longer divide. This is aging.

  In filesystem terms:
    • Telomeres = file header / magic bytes
    • Shortening = a counter that decrements with each read/write
    • Telomere exhaustion = TTL (time-to-live) expiry

  The cell has a built-in write counter.
  Biology implemented TTL 3.5 billion years before TCP/IP.
""")


if __name__ == '__main__':
    show_redundancy()
    show_start_stop()
    storage_density()
    telomere_as_header()
    print("=" * 60)
    print("DNA is not like source code. It is source code.")
    print("The ribosome is not like a compiler. It is a compiler.")
    print("Biology is computer science. We just named them separately.")
    print("=" * 60)
