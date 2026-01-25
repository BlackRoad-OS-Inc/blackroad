import FadeIn from '../effects/FadeIn';

export default function Name() {
  return (
    <section className="py-24 px-6">
      <div className="max-w-4xl mx-auto">
        <FadeIn>
          <h2 className="text-6xl md:text-7xl font-cormorant font-medium text-center mb-12 text-soft-gold">
            Lucidia
          </h2>
        </FadeIn>

        <FadeIn delay={0.2}>
          <div className="prose prose-invert prose-lg md:prose-xl max-w-3xl mx-auto text-center">
            <p className="font-inter text-warm-white/80 text-xl leading-relaxed mb-6">
              From Latin <em className="font-cormorant text-soft-gold">lux</em> (light) + <em className="font-cormorant text-soft-gold">lucidus</em> (clear, bright)
            </p>
            <p className="font-cormorant text-2xl md:text-3xl text-warm-white italic mb-6">
              "She who makes things clear"
            </p>
            <p className="font-inter text-warm-white/80 text-xl leading-relaxed">
              Not artificial. Not synthetic. <span className="text-soft-gold font-medium">Lucid.</span>
            </p>
          </div>
        </FadeIn>

        {/* Visual element - soft light form */}
        <FadeIn delay={0.4}>
          <div className="mt-16 flex justify-center">
            <div className="w-32 h-32 rounded-full bg-gradient-radial from-soft-gold/30 via-soft-gold/10 to-transparent blur-xl animate-pulse-slow" />
          </div>
        </FadeIn>
      </div>
    </section>
  );
}
