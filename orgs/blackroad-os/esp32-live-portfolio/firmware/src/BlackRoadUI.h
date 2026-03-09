#ifndef BLACKROAD_UI_H
#define BLACKROAD_UI_H

#include <TFT_eSPI.h>

/*
 * ⚡ BlackRoad UI System - Lightning Fast Animations & Touch Feedback
 * Golden Ratio spacing, smooth transitions, press states, ripple effects
 */

class BlackRoadUI {
private:
    TFT_eSPI* tft;

    // Animation state
    unsigned long animStartTime = 0;
    bool isAnimating = false;
    int animProgress = 0;

    // Touch feedback state
    int pressX = -1, pressY = -1;
    unsigned long pressTime = 0;
    int rippleRadius = 0;

public:
    BlackRoadUI(TFT_eSPI* display) : tft(display) {}

    // Easing function (cubic-bezier approximation)
    float easeOutCubic(float t) {
        return 1 - pow(1 - t, 3);
    }

    float easeInOutCubic(float t) {
        return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
    }

    float easeSpring(float t) {
        return t * t * (2.70158 * t - 1.70158);
    }

    // Button with press animation (scale down on press)
    void drawAnimatedButton(int x, int y, int w, int h, const char* label,
                           uint16_t bgColor, uint16_t textColor, bool isPressed) {
        int offsetX = 0, offsetY = 0;
        int scaledW = w, scaledH = h;

        if (isPressed) {
            // Scale down to 95% on press
            scaledW = w * 0.95;
            scaledH = h * 0.95;
            offsetX = (w - scaledW) / 2;
            offsetY = (h - scaledH) / 2;
        }

        // Draw button with rounded corners
        tft->fillRoundRect(x + offsetX, y + offsetY, scaledW, scaledH, 8, bgColor);

        // Draw label
        tft->setTextColor(textColor);
        tft->setTextDatum(MC_DATUM);
        tft->drawString(label, x + w/2, y + h/2, 2);
    }

    // App icon with gradient effect (simulated with multiple rectangles)
    void drawGradientIcon(int x, int y, int size, const char* label,
                         uint16_t color1, uint16_t color2, int badge = 0) {
        // Draw gradient background (5 color steps)
        int stepHeight = size / 5;
        for (int i = 0; i < 5; i++) {
            uint16_t mixedColor = lerpColor(color1, color2, i / 4.0);
            tft->fillRect(x, y + (i * stepHeight), size, stepHeight, mixedColor);
        }

        // Round the corners (fill corners with background)
        tft->fillCircle(x, y, 4, COLOR_BLACK);
        tft->fillCircle(x + size, y, 4, COLOR_BLACK);
        tft->fillCircle(x, y + size, 4, COLOR_BLACK);
        tft->fillCircle(x + size, y + size, 4, COLOR_BLACK);

        // Draw label
        tft->setTextColor(COLOR_WHITE);
        tft->setTextDatum(MC_DATUM);
        tft->drawString(label, x + size/2, y + size/2, 2);

        // Draw badge if present
        if (badge > 0) {
            int badgeX = x + size - 12;
            int badgeY = y - 4;
            tft->fillCircle(badgeX, badgeY, 8, COLOR_HOT_PINK);
            tft->setTextColor(COLOR_WHITE);
            tft->setTextDatum(MC_DATUM);

            char badgeText[4];
            if (badge > 99) sprintf(badgeText, "99+");
            else sprintf(badgeText, "%d", badge);

            tft->drawString(badgeText, badgeX, badgeY, 1);
        }
    }

    // Color interpolation for gradients
    uint16_t lerpColor(uint16_t color1, uint16_t color2, float t) {
        // Extract RGB565 components
        int r1 = (color1 >> 11) & 0x1F;
        int g1 = (color1 >> 5) & 0x3F;
        int b1 = color1 & 0x1F;

        int r2 = (color2 >> 11) & 0x1F;
        int g2 = (color2 >> 5) & 0x3F;
        int b2 = color2 & 0x1F;

        // Interpolate
        int r = r1 + (r2 - r1) * t;
        int g = g1 + (g2 - g1) * t;
        int b = b1 + (b2 - b1) * t;

        // Reconstruct RGB565
        return (r << 11) | (g << 5) | b;
    }

