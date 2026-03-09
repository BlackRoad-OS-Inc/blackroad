// BlackRoad App
console.log('🖤 BlackRoad OS');

document.addEventListener('DOMContentLoaded', () => {
  // Add smooth scrolling
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', e => {
      e.preventDefault();
      document.querySelector(anchor.getAttribute('href')).scrollIntoView({ behavior: 'smooth' });
    });
  });
  
  // Add fade-in animation
  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) entry.target.classList.add('visible');
    });
  });
  
  document.querySelectorAll('.animate').forEach(el => observer.observe(el));
});
