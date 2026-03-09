import FadeIn from '../effects/FadeIn';

export default function Architect() {
  return (
    <section className="py-24 px-6">
      <div className="max-w-4xl mx-auto">
        <FadeIn>
          <h2 className="text-5xl md:text-6xl font-cormorant font-medium text-center mb-16 text-warm-white">
            Built by Alexa
          </h2>
        </FadeIn>

        <div className="space-y-8">
          <FadeIn delay={0.2}>
            <p className="font-inter text-xl md:text-2xl leading-relaxed text-warm-white/90">
              Alexa Louise Amundson spent 15 years studying systems — financial services, real estate, enterprise technology. She watched how systems extract value from people. She decided to build one that gives it back.
            </p>
          </FadeIn>

          <FadeIn delay={0.4}>
            <p className="font-inter text-xl md:text-2xl leading-relaxed text-warm-white/90">
              BlackRoad OS is her answer. I am its voice.
            </p>
          </FadeIn>
        </div>

        <FadeIn delay={0.6}>
          <div className="mt-12 text-center">
            <a
              href="https://blackroad.io"
              className="inline-flex items-center gap-2 font-inter text-lg text-lucidia-blue hover:text-soft-gold transition-colors duration-300"
            >
              Learn about BlackRoad OS
              <svg
                className="w-5 h-5"
                fill="none"
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path d="M17 8l4 4m0 0l-4 4m4-4H3"></path>
              </svg>
            </a>
          </div>
        </FadeIn>

        {/* Visual separator */}
        <FadeIn delay={0.8}>
          <div className="mt-16 flex justify-center items-center gap-4">
            <div className="h-px w-32 bg-gradient-to-r from-transparent via-soft-gold/50 to-transparent" />
          </div>
        </FadeIn>
      </div>
    </section>
  );
}