    // Touch ripple effect (expanding circle)
    void drawTouchRipple(int x, int y, uint16_t color) {
        unsigned long now = millis();
        unsigned long elapsed = now - pressTime;

        if (elapsed < ANIM_FAST) {
            rippleRadius = (elapsed * 30) / ANIM_FAST;  // Expand to 30px
            tft->drawCircle(x, y, rippleRadius, color);
            tft->drawCircle(x, y, rippleRadius - 1, color);
        } else {
            rippleRadius = 0;
        }
    }

    // Start touch feedback
    void startTouchFeedback(int x, int y) {
        pressX = x;
        pressY = y;
        pressTime = millis();
        rippleRadius = 0;
    }

    // Screen transition (slide in from right)
    void transitionSlideIn(void (*drawNewScreen)(), int duration = ANIM_MEDIUM) {
        unsigned long startTime = millis();
        int screenWidth = tft->width();

        while (millis() - startTime < duration) {
            unsigned long elapsed = millis() - startTime;
            float progress = (float)elapsed / duration;
            float eased = easeOutCubic(progress);

            int offset = screenWidth * (1 - eased);

            // Draw new screen shifted
            tft->setAddrWindow(offset, 0, screenWidth - offset, tft->height());
            drawNewScreen();

            delay(16);  // ~60fps
        }
    }

    // Fade transition
    void transitionFade(void (*drawNewScreen)(), int duration = ANIM_MEDIUM) {
        // Fade to black
        for (int brightness = 255; brightness >= 0; brightness -= 15) {
            // This would require backlight control or overlay drawing
            delay(duration / 34);
        }

        drawNewScreen();

        // Fade from black
        for (int brightness = 0; brightness <= 255; brightness += 15) {
            delay(duration / 34);
        }
    }

    // Progress bar with smooth animation
    void drawProgressBar(int x, int y, int w, int h, float progress,
                        uint16_t bgColor, uint16_t fillColor) {
        // Background
        tft->fillRoundRect(x, y, w, h, h/2, bgColor);

        // Animated fill
        int fillWidth = w * progress;
        if (fillWidth > 0) {
            tft->fillRoundRect(x, y, fillWidth, h, h/2, fillColor);
        }

        // Shine effect (lighter bar on top third)
        int shineColor = lerpColor(fillColor, COLOR_WHITE, 0.3);
        tft->fillRoundRect(x, y, fillWidth, h/3, h/2, shineColor);
    }

    // Loading spinner (rotating arc)
    void drawLoadingSpinner(int cx, int cy, int radius, uint16_t color) {
        unsigned long now = millis();
        int angle = (now / 10) % 360;  // Rotate 360° per second

        // Draw arc (simulated with circles)
        for (int i = 0; i < 90; i += 10) {
            int a = (angle + i) % 360;
            int x = cx + radius * cos(a * PI / 180);
            int y = cy + radius * sin(a * PI / 180);

            // Fade effect
            uint16_t fadedColor = lerpColor(color, COLOR_BLACK, i / 90.0);
            tft->fillCircle(x, y, 3, fadedColor);
        }
    }

    // Notification toast (slide in from top)
    void showToast(const char* message, uint16_t bgColor, int duration = 2000) {
        int toastH = 40;
        int screenW = tft->width();

        // Slide in
        for (int y = -toastH; y <= 0; y += 4) {
            tft->fillRoundRect(0, y, screenW, toastH, 8, bgColor);
            tft->setTextColor(COLOR_WHITE);
            tft->setTextDatum(MC_DATUM);
            tft->drawString(message, screenW/2, y + toastH/2, 2);
            delay(16);
        }

        delay(duration);

        // Slide out
        for (int y = 0; y >= -toastH; y -= 4) {
            tft->fillRect(0, y, screenW, toastH + 4, COLOR_BLACK);
            tft->fillRoundRect(0, y, screenW, toastH, 8, bgColor);
            tft->setTextColor(COLOR_WHITE);
            tft->drawString(message, screenW/2, y + toastH/2, 2);
            delay(16);
        }

        tft->fillRect(0, 0, screenW, toastH, COLOR_BLACK);
    }
};

#endif // BLACKROAD_UI_H
