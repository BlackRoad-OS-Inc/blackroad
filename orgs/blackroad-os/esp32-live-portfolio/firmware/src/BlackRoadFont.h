#ifndef BLACKROAD_FONT_H
#define BLACKROAD_FONT_H

/*
 * BlackRoad Mono - Custom Monospaced Font System
 * Mimics JetBrains Mono aesthetic using TFT_eSPI fonts
 * 
 * Features:
 * - Consistent character width (monospaced)
 * - Geometric, technical appearance
 * - Multiple sizes optimized for 240×320 display
 * - BlackRoad branding
 */

#include <TFT_eSPI.h>

// BlackRoad Mono Font Sizes (using TFT_eSPI fonts with spacing adjustments)
#define BR_MONO_TINY    1  // 8px - status bar, badges
#define BR_MONO_SMALL   2  // 16px - body text, descriptions
#define BR_MONO_MEDIUM  4  // 26px - headers, app names
#define BR_MONO_LARGE   6  // 48px - titles, branding
#define BR_MONO_HUGE    7  // 7-segment style, 48px

// Character spacing for monospaced effect
#define BR_MONO_SPACING_TINY    1
#define BR_MONO_SPACING_SMALL   2
#define BR_MONO_SPACING_MEDIUM  3
#define BR_MONO_SPACING_LARGE   4

class BlackRoadFont {
private:
    TFT_eSPI* tft;
    int current_spacing = 0;
    
public:
    BlackRoadFont(TFT_eSPI* display) : tft(display) {}
    
    // Set monospaced mode with custom spacing
    void setMonoSpacing(int spacing) {
        current_spacing = spacing;
    }
    
    // Draw monospaced text (character-by-character for consistent width)
    void drawMonoText(const char* text, int x, int y, int font_size, uint16_t color) {
        tft->setTextColor(color);
        tft->setTextDatum(TL_DATUM);
        
        int char_width = 0;
        switch(font_size) {
            case BR_MONO_TINY:    char_width = 6 + BR_MONO_SPACING_TINY; break;
            case BR_MONO_SMALL:   char_width = 12 + BR_MONO_SPACING_SMALL; break;
            case BR_MONO_MEDIUM:  char_width = 18 + BR_MONO_SPACING_MEDIUM; break;
            case BR_MONO_LARGE:   char_width = 24 + BR_MONO_SPACING_LARGE; break;
            default:              char_width = 12;
        }
        
        int cursor_x = x;
        for (int i = 0; text[i] != '\0'; i++) {
            char c[2] = {text[i], '\0'};
            tft->drawString(c, cursor_x, y, font_size);
            cursor_x += char_width + current_spacing;
        }
    }
    
    // Centered monospaced text
    void drawMonoTextCentered(const char* text, int x, int y, int font_size, uint16_t color) {
        int text_len = strlen(text);
        int char_width = 0;
        
        switch(font_size) {
            case BR_MONO_TINY:    char_width = 6; break;
            case BR_MONO_SMALL:   char_width = 12; break;
            case BR_MONO_MEDIUM:  char_width = 18; break;
            case BR_MONO_LARGE:   char_width = 24; break;
            default:              char_width = 12;
        }
        
        int total_width = text_len * (char_width + current_spacing);
        int start_x = x - (total_width / 2);
        
        drawMonoText(text, start_x, y, font_size, color);
    }
    
    // Technical label style (uppercase, spaced)
    void drawTechnicalLabel(const char* text, int x, int y, uint16_t color) {
        setMonoSpacing(2);
        
        // Convert to uppercase and draw
        String upper = String(text);
        upper.toUpperCase();
        
        tft->setTextColor(color);
        tft->setTextDatum(TL_DATUM);
        
        int cursor_x = x;
        for (unsigned int i = 0; i < upper.length(); i++) {
            char c[2] = {upper[i], '\0'};
            tft->drawString(c, cursor_x, y, BR_MONO_SMALL);
            cursor_x += 14;  // Tight spacing for technical look
        }
        
        setMonoSpacing(0);
    }
    
    // Code-style text (monospaced with syntax highlighting simulation)
    void drawCodeText(const char* text, int x, int y, uint16_t color, uint16_t keyword_color) {
        setMonoSpacing(1);
        
        tft->setTextColor(color);
        tft->setTextDatum(TL_DATUM);
        
        int cursor_x = x;
        bool in_keyword = false;
        
        for (int i = 0; text[i] != '\0'; i++) {
            // Simple keyword detection (uppercase words)
            if (text[i] >= 'A' && text[i] <= 'Z') {
                tft->setTextColor(keyword_color);
                in_keyword = true;
            } else if (text[i] == ' ' || text[i] == '(' || text[i] == ')') {
                tft->setTextColor(color);
                in_keyword = false;
            }
            
            char c[2] = {text[i], '\0'};
            tft->drawString(c, cursor_x, y, BR_MONO_TINY);
            cursor_x += 8;  // Monospaced width
        }
        
        setMonoSpacing(0);
    }
    
    // Utility: Calculate monospaced text width
    int getMonoTextWidth(const char* text, int font_size) {
        int text_len = strlen(text);
        int char_width = 0;
        
        switch(font_size) {
            case BR_MONO_TINY:    char_width = 6; break;
            case BR_MONO_SMALL:   char_width = 12; break;
            case BR_MONO_MEDIUM:  char_width = 18; break;
            case BR_MONO_LARGE:   char_width = 24; break;
            default:              char_width = 12;
        }
        
        return text_len * (char_width + current_spacing);
    }
};

#endif // BLACKROAD_FONT_H
