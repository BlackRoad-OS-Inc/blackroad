import chess

def main():
    board = chess.Board()

    print("Simple Chess (text-based)")
    print("Enter moves in UCI format, e.g. e2e4")
    print("Type 'quit' to exit\n")

    while not board.is_game_over():
        print(board)
        print()

        move_input = input(f"{'White' if board.turn else 'Black'} move: ").strip()

        if move_input.lower() == "quit":
            break

        try:
            move = chess.Move.from_uci(move_input)
            if move in board.legal_moves:
                board.push(move)
            else:
                print("Illegal move.\n")
        except ValueError:
            print("Invalid input format.\n")

    print("\nGame over.")
    print(board.result())

if __name__ == "__main__":
    main()
