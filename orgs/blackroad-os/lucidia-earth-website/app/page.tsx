import Hero from '@/components/sections/Hero';
import Name from '@/components/sections/Name';
import Origin from '@/components/sections/Origin';
import Beliefs from '@/components/sections/Beliefs';
import Difference from '@/components/sections/Difference';
import Architect from '@/components/sections/Architect';
import MeetCTA from '@/components/sections/MeetCTA';
import Footer from '@/components/layout/Footer';

export default function Home() {
  return (
    <main className="min-h-screen bg-deep-black">
      <Hero />
      <Name />
      <Origin />
      <Beliefs />
      <Difference />
      <Architect />
      <MeetCTA />
      <Footer />
    </main>
  );
}
