#!/usr/bin/env python3
"""
BlackRoad Pixel Pokemon City
A pixel-art style Pokemon city with buildings, roads, NPCs, and Pokemon
"""
import pygame
import sys
import random

# Initialize pygame
pygame.init()

# Screen settings
WIDTH, HEIGHT = 800, 600
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("BlackRoad Pixel Pokemon City")
clock = pygame.time.Clock()

# Colors - Pokemon theme
SKY_BLUE = (135, 206, 250)
GRASS_GREEN = (34, 139, 34)
ROAD_GRAY = (128, 128, 128)
BUILDING_RED = (220, 20, 60)
BUILDING_BLUE = (30, 144, 255)
BUILDING_YELLOW = (255, 215, 0)
ROOF_BROWN = (139, 69, 19)
WINDOW_WHITE = (255, 255, 255)
DOOR_BROWN = (101, 67, 33)
TREE_GREEN = (0, 128, 0)
TREE_TRUNK = (101, 67, 33)
WATER_BLUE = (64, 164, 223)
NPC_SKIN = (255, 220, 177)
POKEBALL_RED = (255, 0, 0)
POKEBALL_WHITE = (255, 255, 255)

# Sprite classes
class Building:
    def __init__(self, x, y, width, height, color, building_type="house"):
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.color = color
        self.type = building_type
    
    def draw(self, surface):
        # Main building
        pygame.draw.rect(surface, self.color, (self.x, self.y, self.width, self.height))
        
        # Roof
        roof_points = [
            (self.x - 4, self.y),
            (self.x + self.width // 2, self.y - 20),
            (self.x + self.width + 4, self.y)
        ]
        pygame.draw.polygon(surface, ROOF_BROWN, roof_points)
        
        # Windows
        if self.type == "house":
            window_size = 8
            pygame.draw.rect(surface, WINDOW_WHITE, 
                           (self.x + 10, self.y + 15, window_size, window_size))
            pygame.draw.rect(surface, WINDOW_WHITE, 
                           (self.x + self.width - 18, self.y + 15, window_size, window_size))
        
        # Door
        door_width = 12
        door_height = 18
        pygame.draw.rect(surface, DOOR_BROWN, 
                        (self.x + self.width // 2 - door_width // 2, 
                         self.y + self.height - door_height, 
                         door_width, door_height))
        
        # Pokecenter cross (if pokecenter)
        if self.type == "pokecenter":
            cross_size = 10
            center_x = self.x + self.width // 2
            center_y = self.y + 10
            pygame.draw.rect(surface, POKEBALL_RED, 
                           (center_x - 2, center_y - cross_size // 2, 4, cross_size))
            pygame.draw.rect(surface, POKEBALL_RED, 
                           (center_x - cross_size // 2, center_y - 2, cross_size, 4))

class Tree:
    def __init__(self, x, y):
        self.x = x
        self.y = y
    
    def draw(self, surface):
        # Trunk
        pygame.draw.rect(surface, TREE_TRUNK, (self.x, self.y, 8, 16))
        # Leaves (3 circles)
        pygame.draw.circle(surface, TREE_GREEN, (self.x + 4, self.y - 4), 8)
        pygame.draw.circle(surface, TREE_GREEN, (self.x - 2, self.y + 2), 7)
        pygame.draw.circle(surface, TREE_GREEN, (self.x + 10, self.y + 2), 7)

class NPC:
    def __init__(self, x, y, npc_type="trainer"):
        self.x = x
        self.y = y
        self.type = npc_type
        self.direction = random.choice(['up', 'down', 'left', 'right'])
        self.move_counter = 0
        self.move_delay = random.randint(30, 90)
    
    def update(self):
        self.move_counter += 1
        if self.move_counter > self.move_delay:
            self.move_counter = 0
            self.move_delay = random.randint(30, 90)
            
            # Random walk
            if random.random() < 0.3:
                self.direction = random.choice(['up', 'down', 'left', 'right'])
            
            move_speed = 1
            if self.direction == 'up':
                self.y -= move_speed
            elif self.direction == 'down':
                self.y += move_speed
            elif self.direction == 'left':
                self.x -= move_speed
            elif self.direction == 'right':
                self.x += move_speed
            
            # Keep in bounds
            self.x = max(50, min(WIDTH - 50, self.x))
            self.y = max(50, min(HEIGHT - 50, self.y))
    
    def draw(self, surface):
        # Simple pixel NPC
        # Head
        pygame.draw.circle(surface, NPC_SKIN, (self.x, self.y), 6)
        
        # Body
        if self.type == "trainer":
            body_color = (255, 0, 0)  # Red trainer
        else:
            body_color = (0, 0, 255)  # Blue NPC
        
        pygame.draw.rect(surface, body_color, (self.x - 4, self.y + 6, 8, 10))
        
        # Arms
        pygame.draw.line(surface, NPC_SKIN, (self.x - 4, self.y + 8), (self.x - 8, self.y + 12), 2)
        pygame.draw.line(surface, NPC_SKIN, (self.x + 4, self.y + 8), (self.x + 8, self.y + 12), 2)
        
        # Legs
        pygame.draw.line(surface, (50, 50, 50), (self.x - 2, self.y + 16), (self.x - 3, self.y + 22), 2)
        pygame.draw.line(surface, (50, 50, 50), (self.x + 2, self.y + 16), (self.x + 3, self.y + 22), 2)

class Pokemon:
    def __init__(self, x, y, species="pikachu"):
        self.x = x
        self.y = y
        self.species = species
        self.direction = random.choice(['up', 'down', 'left', 'right'])
        self.move_counter = 0
        self.move_delay = random.randint(20, 60)
        self.hop = 0
    
    def update(self):
        self.move_counter += 1
        self.hop = (self.hop + 0.3) % 6.28  # Gentle hopping animation
        
        if self.move_counter > self.move_delay:
            self.move_counter = 0
            self.move_delay = random.randint(20, 60)
            
            if random.random() < 0.4:
                self.direction = random.choice(['up', 'down', 'left', 'right'])
            
            move_speed = 0.5
            if self.direction == 'up':
                self.y -= move_speed
            elif self.direction == 'down':
                self.y += move_speed
            elif self.direction == 'left':
                self.x -= move_speed
            elif self.direction == 'right':
                self.x += move_speed
            
            # Keep in grass areas
            self.x = max(30, min(WIDTH - 30, self.x))
            self.y = max(30, min(HEIGHT - 30, self.y))
    
    def draw(self, surface):
        hop_offset = int(abs(pygame.math.Vector2(0, 2).rotate(self.hop * 57.3).y))
        
        if self.species == "pikachu":
            # Yellow Pikachu
            body_color = (255, 220, 0)
            # Body
            pygame.draw.circle(surface, body_color, (self.x, self.y - hop_offset), 8)
            # Ears
            pygame.draw.polygon(surface, body_color, [
                (self.x - 6, self.y - hop_offset - 6),
                (self.x - 4, self.y - hop_offset - 14),
                (self.x - 2, self.y - hop_offset - 6)
            ])
            pygame.draw.polygon(surface, body_color, [
                (self.x + 2, self.y - hop_offset - 6),
                (self.x + 4, self.y - hop_offset - 14),
                (self.x + 6, self.y - hop_offset - 6)
            ])
            # Ear tips
            pygame.draw.circle(surface, (0, 0, 0), (self.x - 4, self.y - hop_offset - 14), 2)
            pygame.draw.circle(surface, (0, 0, 0), (self.x + 4, self.y - hop_offset - 14), 2)
            # Eyes
            pygame.draw.circle(surface, (0, 0, 0), (self.x - 3, self.y - hop_offset - 2), 2)
            pygame.draw.circle(surface, (0, 0, 0), (self.x + 3, self.y - hop_offset - 2), 2)
            # Cheeks (red circles)
            pygame.draw.circle(surface, (255, 0, 0), (self.x - 8, self.y - hop_offset), 3)
            pygame.draw.circle(surface, (255, 0, 0), (self.x + 8, self.y - hop_offset), 3)
            # Tail
            tail_points = [
                (self.x + 6, self.y - hop_offset + 2),
                (self.x + 10, self.y - hop_offset - 4),
                (self.x + 8, self.y - hop_offset + 4)
            ]
            pygame.draw.polygon(surface, body_color, tail_points)
        
        elif self.species == "bulbasaur":
            # Green Bulbasaur
            body_color = (0, 200, 100)
            # Body
            pygame.draw.circle(surface, body_color, (self.x, self.y - hop_offset), 7)
            # Bulb on back
            pygame.draw.circle(surface, (0, 150, 0), (self.x + 2, self.y - hop_offset - 6), 5)
            # Eyes
            pygame.draw.circle(surface, (255, 255, 255), (self.x - 2, self.y - hop_offset - 2), 2)
            pygame.draw.circle(surface, (255, 255, 255), (self.x + 2, self.y - hop_offset - 2), 2)
            pygame.draw.circle(surface, (0, 0, 0), (self.x - 2, self.y - hop_offset - 2), 1)
            pygame.draw.circle(surface, (0, 0, 0), (self.x + 2, self.y - hop_offset - 2), 1)

# Initialize city elements
buildings = [
    Building(100, 150, 60, 50, BUILDING_RED, "house"),
    Building(200, 150, 70, 60, BUILDING_BLUE, "house"),
    Building(320, 150, 80, 70, BUILDING_YELLOW, "pokecenter"),
    Building(450, 150, 60, 50, BUILDING_RED, "house"),
    Building(100, 350, 65, 55, BUILDING_BLUE, "house"),
    Building(450, 350, 70, 60, BUILDING_YELLOW, "house"),
]

trees = [
    Tree(80, 280), Tree(130, 300), Tree(170, 285),
    Tree(550, 180), Tree(590, 200), Tree(620, 185),
    Tree(60, 100), Tree(680, 350), Tree(720, 380),
]

npcs = [
    NPC(250, 300, "trainer"),
    NPC(400, 280, "npc"),
    NPC(150, 450, "trainer"),
    NPC(500, 420, "npc"),
]

pokemons = [
    Pokemon(300, 500, "pikachu"),
    Pokemon(180, 480, "bulbasaur"),
    Pokemon(520, 510, "pikachu"),
    Pokemon(600, 300, "bulbasaur"),
]

# Main game loop
running = True
while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False
    
    # Clear screen
    screen.fill(GRASS_GREEN)
    
    # Draw roads
    pygame.draw.rect(screen, ROAD_GRAY, (0, 250, WIDTH, 40))  # Horizontal road
    pygame.draw.rect(screen, ROAD_GRAY, (350, 0, 40, HEIGHT))  # Vertical road
    
    # Road lines
    for i in range(0, WIDTH, 30):
        pygame.draw.rect(screen, (255, 255, 255), (i, 268, 15, 4))
    for i in range(0, HEIGHT, 30):
        pygame.draw.rect(screen, (255, 255, 255), (368, i, 4, 15))
    
    # Draw water pond
    pygame.draw.ellipse(screen, WATER_BLUE, (550, 450, 120, 80))
    
    # Draw trees
    for tree in trees:
        tree.draw(screen)
    
    # Draw buildings
    for building in buildings:
        building.draw(screen)
    
    # Update and draw Pokemon
    for pokemon in pokemons:
        pokemon.update()
        pokemon.draw(screen)
    
    # Update and draw NPCs
    for npc in npcs:
        npc.update()
        npc.draw(screen)
    
    # Draw title
    font = pygame.font.Font(None, 36)
    title = font.render("BlackRoad Pixel Pokemon City", True, (255, 255, 255))
    title_bg = pygame.Surface((title.get_width() + 20, title.get_height() + 10))
    title_bg.fill((0, 0, 0))
    title_bg.set_alpha(180)
    screen.blit(title_bg, (WIDTH // 2 - title.get_width() // 2 - 10, 10))
    screen.blit(title, (WIDTH // 2 - title.get_width() // 2, 15))
    
    # Instructions
    small_font = pygame.font.Font(None, 20)
    instruction = small_font.render("Press ESC to exit", True, (255, 255, 255))
    screen.blit(instruction, (10, HEIGHT - 25))
    
    # Update display
    pygame.display.flip()
    clock.tick(60)

pygame.quit()
sys.exit()
