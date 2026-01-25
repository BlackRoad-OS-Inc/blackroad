// Weather Effects System for RoadWorld
// Adds atmospheric visual effects based on time and simulated weather

export class WeatherEffects {
    constructor(mapManager) {
        this.mapManager = mapManager;
        this.weatherContainer = null;
        this.currentWeather = null;
        this.timeOfDay = null;
        this.particles = [];
        this.isActive = false;

        // Weather types with their visual properties
        this.weatherTypes = {
            clear: {
                name: 'Clear',
                icon: '☀️',
                particles: null,
                overlay: null,
                ambientLight: 1.0
            },
            cloudy: {
                name: 'Cloudy',
                icon: '☁️',
                particles: null,
                overlay: 'rgba(100, 100, 120, 0.15)',
                ambientLight: 0.8
            },
            rain: {
                name: 'Rain',
                icon: '🌧️',
                particles: 'rain',
                overlay: 'rgba(50, 60, 80, 0.25)',
                ambientLight: 0.6
            },
            storm: {
                name: 'Storm',
                icon: '⛈️',
                particles: 'rain-heavy',
                overlay: 'rgba(30, 40, 60, 0.35)',
                ambientLight: 0.4,
                lightning: true
            },
            snow: {
                name: 'Snow',
                icon: '❄️',
                particles: 'snow',
                overlay: 'rgba(200, 210, 230, 0.2)',
                ambientLight: 0.9
            },
            fog: {
                name: 'Fog',
                icon: '🌫️',
                particles: 'fog',
                overlay: 'rgba(180, 180, 190, 0.4)',
                ambientLight: 0.7
            }
        };
    }

    init() {
        this.createWeatherContainer();
        this.createOverlay();
        this.isActive = true;

        // Start with time-based weather
        this.updateTimeOfDay();
        this.simulateWeather();

        // Update every minute
        setInterval(() => this.updateTimeOfDay(), 60000);

        console.log('🌤️ Weather Effects initialized');
    }

    createWeatherContainer() {
        this.weatherContainer = document.createElement('div');
        this.weatherContainer.className = 'weather-container';
        this.weatherContainer.innerHTML = `
            <canvas id="weather-canvas"></canvas>
            <div class="weather-overlay"></div>
        `;
        document.body.appendChild(this.weatherContainer);

        this.canvas = document.getElementById('weather-canvas');
        this.ctx = this.canvas.getContext('2d');
        this.resizeCanvas();

        window.addEventListener('resize', () => this.resizeCanvas());
    }

    createOverlay() {
        this.overlay = this.weatherContainer.querySelector('.weather-overlay');
    }

    resizeCanvas() {
        this.canvas.width = window.innerWidth;
        this.canvas.height = window.innerHeight;
    }

    updateTimeOfDay() {
        const hour = new Date().getHours();

        let timeOfDay, ambientColor;

        if (hour >= 5 && hour < 7) {
            timeOfDay = 'dawn';
            ambientColor = 'rgba(255, 180, 100, 0.1)';
        } else if (hour >= 7 && hour < 17) {
            timeOfDay = 'day';
            ambientColor = 'transparent';
        } else if (hour >= 17 && hour < 20) {
            timeOfDay = 'dusk';
            ambientColor = 'rgba(255, 120, 80, 0.15)';
        } else {
            timeOfDay = 'night';
            ambientColor = 'rgba(20, 30, 60, 0.3)';
        }

        this.timeOfDay = timeOfDay;
        document.body.setAttribute('data-time', timeOfDay);

        // Apply time-based tint
        if (this.overlay) {
            this.overlay.style.background = ambientColor;
        }

        return timeOfDay;
    }

    simulateWeather() {
        // Simulate weather based on random chance and time
        const random = Math.random();
        const hour = new Date().getHours();
        const month = new Date().getMonth();

        let weather;

        // Winter months have more snow/fog
        const isWinter = month === 11 || month === 0 || month === 1;

        if (random < 0.5) {
            weather = 'clear';
        } else if (random < 0.65) {
            weather = 'cloudy';
        } else if (random < 0.8) {
            weather = isWinter ? 'snow' : 'rain';
        } else if (random < 0.9) {
            weather = 'fog';
        } else {
            weather = 'storm';
        }

        this.setWeather(weather);
    }

    setWeather(weatherType) {
        const weather = this.weatherTypes[weatherType];
        if (!weather) return;

        this.currentWeather = weatherType;
        this.stopParticles();

        // Apply overlay
        if (weather.overlay) {
            this.overlay.style.background = weather.overlay;
        }

        // Start particles
        if (weather.particles) {
            this.startParticles(weather.particles);
        }

        // Lightning effect
        if (weather.lightning) {
            this.startLightning();
        }

        console.log(`🌤️ Weather changed to: ${weather.name}`);
        return weather;
    }

