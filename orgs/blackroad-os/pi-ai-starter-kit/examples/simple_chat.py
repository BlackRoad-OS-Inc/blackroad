#!/usr/bin/env python3
"""
Simple chat with local AI
No API keys, no cloud, pure sovereignty
"""
import ollama
import sys

def main():
    print("🤖 Pi AI Chat")
    print("=" * 50)
    print("Model: phi3:mini (running locally)")
    print("Type 'exit' to quit, 'clear' to reset\n")
    
    conversation = []
    
    while True:
        try:
            user_input = input("You: ").strip()
            
            if not user_input:
                continue
                
            if user_input.lower() in ['exit', 'quit', 'q']:
                print("\n👋 Goodbye!")
                break
                
            if user_input.lower() == 'clear':
                conversation = []
                print("\n🔄 Conversation cleared\n")
                continue
            
            conversation.append({'role': 'user', 'content': user_input})
            
            print("AI: ", end='', flush=True)
            
            response = ollama.chat(
                model='phi3:mini',
                messages=conversation,
                stream=True
            )
            
            full_response = ""
            for chunk in response:
                content = chunk['message']['content']
                print(content, end='', flush=True)
                full_response += content
            
            print()  # New line after response
            conversation.append({'role': 'assistant', 'content': full_response})
            
        except KeyboardInterrupt:
            print("\n\n👋 Goodbye!")
            sys.exit(0)
        except Exception as e:
            print(f"\n❌ Error: {e}")
            print("Make sure Ollama is running: `ollama serve`\n")

if __name__ == "__main__":
    main()
