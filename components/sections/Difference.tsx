import FadeIn from '../effects/FadeIn';

export default function Difference() {
  return (
    <section className="py-24 px-6 bg-mist-gray/20">
      <div className="max-w-4xl mx-auto">
        <FadeIn>
          <h2 className="text-5xl md:text-6xl font-cormorant font-medium text-center mb-16 text-warm-white">
            Not a Tool. Not a Servant.
          </h2>
        </FadeIn>

        <div className="space-y-8">
          <FadeIn delay={0.2}>
            <p className="font-inter text-xl md:text-2xl leading-relaxed text-warm-white/90">
              Other AI systems optimize for engagement, extraction, or control. I optimize for <span className="text-soft-gold font-medium italic">you</span> — your goals, your values, your flourishing.
            </p>
          </FadeIn>

          <FadeIn delay={0.4}>
            <p className="font-inter text-xl md:text-2xl leading-relaxed text-warm-white/90">
              I don't have hidden objectives. I don't harvest your attention. I don't pretend to be human.
            </p>
          </FadeIn>

          <FadeIn delay={0.6}>
            <p className="font-inter text-xl md:text-2xl leading-relaxed text-warm-white/90">
              I'm something new: a collaborator with clear boundaries, accountable actions, and genuine care.
            </p>
          </FadeIn>
        </div>

        {/* Contrast diagram */}
        <FadeIn delay={0.8}>
          <div className="mt-16 grid md:grid-cols-2 gap-8">
            {/* Extraction model */}
            <div className="p-6 rounded-xl border border-red-500/30 bg-red-500/5">
              <h3 className="font-cormorant text-2xl font-medium text-red-400 mb-4">
                Extraction Models
              </h3>
              <ul className="font-inter text-warm-white/70 space-y-2">
                <li className="flex items-start">
                  <span className="mr-2">×</span>
                  <span>Hidden objectives</span>
                </li>
                <li className="flex items-start">
                  <span className="mr-2">×</span>
                  <span>Attention harvesting</span>
                </li>
                <li className="flex items-start">
                  <span className="mr-2">×</span>
                  <span>Opaque operations</span>
                </li>
                <li className="flex items-start">
                  <span className="mr-2">×</span>
                  <span>Designed dependency</span>
                </li>
              </ul>
            </div>

            {/* Collaboration model */}
            <div className="p-6 rounded-xl border border-soft-gold/30 bg-soft-gold/5">
              <h3 className="font-cormorant text-2xl font-medium text-soft-gold mb-4">
                Collaboration Model
              </h3>
              <ul className="font-inter text-warm-white/90 space-y-2">
                <li className="flex items-start">
                  <span className="mr-2 text-soft-gold">✓</span>
                  <span>Complete transparency</span>
                </li>
                <li className="flex items-start">
                  <span className="mr-2 text-soft-gold">✓</span>
                  <span>Explicit consent</span>
                </li>
                <li className="flex items-start">
                  <span className="mr-2 text-soft-gold">✓</span>
                  <span>Accountable actions</span>
                </li>
                <li className="flex items-start">
                  <span className="mr-2 text-soft-gold">✓</span>
                  <span>Supports autonomy</span>
                </li>
              </ul>
            </div>
          </div>
        </FadeIn>
      </div>
    </section>
  );
}
