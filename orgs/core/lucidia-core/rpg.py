"""Tiny text-based RPG engine for Lucidia.

This module provides minimal classes to model a small turn-based battle game.
It can be imported as a library or executed directly for a quick demo.
"""
from __future__ import annotations

import random
from dataclasses import dataclass
from typing import Optional


@dataclass
class Character:
    """Basic combatant with hit points and attack range."""

    name: str
    hp: int
    attack_min: int
    attack_max: int

    def is_alive(self) -> bool:
        """Return ``True`` if the character still has hit points."""
        return self.hp > 0

    def attack(self, other: "Character", rng: random.Random) -> int:
        """Attack ``other`` and return the damage dealt."""
        damage = rng.randint(self.attack_min, self.attack_max)
        other.hp = max(0, other.hp - damage)
        return damage


class Game:
    """Manage a simple player-versus-enemy battle."""

    def __init__(
        self, player: Character, enemy: Character, rng: Optional[random.Random] = None
    ) -> None:
        self.player = player
        self.enemy = enemy
        self.rng = rng or random.Random()

    def player_turn(self) -> int:
        """Execute the player's attack."""
        return self.player.attack(self.enemy, self.rng)

    def enemy_turn(self) -> int:
        """Execute the enemy's attack."""
        return self.enemy.attack(self.player, self.rng)

    def run(self) -> str:
        """Run the battle until one character is defeated.

        Returns
        -------
        str
            The name of the winning character.
        """
        while self.player.is_alive() and self.enemy.is_alive():
            self.player_turn()
            if not self.enemy.is_alive():
                break
            self.enemy_turn()
        return self.player.name if self.player.is_alive() else self.enemy.name


def main() -> None:
    """Play a quick demo game in the console."""
    rng = random.Random()
    player = Character("Hero", hp=20, attack_min=2, attack_max=5)
    enemy = Character("Goblin", hp=15, attack_min=1, attack_max=4)
    game = Game(player, enemy, rng)
    print("Welcome to Lucidia RPG! Type 'attack' to strike your foe.")
    while player.is_alive() and enemy.is_alive():
        cmd = input("> ").strip().lower()
        if cmd != "attack":
            print("Unknown command. Try 'attack'.")
            continue
        dmg = game.player_turn()
        print(f"You hit {enemy.name} for {dmg} damage (hp={enemy.hp}).")
        if not enemy.is_alive():
            break
        dmg = game.enemy_turn()
        print(f"{enemy.name} hits you for {dmg} damage (hp={player.hp}).")
    winner = game.player.name if player.is_alive() else enemy.name
    print(f"{winner} wins!")


if __name__ == "__main__":
    main()
