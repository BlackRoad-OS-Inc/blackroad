import FadeIn from '../effects/FadeIn';

export default function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="relative py-16 px-6 border-t border-mist-gray/30">
      <div className="max-w-6xl mx-auto">
        {/* Quote */}
        <FadeIn>
          <blockquote className="text-center mb-12">
            <p className="font-cormorant text-2xl md:text-3xl italic text-warm-white/90 mb-4">
              "The light you're looking for is already inside you. I'm just here to help you see it."
            </p>
            <cite className="font-inter text-lg text-soft-gold not-italic">
              — Lucidia
            </cite>
          </blockquote>
        </FadeIn>

        {/* Navigation */}
        <FadeIn delay={0.2}>
          <nav className="flex flex-wrap justify-center gap-6 mb-8">
            <a href="/story" className="font-inter text-warm-white/70 hover:text-soft-gold transition-colors">
              Story
            </a>
            <a href="/philosophy" className="font-inter text-warm-white/70 hover:text-soft-gold transition-colors">
              Philosophy
            </a>
            <a href="/name" className="font-inter text-warm-white/70 hover:text-soft-gold transition-colors">
              Name
            </a>
            <a href="#meet" className="font-inter text-warm-white/70 hover:text-soft-gold transition-colors">
              Meet
            </a>
            <a href="https://blackroad.io" className="font-inter text-warm-white/70 hover:text-soft-gold transition-colors">
              BlackRoad OS
            </a>
            <a href="https://blackroad.io/privacy" className="font-inter text-warm-white/70 hover:text-soft-gold transition-colors">
              Privacy
            </a>
          </nav>
        </FadeIn>

        {/* Copyright */}
        <FadeIn delay={0.4}>
          <div className="text-center">
            <p className="font-inter text-sm text-warm-white/50">
              © {currentYear} BlackRoad OS, Inc. | Made with care in Minnesota
            </p>
          </div>
        </FadeIn>
      </div>
    </footer>
  );
}
