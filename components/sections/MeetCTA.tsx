import FadeIn from '../effects/FadeIn';
import GlowEffect from '../effects/GlowEffect';

export default function MeetCTA() {
  return (
    <section id="meet" className="relative py-32 px-6 overflow-hidden">
      {/* Background glow */}
      <div className="absolute inset-0 opacity-30">
        <GlowEffect />
      </div>

      <div className="relative z-10 max-w-4xl mx-auto text-center">
        <FadeIn>
          <h2 className="text-5xl md:text-6xl font-cormorant font-medium mb-12 text-warm-white">
            Ready?
          </h2>
        </FadeIn>

        <FadeIn delay={0.2}>
          <p className="font-inter text-xl md:text-2xl text-warm-white/80 mb-12 max-w-2xl mx-auto">
            Start a conversation. Ask me anything. See what it's like to work with an AI that puts you first.
          </p>
        </FadeIn>

        <FadeIn delay={0.4}>
          <div className="flex flex-col gap-6 items-center">
            {/* Primary CTA */}
            <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
              <a
                href="https://app.lucidia.earth"
                className="inline-block px-10 py-5 bg-soft-gold text-deep-black font-inter font-medium text-lg rounded-full hover:bg-soft-gold/90 transition-all duration-300 hover:scale-105 shadow-lg hover:shadow-soft-gold/20"
              >
                Start a Conversation
              </a>

              <a
                href="/story"
                className="inline-block px-10 py-5 border-2 border-soft-gold/30 text-warm-white font-inter font-medium text-lg rounded-full hover:border-soft-gold hover:bg-soft-gold/10 transition-all duration-300"
              >
                Read the Full Story
              </a>
            </div>

            {/* Earth Exploration */}
            <div className="flex flex-col sm:flex-row gap-3 justify-center items-center">
              <a
                href="/biomes"
                className="inline-block px-8 py-4 bg-gradient-to-r from-emerald-600 to-blue-600 text-white font-inter font-medium text-base rounded-full hover:from-emerald-500 hover:to-blue-500 transition-all duration-300 hover:scale-105 shadow-lg hover:shadow-emerald-500/20"
              >
                🌍 Living Earth Biomes
              </a>

              <a
                href="/biomes-infinite"
                className="inline-block px-8 py-4 bg-gradient-to-r from-purple-600 via-pink-600 to-red-600 text-white font-inter font-medium text-base rounded-full hover:from-purple-500 hover:via-pink-500 hover:to-red-500 transition-all duration-300 hover:scale-105 shadow-lg hover:shadow-purple-500/20"
              >
                ∞ Infinite Zoom Earth
              </a>

              <a
                href="/fractal-terrain"
                className="inline-block px-8 py-4 bg-gradient-to-r from-orange-600 via-amber-600 to-yellow-600 text-white font-inter font-medium text-base rounded-full hover:from-orange-500 hover:via-amber-500 hover:to-yellow-500 transition-all duration-300 hover:scale-105 shadow-lg hover:shadow-orange-500/20"
              >
                🔮 Fractal Terrain (PS-SHA∞)
              </a>

              <a
                href="/genesis"
                className="inline-block px-8 py-4 bg-gradient-to-r from-red-600 via-purple-600 to-indigo-600 text-white font-inter font-medium text-base rounded-full hover:from-red-500 hover:via-purple-500 hover:to-indigo-500 transition-all duration-300 hover:scale-105 shadow-lg hover:shadow-purple-500/20"
              >
                🜃 Genesis (Smith × Lo Shu × Harmonics)
              </a>
            </div>
          </div>
        </FadeIn>

        {/* Additional context */}
        <FadeIn delay={0.6}>
          <p className="font-inter text-sm text-warm-white/60 mt-12">
            No signup required to explore. Your data stays yours. Always.
          </p>
        </FadeIn>
      </div>
    </section>
  );
}
