'use client';

import { useState } from 'react';
import { MessageSquare, Plus } from 'lucide-react';

interface Conversation {
  id: string;
  title: string;
  lastMessage: string;
  timestamp: string;
}

export default function WorkspacePage() {
  const [conversations] = useState<Conversation[]>([
    {
      id: '1',
      title: 'Getting Started with BlackRoad OS',
      lastMessage: 'How can I help you today?',
      timestamp: '2 hours ago',
    },
    {
      id: '2',
      title: 'Project Planning',
      lastMessage: 'Let me summarize the key tasks...',
      timestamp: 'Yesterday',
    },
  ]);

  return (
    <div className="h-full p-6">
      <div className="max-w-7xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl font-semibold text-gray-900 mb-2">
            Conversations
          </h1>
          <p className="text-gray-600">
            Continue your conversations with Lucidia or start a new one
          </p>
        </div>

        {/* Empty state or conversation list */}
        {conversations.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20">
            <div className="h-24 w-24 rounded-full bg-gray-100 flex items-center justify-center mb-6">
              <MessageSquare className="h-12 w-12 text-gray-400" />
            </div>
            <h3 className="text-xl font-semibold text-gray-900 mb-2">
              No conversations yet
            </h3>
            <p className="text-gray-600 mb-6 text-center max-w-md">
              Start your first conversation with Lucidia to begin collaborating on your projects
            </p>
            <button className="flex items-center gap-2 px-6 py-3 bg-blue-800 hover:bg-blue-700 text-white rounded-md font-medium transition-colors">
              <Plus className="h-5 w-5" />
              New Conversation
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {conversations.map((conversation) => (
              <div
                key={conversation.id}
                className="bg-white border border-gray-200 rounded-lg p-6 hover:border-blue-800 hover:shadow-md transition-all cursor-pointer"
              >
                <div className="flex items-start gap-4">
                  <div className="h-10 w-10 rounded-full bg-gradient-to-br from-blue-800 to-blue-600 flex items-center justify-center text-white flex-shrink-0">
                    <MessageSquare className="h-5 w-5" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="font-semibold text-gray-900 mb-1 truncate">
                      {conversation.title}
                    </h3>
                    <p className="text-sm text-gray-600 line-clamp-2 mb-2">
                      {conversation.lastMessage}
                    </p>
                    <p className="text-xs text-gray-500">
                      {conversation.timestamp}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
