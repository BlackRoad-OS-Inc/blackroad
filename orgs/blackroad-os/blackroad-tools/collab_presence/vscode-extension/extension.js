const vscode = require('vscode');
const io = require('socket.io-client');

let socket;
let heartbeat;

function activate(context) {
  const config = () => vscode.workspace.getConfiguration('blackroadPresence');

  function connect() {
    const agent = config().get('agent') || 'vscode';
    const baseUrl = (config().get('busUrl') || 'http://127.0.0.1:9000').replace(/\/$/, '');
    if (socket) {
      socket.disconnect();
    }
    socket = io(baseUrl, {
      path: '/collab/socket.io',
      transports: ['websocket', 'polling'],
      reconnection: true,
      reconnectionDelay: 500,
      reconnectionAttempts: 5
    });
    socket.on('connect', () => {
      socket.emit('join', { agent, ts: Date.now() / 1000 });
      sendHeartbeat();
    });
    socket.on('connect_error', (err) => {
      console.warn('[presence-bus] connect error', err.message);
    });
  }

  function sendHeartbeat(editor) {
    const agent = config().get('agent') || 'vscode';
    const baseUrl = (config().get('busUrl') || 'http://127.0.0.1:9000').replace(/\/$/, '');
    const branch = vscode.workspace.getConfiguration('git').get('defaultBranchName') || undefined;
    const payload = {
      agent,
      ts: Date.now() / 1000,
      file: editor && editor.document ? vscode.workspace.asRelativePath(editor.document.uri) : undefined,
      branch,
      metadata: {
        language: editor && editor.document ? editor.document.languageId : undefined
      }
    };
    if (socket && socket.connected) {
      socket.emit('focus', payload);
    }
    fetch(`${baseUrl}/collab/events`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ event: 'focus', payload })
    }).catch((err) => console.warn('[presence-bus] heartbeat failed', err.message));
  }

  function handleActiveEditor(editor) {
    if (!editor) {
      return;
    }
    sendHeartbeat(editor);
  }

  context.subscriptions.push(vscode.workspace.onDidChangeConfiguration((event) => {
    if (event.affectsConfiguration('blackroadPresence')) {
      connect();
    }
  }));

  context.subscriptions.push(vscode.window.onDidChangeActiveTextEditor((editor) => handleActiveEditor(editor)));
  context.subscriptions.push(vscode.workspace.onDidChangeTextDocument((event) => {
    const editor = vscode.window.visibleTextEditors.find((ed) => ed.document === event.document);
    if (editor) {
      sendHeartbeat(editor);
    }
  }));

  connect();
  heartbeat = setInterval(() => sendHeartbeat(vscode.window.activeTextEditor), 45000);
}

function deactivate() {
  if (heartbeat) {
    clearInterval(heartbeat);
    heartbeat = undefined;
  }
  if (socket) {
    socket.disconnect();
    socket = undefined;
  }
}

module.exports = {
  activate,
  deactivate
};
