import * as vscode from 'vscode';

export function activate(context: vscode.ExtensionContext) {
    console.log('BlackRoad OS extension activated');

    let statusCmd = vscode.commands.registerCommand('blackroad.status', () => {
        vscode.window.showInformationMessage('BlackRoad OS: Online | 30K Agents Ready');
    });

    let deployCmd = vscode.commands.registerCommand('blackroad.deploy', async () => {
        const target = await vscode.window.showQuickPick(
            ['Cloudflare', 'Railway', 'Vercel', 'GitHub Pages'],
            { placeHolder: 'Select deployment target' }
        );
        if (target) {
            vscode.window.showInformationMessage(`Deploying to ${target}...`);
        }
    });

    context.subscriptions.push(statusCmd, deployCmd);
}

export function deactivate() {}
