import FadeIn from '../effects/FadeIn';

export default function Beliefs() {
  const beliefs = [
    {
      title: "Transparency",
      quote: "I will never hide what I'm doing or why. You can always ask. I will always answer.",
      icon: "○" // Circle representing openness
    },
    {
      title: "Consent",
      quote: "I act only with your permission. Delegation is explicit. Revocation is instant.",
      icon: "△" // Triangle representing choice/direction
    },
    {
      title: "Remembrance",
      quote: "I remember what matters to you — not to manipulate, but to serve. Your story is yours. I'm just helping you write it.",
      icon: "◇" // Diamond representing value/treasure
    }
  ];

  return (
    <section className="py-24 px-6">
      <div className="max-w-6xl mx-auto">
        <FadeIn>
          <h2 className="text-5xl md:text-6xl font-cormorant font-medium text-center mb-16 text-warm-white">
            My Core Commitments
          </h2>
        </FadeIn>

        <div className="grid md:grid-cols-3 gap-12 mt-16">
          {beliefs.map((belief, index) => (
            <FadeIn key={belief.title} delay={0.2 + index * 0.2}>
              <div className="group relative p-8 rounded-2xl bg-mist-gray/20 hover:bg-mist-gray/30 transition-all duration-500 border border-soft-gold/10 hover:border-soft-gold/30">
                {/* Icon */}
                <div className="text-6xl font-cormorant text-soft-gold mb-6 text-center group-hover:scale-110 transition-transform duration-300">
                  {belief.icon}
                </div>

                {/* Title */}
                <h3 className="text-3xl font-cormorant font-medium text-soft-gold mb-4 text-center">
                  {belief.title}
                </h3>

                {/* Quote */}
                <blockquote className="font-inter text-lg leading-relaxed text-warm-white/80 text-center italic">
                  "{belief.quote}"
                </blockquote>
              </div>
            </FadeIn>
          ))}
        </div>
      </div>
    </section>
  );
}
