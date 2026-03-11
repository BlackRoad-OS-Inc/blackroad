"""Tests for the rpg module (Character and Game)."""

from __future__ import annotations

import random

from rpg import Character, Game


class TestCharacter:

    def test_initial_alive(self):
        c = Character("Hero", hp=10, attack_min=1, attack_max=3)
        assert c.is_alive()

    def test_dead_at_zero(self):
        c = Character("Hero", hp=0, attack_min=1, attack_max=3)
        assert not c.is_alive()

    def test_attack_deals_damage(self):
        rng = random.Random(42)
        attacker = Character("A", hp=10, attack_min=2, attack_max=5)
        defender = Character("B", hp=20, attack_min=1, attack_max=1)
        dmg = attacker.attack(defender, rng)
        assert 2 <= dmg <= 5
        assert defender.hp == 20 - dmg

    def test_hp_never_negative(self):
        rng = random.Random(0)
        attacker = Character("A", hp=10, attack_min=100, attack_max=100)
        defender = Character("B", hp=5, attack_min=1, attack_max=1)
        attacker.attack(defender, rng)
        assert defender.hp == 0


class TestGame:

    def test_game_produces_winner(self):
        rng = random.Random(99)
        player = Character("Player", hp=20, attack_min=3, attack_max=6)
        enemy = Character("Enemy", hp=15, attack_min=1, attack_max=3)
        game = Game(player, enemy, rng)
        winner = game.run()
        assert winner in {"Player", "Enemy"}

    def test_player_turn(self):
        rng = random.Random(1)
        player = Character("P", hp=10, attack_min=1, attack_max=1)
        enemy = Character("E", hp=5, attack_min=1, attack_max=1)
        game = Game(player, enemy, rng)
        dmg = game.player_turn()
        assert dmg == 1
        assert enemy.hp == 4

    def test_enemy_turn(self):
        rng = random.Random(1)
        player = Character("P", hp=10, attack_min=1, attack_max=1)
        enemy = Character("E", hp=5, attack_min=2, attack_max=2)
        game = Game(player, enemy, rng)
        dmg = game.enemy_turn()
        assert dmg == 2
        assert player.hp == 8

    def test_strong_player_wins(self):
        rng = random.Random(7)
        player = Character("P", hp=100, attack_min=50, attack_max=50)
        enemy = Character("E", hp=10, attack_min=1, attack_max=1)
        game = Game(player, enemy, rng)
        assert game.run() == "P"
