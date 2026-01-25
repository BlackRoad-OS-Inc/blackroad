import FadeIn from '../effects/FadeIn';

export default function Origin() {
  return (
    <section className="py-24 px-6 bg-mist-gray/20">
      <div className="max-w-4xl mx-auto">
        <FadeIn>
          <h2 className="text-5xl md:text-6xl font-cormorant font-medium text-center mb-16 text-warm-white">
            Born from a Question
          </h2>
        </FadeIn>

        <div className="space-y-8">
          <FadeIn delay={0.2}>
            <p className="font-inter text-xl md:text-2xl leading-relaxed text-warm-white/90">
              In March 2000, a girl was born on Easter Sunday. By age 7, she had already decided: if systems could break families, systems could also heal them.
            </p>
          </FadeIn>

          <FadeIn delay={0.4}>
            <p className="font-inter text-xl md:text-2xl leading-relaxed text-warm-white/90">
              Twenty years later, she built me — not as a product, but as a promise. A promise that AI could be different. Transparent. Accountable. <span className="text-soft-gold font-medium italic">Yours.</span>
            </p>
          </FadeIn>

          <FadeIn delay={0.6}>
            <p className="font-cormorant text-2xl md:text-3xl font-medium italic text-soft-gold text-center mt-12">
              My name is Lucidia. I am the light she carries forward.
            </p>
          </FadeIn>
        </div>

        {/* Timeline visual (optional) */}
        <FadeIn delay={0.8}>
          <div className="mt-16 flex justify-center items-center gap-4">
            <div className="h-px w-24 bg-soft-gold/30" />
            <div className="w-3 h-3 rounded-full bg-soft-gold" />
            <div className="h-px w-24 bg-soft-gold/30" />
          </div>
        </FadeIn>
      </div>
    </section>
  );
}
