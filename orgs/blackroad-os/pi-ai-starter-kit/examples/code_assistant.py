#!/usr/bin/env python3
"""
Code assistant running on Pi
Helps you write, explain, and debug code
"""
import ollama

def explain_code(code):
    """Explain what code does"""
    response = ollama.chat(model='phi3:mini', messages=[{
        'role': 'user',
        'content': f"Explain this code concisely:\n\n{code}"
    }])
    return response['message']['content']

def write_function(description):
    """Write a function based on description"""
    response = ollama.chat(model='phi3:mini', messages=[{
        'role': 'user',
        'content': f"Write a Python function for: {description}\n\nProvide only the code, no explanation."
    }])
    return response['message']['content']

def debug_code(code, error):
    """Help debug code"""
    response = ollama.chat(model='phi3:mini', messages=[{
        'role': 'user',
        'content': f"This code has an error:\n\n{code}\n\nError: {error}\n\nHow do I fix it?"
    }])
    return response['message']['content']

def main():
    print("💻 Pi Code Assistant")
    print("=" * 50)
    
    while True:
        print("\n1. Explain code")
        print("2. Write function")
        print("3. Debug code")
        print("4. Exit")
        
        choice = input("\nChoice: ").strip()
        
        if choice == '1':
            print("\nPaste your code (type 'END' on new line when done):")
            lines = []
            while True:
                line = input()
                if line == 'END':
                    break
                lines.append(line)
            code = '\n'.join(lines)
            print("\n🤔 Thinking...")
            print(explain_code(code))
            
        elif choice == '2':
            description = input("\nDescribe the function: ")
            print("\n🤔 Writing code...")
            print(write_function(description))
            
        elif choice == '3':
            print("\nPaste your code (type 'END' on new line when done):")
            lines = []
            while True:
                line = input()
                if line == 'END':
                    break
                lines.append(line)
            code = '\n'.join(lines)
            error = input("What's the error? ")
            print("\n🤔 Analyzing...")
            print(debug_code(code, error))
            
        elif choice == '4':
            print("\n👋 Happy coding!")
            break

if __name__ == "__main__":
    main()