    startParticles(type) {
        this.particles = [];

        const particleCount = type === 'rain-heavy' ? 200 :
                              type === 'rain' ? 100 :
                              type === 'snow' ? 80 :
                              type === 'fog' ? 30 : 50;

        for (let i = 0; i < particleCount; i++) {
            this.particles.push(this.createParticle(type));
        }

        this.animateParticles(type);
    }

    createParticle(type) {
        return {
            x: Math.random() * this.canvas.width,
            y: Math.random() * this.canvas.height,
            size: type === 'snow' ? Math.random() * 4 + 2 :
                  type === 'fog' ? Math.random() * 100 + 50 :
                  Math.random() * 2 + 1,
            speed: type === 'snow' ? Math.random() * 2 + 1 :
                   type === 'rain-heavy' ? Math.random() * 15 + 10 :
                   type === 'fog' ? Math.random() * 0.5 + 0.1 :
                   Math.random() * 10 + 5,
            opacity: type === 'fog' ? Math.random() * 0.3 + 0.1 :
                     Math.random() * 0.5 + 0.3,
            drift: type === 'snow' ? Math.random() * 2 - 1 :
                   type === 'fog' ? Math.random() * 1 - 0.5 : 0
        };
    }

    animateParticles(type) {
        if (!this.isActive) return;

        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

        this.particles.forEach(particle => {
            if (type === 'fog') {
                // Fog: large, blurry circles
                const gradient = this.ctx.createRadialGradient(
                    particle.x, particle.y, 0,
                    particle.x, particle.y, particle.size
                );
                gradient.addColorStop(0, `rgba(180, 180, 190, ${particle.opacity})`);
                gradient.addColorStop(1, 'rgba(180, 180, 190, 0)');

                this.ctx.fillStyle = gradient;
                this.ctx.beginPath();
                this.ctx.arc(particle.x, particle.y, particle.size, 0, Math.PI * 2);
                this.ctx.fill();

                particle.x += particle.drift;
                particle.y += particle.speed * 0.1;
            } else if (type === 'snow') {
                // Snow: white circles with drift
                this.ctx.fillStyle = `rgba(255, 255, 255, ${particle.opacity})`;
                this.ctx.beginPath();
                this.ctx.arc(particle.x, particle.y, particle.size, 0, Math.PI * 2);
                this.ctx.fill();

                particle.x += particle.drift + Math.sin(particle.y * 0.01) * 0.5;
                particle.y += particle.speed;
            } else {
                // Rain: lines
                this.ctx.strokeStyle = `rgba(150, 180, 220, ${particle.opacity})`;
                this.ctx.lineWidth = particle.size;
                this.ctx.beginPath();
                this.ctx.moveTo(particle.x, particle.y);
                this.ctx.lineTo(particle.x + 1, particle.y + particle.speed * 2);
                this.ctx.stroke();

                particle.y += particle.speed;
            }

            // Reset particles that go off screen
            if (particle.y > this.canvas.height) {
                particle.y = -10;
                particle.x = Math.random() * this.canvas.width;
            }
            if (particle.x > this.canvas.width) {
                particle.x = 0;
            } else if (particle.x < 0) {
                particle.x = this.canvas.width;
            }
        });

        this.animationFrame = requestAnimationFrame(() => this.animateParticles(type));
    }

    stopParticles() {
        if (this.animationFrame) {
            cancelAnimationFrame(this.animationFrame);
        }
        this.particles = [];
        if (this.ctx) {
            this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        }
    }

    startLightning() {
        const flash = () => {
            if (this.currentWeather !== 'storm') return;

            // Random flash
            if (Math.random() < 0.3) {
                const flashOverlay = document.createElement('div');
                flashOverlay.className = 'lightning-flash';
                document.body.appendChild(flashOverlay);

                setTimeout(() => {
                    flashOverlay.remove();
                }, 100);
            }

            // Schedule next potential flash
            setTimeout(flash, Math.random() * 5000 + 2000);
        };

        flash();
    }

    getWeatherInfo() {
        const weather = this.weatherTypes[this.currentWeather];
        return {
            type: this.currentWeather,
            ...weather,
            timeOfDay: this.timeOfDay
        };
    }

    toggle() {
        this.isActive = !this.isActive;

        if (this.isActive) {
            this.weatherContainer.style.display = 'block';
            this.simulateWeather();
        } else {
            this.weatherContainer.style.display = 'none';
            this.stopParticles();
        }

        return this.isActive;
    }

    destroy() {
        this.isActive = false;
        this.stopParticles();
        if (this.weatherContainer) {
            this.weatherContainer.remove();
        }
    }
}
